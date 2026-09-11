import Foundation
import CloudKit

/// Backs the multi-plan WeeklyPlanView (rename/delete/set-active, per-day
/// exercise editing) and the Smart Plan Generator's "Save as Plan" action.
/// Mirrors the DailyPlanService pattern: one JSON-blob CKRecord, mutate the
/// published array locally, `save()` persists the whole thing.
@MainActor
final class WorkoutPlanService: ObservableObject {

    @Published private(set) var plans: [WorkoutPlan] = []
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?

    private let db = CloudKitManager.privateDatabase
    private var isAccountAvailable = false
    private var hasLoadedOnce = false

    var activePlan: WorkoutPlan? { plans.first(where: \.isActive) }

    /// WeeklyPlanView/HomeView call this on every `.onAppear`, not just
    /// once — without the `hasLoadedOnce` guard, a plan created right after
    /// the screen appears could lose the race against that appearance's own
    /// `load()`: the append happens locally and its `save()` is queued, but
    /// if the older `load()` Task resolves afterward, it overwrites
    /// `plans` with the pre-append server state, erasing the new plan
    /// in memory — and the *next* save then persists that emptier state,
    /// erasing it from CloudKit too. Loading once per session (this object
    /// is a long-lived singleton for the whole app session, not re-created
    /// per screen) removes the second, competing `load()` entirely.
    func start(isAccountAvailable: Bool) {
        self.isAccountAvailable = isAccountAvailable
        guard isAccountAvailable else {
            isLoading = false
            return
        }
        guard !hasLoadedOnce else {
            isLoading = false
            return
        }
        hasLoadedOnce = true
        Task { await load() }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let record = try await db.record(for: WorkoutPlansDoc.recordID)
            plans = WorkoutPlansDoc(record: record)?.plans ?? []
        } catch let error as CKError where error.code == .unknownItem {
            plans = []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func save() async {
        guard isAccountAvailable else { return }
        do {
            let recordID = WorkoutPlansDoc.recordID
            let record: CKRecord
            if let existing = try? await db.record(for: recordID) {
                record = existing
            } else {
                record = CKRecord(recordType: CloudKitRecordType.workoutPlans, recordID: recordID)
            }
            WorkoutPlansDoc(plans: plans).apply(to: record)
            try await db.save(record)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func addPlan(name: String, days: [String: [PlannedExercise]] = [:]) -> WorkoutPlan {
        var plan = WorkoutPlan(name: name, days: days)
        if plans.isEmpty { plan.isActive = true }
        plans.append(plan)
        Task { await save() }
        return plan
    }

    func setActive(planId: String) {
        for i in plans.indices { plans[i].isActive = (plans[i].id == planId) }
        Task { await save() }
    }

    func rename(planId: String, name: String) {
        guard let idx = plans.firstIndex(where: { $0.id == planId }) else { return }
        plans[idx].name = name
        Task { await save() }
    }

    func deletePlan(planId: String) {
        let wasActive = plans.first { $0.id == planId }?.isActive ?? false
        plans.removeAll { $0.id == planId }
        if wasActive, let first = plans.first {
            plans[0] = { var p = first; p.isActive = true; return p }()
        }
        Task { await save() }
    }

    func addExercise(_ exercise: Exercise, planId: String, day: String, sets: Int = 3, reps: Int = 8) {
        guard let idx = plans.firstIndex(where: { $0.id == planId }) else { return }
        var item = PlannedExercise(from: exercise, sets: sets, reps: reps)
        item.maxWeight = ExerciseMaxWeightService.shared.weight(for: exercise.id)
        plans[idx].days[day, default: []].append(item)
        Task { await save() }
    }

    func removeExercise(planId: String, day: String, plannedId: String) {
        guard let idx = plans.firstIndex(where: { $0.id == planId }) else { return }
        plans[idx].days[day]?.removeAll { $0.plannedId == plannedId }
        Task { await save() }
    }

    func updateSets(planId: String, day: String, plannedId: String, sets: Int) {
        guard let pIdx = plans.firstIndex(where: { $0.id == planId }),
              let eIdx = plans[pIdx].days[day]?.firstIndex(where: { $0.plannedId == plannedId }) else { return }
        plans[pIdx].days[day]?[eIdx].sets = max(1, sets)
        Task { await save() }
    }

    func updateReps(planId: String, day: String, plannedId: String, reps: Int) {
        guard let pIdx = plans.firstIndex(where: { $0.id == planId }),
              let eIdx = plans[pIdx].days[day]?.firstIndex(where: { $0.plannedId == plannedId }) else { return }
        plans[pIdx].days[day]?[eIdx].reps = max(1, reps)
        Task { await save() }
    }
}
