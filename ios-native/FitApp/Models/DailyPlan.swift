import Foundation
import CloudKit

/// Mirrors `PlannedExercise` from hooks/useDailyPlan.ts — an Exercise plus
/// per-plan scheduling fields.
struct PlannedExercise: Codable, Identifiable, Equatable {
    var plannedId: String
    var id: String
    var title: String
    var category: ExerciseCategory
    var difficulty: ExerciseDifficulty
    var duration: Int
    var calories: Int
    var equipment: [String]
    var muscles: [String]
    var instructions: [String]
    var tips: [String]?
    var imageUrl: String
    var popularity: Int
    var sets: Int
    var reps: Int
    var completed: Bool = false
    var maxWeight: Double?
    var variationId: String?

    init(from exercise: Exercise, sets: Int = 3, reps: Int = 8) {
        self.plannedId = "p_\(UUID().uuidString.prefix(12))"
        self.id = exercise.id
        self.title = exercise.title
        self.category = exercise.category
        self.difficulty = exercise.difficulty
        self.duration = exercise.duration
        self.calories = exercise.calories
        self.equipment = exercise.equipment
        self.muscles = exercise.muscles
        self.instructions = exercise.instructions
        self.tips = exercise.tips
        self.imageUrl = exercise.imageUrl
        self.popularity = exercise.popularity
        self.sets = sets
        self.reps = reps
    }
}

/// Mirrors `DailyPlanDoc` — now a CloudKit record (type "DailyPlan", private
/// database) instead of a Firestore doc. `items` doesn't map to native
/// CKRecord fields (no nested-object support), so it's stored as a single
/// JSON-encoded Data field — see `apply(to:)` / `init?(record:)` below.
struct DailyPlanDoc: Codable, Equatable {
    var dateKey: String
    var title: String = "Daily Workout"
    var items: [PlannedExercise] = []
    var updatedAt: Date?

    static func empty(dateKey: String) -> DailyPlanDoc {
        DailyPlanDoc(dateKey: dateKey, title: "Daily Workout", items: [])
    }

    // MARK: - CKRecord mapping

    static func recordID(for dateKey: String) -> CKRecord.ID {
        CKRecord.ID(recordName: "dailyPlan_\(dateKey)")
    }

    init(dateKey: String, title: String = "Daily Workout", items: [PlannedExercise] = [], updatedAt: Date? = nil) {
        self.dateKey = dateKey
        self.title = title
        self.items = items
        self.updatedAt = updatedAt
    }

    init?(record: CKRecord) {
        guard let dateKey = record["dateKey"] as? String else { return nil }
        self.dateKey = dateKey
        self.title = (record["title"] as? String) ?? "Daily Workout"
        if let data = record["itemsJSON"] as? Data,
           let decoded = try? JSONDecoder().decode([PlannedExercise].self, from: data) {
            self.items = decoded
        } else {
            self.items = []
        }
        self.updatedAt = record.modificationDate
    }

    func apply(to record: CKRecord) {
        record["dateKey"] = dateKey as CKRecordValue
        record["title"] = title as CKRecordValue
        if let data = try? JSONEncoder().encode(items) {
            record["itemsJSON"] = data as CKRecordValue
        }
    }
}

enum DateKey {
    /// YYYY-MM-DD, matches `toDateKey` in hooks/useDailyPlan.ts
    static func from(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static var today: String { from(Date()) }
}
