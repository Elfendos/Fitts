import Foundation

enum AchievementRarity: String, Codable {
    case common = "Common"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"

    var accentColor: String {
        switch self {
        case .common: return "#8E8E93"
        case .rare: return "#0A7EA4"
        case .epic: return "#9B59B6"
        case .legendary: return "#F5A623"
        }
    }
}

enum AchievementConditionType: String, Codable {
    case streak, steps, workouts, calories, other
}

/// Mirrors `AchievementDefinition` from constants/achievementsData.ts.
/// Bundled as Resources/Data/achievements.json (17 definitions extracted
/// from the RN data file) and decoded at launch — see AchievementService.
struct AchievementDefinition: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var description: String
    var icon: String
    var rarity: AchievementRarity
    var conditionType: AchievementConditionType?
    var targetValue: Int?
}

struct UnlockedAchievement: Identifiable, Equatable {
    var definition: AchievementDefinition
    var isUnlocked: Bool
    var progress: Int

    var id: String { definition.id }
}
