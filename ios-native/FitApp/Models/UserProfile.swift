import Foundation
import FirebaseFirestore

/// Mirrors the RN `HealthProfile` interface (hooks/useUserProfile.ts).
/// Enum-like fields are kept as raw strings for now; port the exact
/// enums from utils/healthCalculations.ts when the onboarding flow is rebuilt.
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

/// Mirrors the RN `UserProfile` interface (hooks/useUserProfile.ts).
/// Stored at Firestore path: users/{uid}
struct UserProfile: Codable, Identifiable, Equatable {
    @DocumentID var docId: String?
    var uid: String
    var name: String
    var email: String
    var initials: String
    var photoURL: String?
    var stats: UserStats?
    var healthProfile: HealthProfile?

    var id: String { uid }

    static func newProfile(uid: String, email: String?, displayName: String?) -> UserProfile {
        let name = displayName ?? email?.components(separatedBy: "@").first ?? "User"
        let initials = String(
            name
                .split(separator: " ")
                .compactMap { $0.first }
                .prefix(2)
        ).uppercased()

        return UserProfile(
            uid: uid,
            name: name,
            email: email ?? "",
            initials: initials.isEmpty ? "U" : initials,
            photoURL: nil,
            stats: UserStats(),
            healthProfile: nil
        )
    }
}
