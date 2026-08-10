import Foundation
import FirebaseFirestore

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

/// Mirrors `DailyPlanDoc` — Firestore path: users/{uid}/dailyPlans/{dateKey}
struct DailyPlanDoc: Codable, Equatable {
    var dateKey: String
    var title: String = "Daily Workout"
    var items: [PlannedExercise] = []
    var updatedAt: Timestamp?

    static func empty(dateKey: String) -> DailyPlanDoc {
        DailyPlanDoc(dateKey: dateKey, title: "Daily Workout", items: [])
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
