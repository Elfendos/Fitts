import Foundation
import CloudKit

/// Mirrors the RN `HealthProfile` interface (hooks/useUserProfile.ts).
/// Enum-like fields are kept as raw strings for now; port the exact
/// enums from utils/healthCalculations.ts when the onboarding flow is rebuilt.
/// Stored as a JSON blob in a single CloudKit field (see UserProfile.record)
/// since CKRecord doesn't support nested structured values directly.
struct HealthProfile: Codable, Equatable {
    var age: Int
    var gender: String
    var heightCm: Double
    var weightKg: Double
    var startWeightKg: Double
    var targetWeightKg: Double
    var activityLevel: String
    var weeklyWorkouts: Int
    var goal: String
    var concerns: [String]
    var workoutLevel: String
    var dailyCalories: Double
    var bmr: Double
    var tdee: Double
}

struct UserStats: Codable, Equatable {
    var totalWorkouts: Int = 0
    var currentStreak: Int = 0
    var totalCalories: Int = 0
}

/// Mirrors the RN `UserProfile` interface (hooks/useUserProfile.ts), now
/// backed by a single CloudKit record in the private database (record type
/// "UserProfile", fixed recordID "CurrentUserProfile" — the private DB is
/// already scoped to one iCloud account, so there's no per-uid keying to do).
struct UserProfile: Codable, Identifiable, Equatable {
    static let fixedRecordName = "CurrentUserProfile"

    var name: String
    var initials: String
    var stats: UserStats
    var healthProfile: HealthProfile?

    var id: String { UserProfile.fixedRecordName }

    static func newProfile(displayName: String?) -> UserProfile {
        let name = displayName ?? "User"
        let initials = String(
            name
                .split(separator: " ")
                .compactMap { $0.first }
                .prefix(2)
        ).uppercased()

        return UserProfile(
            name: name,
            initials: initials.isEmpty ? "U" : initials,
            stats: UserStats(),
            healthProfile: nil
        )
    }

    // MARK: - CKRecord mapping

    static var recordID: CKRecord.ID {
        CKRecord.ID(recordName: fixedRecordName)
    }

    init(name: String, initials: String, stats: UserStats, healthProfile: HealthProfile?) {
        self.name = name
        self.initials = initials
        self.stats = stats
        self.healthProfile = healthProfile
    }

    init?(record: CKRecord) {
        guard let name = record["name"] as? String,
              let initials = record["initials"] as? String else { return nil }
        self.name = name
        self.initials = initials
        self.stats = UserStats(
            totalWorkouts: (record["totalWorkouts"] as? Int) ?? 0,
            currentStreak: (record["currentStreak"] as? Int) ?? 0,
            totalCalories: (record["totalCalories"] as? Int) ?? 0
        )
        if let data = record["healthProfileJSON"] as? Data {
            self.healthProfile = try? JSONDecoder().decode(HealthProfile.self, from: data)
        } else {
            self.healthProfile = nil
        }
    }

    func apply(to record: CKRecord) {
        record["name"] = name as CKRecordValue
        record["initials"] = initials as CKRecordValue
        record["totalWorkouts"] = stats.totalWorkouts as CKRecordValue
        record["currentStreak"] = stats.currentStreak as CKRecordValue
        record["totalCalories"] = stats.totalCalories as CKRecordValue
        if let healthProfile, let data = try? JSONEncoder().encode(healthProfile) {
            record["healthProfileJSON"] = data as CKRecordValue
        } else {
            record["healthProfileJSON"] = nil
        }
    }
}
