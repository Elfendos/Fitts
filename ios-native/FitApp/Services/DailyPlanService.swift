import Foundation
import FirebaseFirestore

/// Mirrors hooks/useDailyPlan.ts — Firestore path: users/{uid}/dailyPlans/{dateKey}.
@MainActor
final class DailyPlanService: ObservableObject {

    @Published private(set) var plan: DailyPlanDoc
    @Published private(set) var isLoading = true
    @Published private(set) var isSaving = false

    private let db = Firestore.firestore()
    private let dateKey: String
    private var userId: String?

    init(dateKey: String = DateKey.today) {
        self.dateKey = dateKey
        self.plan = .empty(dateKey: dateKey)
    }

    func start(for uid: String?) {
        userId = uid
        Task { await load() }
    }

    private func docRef() -> DocumentReference? {
        guard let userId else { return nil }
        return db.collection("users").document(userId)
            .collection("dailyPlans").document(dateKey)
    }

    func load() async {
        guard let ref = docRef() else {
            isLoading = false
            return
        }
        isLoading = true
        do {
            let snapshot = try await ref.getDocument()
            if snapshot.exists, let doc = try? snapshot.data(as: DailyPlanDoc.self) {
                plan = doc
            } else {
                plan = .empty(dateKey: dateKey)
            }
        } catch {
            print("Failed to load daily plan: \(error)")
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

    func save() async {
        guard let ref = docRef() else { return }
        isSaving = true
        do {
            var toSave = plan
            toSave.updatedAt = Timestamp(date: Date())
            try ref.setData(from: toSave, merge: true)
        } catch {
            print("Failed to save daily plan: \(error)")
        }
        isSaving = false
    }
}
