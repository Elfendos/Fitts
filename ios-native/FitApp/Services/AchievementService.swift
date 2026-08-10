import Foundation

/// Loads the bundled achievement catalog (Resources/Data/achievements.json —
/// 17 definitions extracted from constants/achievementsData.ts) and computes
/// unlock state from the user's stats. Mirrors hooks/useAchievements.ts at a
/// basic level (streak/workouts/calories conditions); the RN hook additionally
/// writes unlock events back to Firestore via a batched commit — port that
/// once the stats-tracking screens (history/analytics) are rebuilt.
@MainActor
final class AchievementService: ObservableObject {

    static let shared = AchievementService()

    @Published private(set) var definitions: [AchievementDefinition] = []
    @Published private(set) var loadError: String?

    private init() {
        load()
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "achievements", withExtension: "json") else {
            loadError = "achievements.json bundle'da bulunamadı."
            return
        }
        do {
            let data = try Data(contentsOf: url)
            definitions = try JSONDecoder().decode([AchievementDefinition].self, from: data)
        } catch {
            loadError = "achievements.json parse edilemedi: \(error)"
        }
    }

    func unlocked(for stats: UserStats?) -> [UnlockedAchievement] {
        let stats = stats ?? UserStats()
        return definitions.map { def in
            let progress: Int
            switch def.conditionType {
            case .streak: progress = stats.currentStreak
            case .workouts: progress = stats.totalWorkouts
            case .calories: progress = stats.totalCalories
            case .steps, .other, .none: progress = 0
            }
            let target = def.targetValue ?? Int.max
            return UnlockedAchievement(definition: def, isUnlocked: progress >= target, progress: progress)
        }
    }
}
