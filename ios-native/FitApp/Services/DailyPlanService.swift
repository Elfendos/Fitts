import Foundation
import CloudKit

/// Replaces the Firestore-backed `DailyPlanService` — mirrors
/// hooks/useDailyPlan.ts, now reading/writing a CKRecord (type "DailyPlan",
/// recordID `dailyPlan_{dateKey}`) in the private database instead of
/// users/{uid}/dailyPlans/{dateKey}.
@MainActor
final class DailyPlanService: ObservableObject {

    @Published private(set) var plan: DailyPlanDoc
    @Published private(set) var isLoading = true
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?

    private let db = CloudKitManager.privateDatabase
    private var dateKey: String
    private var isAccountAvailable = false

    init(dateKey: String = DateKey.today) {
        self.dateKey = dateKey
        self.plan = .empty(dateKey: dateKey)
    }

    func start(isAccountAvailable: Bool) {
        self.isAccountAvailable = isAccountAvailable
        guard isAccountAvailable else {
            isLoading = false
            return
        }
        Task { await load() }
    }

    /// Re-points this service at a different day (see HomeView's date strip)
    /// and reloads that day's plan.
    func switchTo(dateKey: String) {
        guard dateKey != self.dateKey else { return }
        self.dateKey = dateKey
        plan = .empty(dateKey: dateKey)
        guard isAccountAvailable else { return }
        Task { await load() }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let record = try await db.record(for: DailyPlanDoc.recordID(for: dateKey))
            plan = DailyPlanDoc(record: record) ?? .empty(dateKey: dateKey)
        } catch let error as CKError where error.code == .unknownItem {
            plan = .empty(dateKey: dateKey)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addExercise(_ exercise: Exercise, sets: Int = 3, reps: Int = 8) {
        plan.items.append(PlannedExercise(from: exercise, sets: sets, reps: reps))
    }

    func removeExercise(plannedId: String) {
        plan.items.removeAll { $0.plannedId == plannedId }
    }

    func toggleCompleted(plannedId: String) {
        guard let idx = plan.items.firstIndex(where: { $0.plannedId == plannedId }) else { return }
        plan.items[idx].completed.toggle()
    }

    func updateSets(plannedId: String, sets: Int) {
        guard let idx = plan.items.firstIndex(where: { $0.plannedId == plannedId }) else { return }
        plan.items[idx].sets = max(1, sets)
    }

    func updateReps(plannedId: String, reps: Int) {
        guard let idx = plan.items.firstIndex(where: { $0.plannedId == plannedId }) else { return }
        plan.items[idx].reps = max(1, reps)
    }

    func updateMaxWeight(plannedId: String, maxWeight: Double) {
        guard let idx = plan.items.firstIndex(where: { $0.plannedId == plannedId }) else { return }
        plan.items[idx].maxWeight = max(0, maxWeight)
    }

    func save() async {
        guard isAccountAvailable else { return }
        isSaving = true
        errorMessage = nil
        do {
            let recordID = DailyPlanDoc.recordID(for: dateKey)
            let record: CKRecord
            if let existing = try? await db.record(for: recordID) {
                record = existing
            } else {
                record = CKRecord(recordType: CloudKitRecordType.dailyPlan, recordID: recordID)
            }
            plan.apply(to: record)
            try await db.save(record)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
