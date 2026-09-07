import Foundation

/// Builds a starter push/pull/legs weekly split from the bundled exercise
/// catalog. Used by both the onboarding flow's auto-generated first plan and
/// the Weekly Plan screen's "Smart Plan Generator" preview — there's no
/// remote AI call here, just a fixed, well-known template looked up by
/// exercise title (a genuine LLM-backed generator would replace this
/// function's body without touching its callers).
@MainActor
enum WorkoutTemplateGenerator {
    struct TemplateExercise {
        var title: String
        var sets: Int
        var reps: Int
    }

    static let pushDay: [TemplateExercise] = [
        .init(title: "Push-ups", sets: 4, reps: 8),
        .init(title: "Bench Press", sets: 4, reps: 8),
        .init(title: "Dumbbell Lateral Raise", sets: 3, reps: 10),
        .init(title: "Triceps Rope Pushdown", sets: 3, reps: 10),
        .init(title: "Tricep Dips", sets: 3, reps: 10),
    ]

    static let pullDay: [TemplateExercise] = [
        .init(title: "Pull-ups", sets: 4, reps: 8),
        .init(title: "Seated Cable Row", sets: 4, reps: 8),
        .init(title: "Bent Over Rows", sets: 4, reps: 8),
        .init(title: "Bicep Curls", sets: 3, reps: 10),
        .init(title: "Hammer Curl", sets: 3, reps: 10),
    ]

    static let legDay: [TemplateExercise] = [
        .init(title: "Bodyweight Squats", sets: 4, reps: 8),
        .init(title: "Conventional Deadlift", sets: 4, reps: 8),
        .init(title: "Walking Lunges", sets: 4, reps: 8),
        .init(title: "Romanian Deadlift", sets: 4, reps: 8),
        .init(title: "Plank Hold", sets: 3, reps: 10),
    ]

    /// Mon/Wed/Fri push-pull-legs, Tue/Thu/Sat/Sun rest.
    static func weeklySplit() -> [String: [TemplateExercise]] {
        [
            "Mon": pushDay,
            "Wed": pullDay,
            "Fri": legDay,
        ]
    }

    /// Resolves each template entry against the bundled catalog by exact
    /// (case-insensitive) title match, skipping any that aren't found.
    static func resolve(_ template: [TemplateExercise]) -> [PlannedExercise] {
        template.compactMap { entry in
            guard let exercise = ExerciseDataStore.shared.all.first(where: {
                $0.title.caseInsensitiveCompare(entry.title) == .orderedSame
            }) else { return nil }
            return PlannedExercise(from: exercise, sets: entry.sets, reps: entry.reps)
        }
    }

    static func resolvedWeeklySplit() -> [String: [PlannedExercise]] {
        weeklySplit().mapValues(resolve)
    }
}
