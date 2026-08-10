import Foundation

/// Mirrors `PrimaryMuscle` from utils/exercisesData.ts
enum PrimaryMuscle: String, Codable, CaseIterable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case legs = "Legs"
    case core = "Core"
    case cardio = "Cardio"
    case mobility = "Mobility"
    case hiit = "HIIT"

    var id: String { rawValue }
}

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case strength, cardio, core, flexibility, hiit, plyometric, balance, functional

    var id: String { rawValue }
}

enum ExerciseDifficulty: String, Codable, CaseIterable, Identifiable {
    case beginner, intermediate, advanced

    var id: String { rawValue }
}

/// Mirrors `ExerciseVariation` from utils/exercisesData.ts
struct ExerciseVariationLocalizedText: Codable, Equatable {
    var tr: String
    var en: String
}

struct ExerciseVariation: Codable, Identifiable, Equatable {
    var id: String
    var label: ExerciseVariationLocalizedText
    var cue: ExerciseVariationLocalizedText
    var imageUrl: String?
}

/// Mirrors `ExerciseData` from utils/exercisesData.ts.
/// Bundled as Resources/Data/exercises.json (extracted from the RN data file,
/// 160 exercises across 8 categories) and decoded at launch — see ExerciseDataStore.
struct Exercise: Codable, Identifiable, Equatable {
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
    var primaryMuscle: PrimaryMuscle?
    var variations: [ExerciseVariation]?

    /// Falls back to deriving a primary muscle from `muscles`/`category`
    /// when the field wasn't set explicitly, matching the RN helper logic.
    var resolvedPrimaryMuscle: PrimaryMuscle {
        if let primaryMuscle { return primaryMuscle }
        if category == .cardio { return .cardio }
        if category == .hiit { return .hiit }
        if let first = muscles.first, let match = PrimaryMuscle(rawValue: first) {
            return match
        }
        return .core
    }
}
