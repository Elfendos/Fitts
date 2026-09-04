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

/// Ports `derivePrimaryMuscle` + its `MUSCLE_TO_PRIMARY`/`PRIMARY_OVERRIDE`
/// lookup tables from utils/exercisesData.ts verbatim. The bundled
/// exercises.json never sets `primaryMuscle` on individual entries (the RN
/// data file doesn't either — it's derived on demand), and the raw
/// `muscles[0]` strings are specific ("Quads", "Lats", "Rear Delts", ...)
/// rather than already matching `PrimaryMuscle`'s cases, so resolving this
/// with a naive exact-match (as an earlier version of this file did) mis-
/// buckets most exercises into `.core`. Used by both `Exercise` and
/// `PlannedExercise` (see DailyPlan.swift) for the muscle-map screen.
enum PrimaryMuscleResolver {
    /// category/flexibility/hiit/core short-circuit before this table is
    /// consulted at all — see `resolve(id:category:muscles:)`.
    private static let muscleToPrimary: [String: PrimaryMuscle] = [
        "chest": .chest, "upper chest": .chest,
        "back": .back, "lats": .back, "mid back": .back, "lower back": .back,
        "shoulders": .shoulders, "side delts": .shoulders, "rear delts": .shoulders, "neck": .shoulders,
        "biceps": .biceps,
        "triceps": .triceps, "arms": .triceps,
        "quads": .legs, "quadriceps": .legs, "hamstrings": .legs,
        "glutes": .legs, "calves": .legs, "inner thighs": .legs,
        "hip flexors": .legs, "legs": .legs,
        "core": .core, "abs": .core, "upper abs": .core,
        "lower abs": .core, "obliques": .core, "spine": .core, "grip": .core,
    ]

    /// Manual overrides for "Full Body" plyometric/balance/functional moves,
    /// keyed by exercise id — matches PRIMARY_OVERRIDE in exercisesData.ts.
    private static let primaryOverride: [String: PrimaryMuscle] = [
        "plyo_depth_jump": .legs,
        "plyo_broad_jump": .legs,
        "plyo_single_leg_hop": .legs,
        "plyo_lateral_bounds": .legs,
        "plyo_clap_pushups": .chest,
        "plyo_lunge_jumps": .legs,
        "plyo_power_skips": .legs,
        "plyo_ankle_hops": .legs,
        "bal_single_leg_stand": .core,
        "bal_bosu_squat": .legs,
        "bal_tandem_stance": .core,
        "bal_single_leg_deadlift": .legs,
        "bal_warrior_3": .core,
        "bal_stability_ball_plank": .core,
        "bal_tree_pose": .core,
        "bal_clock_reaches": .core,
        "func_turkish_getup": .core,
        "func_farmers_carry": .core,
        "func_sled_push": .legs,
        "func_medicine_ball_slam": .core,
        "func_wood_chop": .core,
        "func_pallof_press": .core,
        "func_bear_crawl": .core,
        "func_landmine_press": .shoulders,
        "func_sandbag_clean": .legs,
        "func_loaded_carry_variations": .shoulders,
    ]

    static func resolve(id: String, category: ExerciseCategory, muscles: [String]) -> PrimaryMuscle {
        if let override = primaryOverride[id] { return override }
        switch category {
        case .cardio: return .cardio
        case .flexibility: return .mobility
        case .hiit: return .hiit
        case .core: return .core
        default: break
        }
        let first = (muscles.first ?? "").lowercased().trimmingCharacters(in: .whitespaces)
        return muscleToPrimary[first] ?? .core
    }
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
    /// when the field wasn't set explicitly — see `PrimaryMuscleResolver`.
    var resolvedPrimaryMuscle: PrimaryMuscle {
        if let primaryMuscle { return primaryMuscle }
        return PrimaryMuscleResolver.resolve(id: id, category: category, muscles: muscles)
    }
}
