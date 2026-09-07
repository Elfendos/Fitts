import Foundation
import CloudKit

/// One named weekly workout plan (e.g. "Push Pull Legs") — the multi-plan
/// model the RN weekly-plan screen supports (multiple named plans, an
/// active one, per-day exercises) that the first native pass (see
/// WeeklyPlanView's original comment) deliberately skipped as a single-plan
/// simplification. All of a user's plans live in one CloudKit record (fixed
/// recordID, JSON blob) — same "one record, JSON field" pattern already
/// used for UserProfile/DailyPlan, since CKRecord has no nested-array-of-
/// structs support.
struct WorkoutPlan: Codable, Identifiable, Equatable {
    var id: String = "plan_\(UUID().uuidString.prefix(12))"
    var name: String
    var isActive: Bool = false
    /// Keyed by weekday abbreviation, see `WorkoutPlan.weekdays`.
    var days: [String: [PlannedExercise]] = [:]

    static let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    func exercises(on day: String) -> [PlannedExercise] {
        days[day] ?? []
    }
}

struct WorkoutPlansDoc: Codable, Equatable {
    var plans: [WorkoutPlan] = []

    static let recordID = CKRecord.ID(recordName: "CurrentUserWorkoutPlans")

    init(plans: [WorkoutPlan] = []) {
        self.plans = plans
    }

    init?(record: CKRecord) {
        guard let data = record["plansJSON"] as? Data,
              let decoded = try? JSONDecoder().decode([WorkoutPlan].self, from: data) else {
            return nil
        }
        self.plans = decoded
    }

    func apply(to record: CKRecord) {
        if let data = try? JSONEncoder().encode(plans) {
            record["plansJSON"] = data as CKRecordValue
        }
    }
}
