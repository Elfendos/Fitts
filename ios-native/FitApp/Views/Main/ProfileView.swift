import SwiftUI

/// Mirrors app/(tabs)/profile.tsx (core: identity, stats, sign out).
/// Not yet ported from the RN screen: photo upload to Firebase Storage
/// (the flow that was throwing errors — see task backlog), the Edit
/// Profile form, and the Settings/Subscription rows.
struct ProfileView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var profileService: UserProfileService
    @ObservedObject private var achievementService = AchievementService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    avatarSection
                    statsRow
                    achievementsPreview
                    signOutButton
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(L("home.profile"))
        }
    }

    private var avatarSection: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(AppTheme.brandAccent.opacity(0.15))
                .frame(width: 88, height: 88)
                .overlay(
                    Text(profileService.profile?.initials ?? "U")
                        .font(.title.bold())
                        .foregroundColor(AppTheme.brandAccent)
                )
            Text(profileService.profile?.name ?? "")
                .font(.title3.weight(.semibold))
                .foregroundColor(AppTheme.text)
            Text(profileService.profile?.email ?? "")
                .font(.footnote)
                .foregroundColor(AppTheme.subtext)
        }
        .padding(.top, 12)
    }

    private var statsRow: some View {
        let stats = profileService.profile?.stats ?? UserStats()
        return HStack(spacing: 12) {
            statCard(value: "\(stats.totalWorkouts)", label: "Workouts")
            statCard(value: "\(stats.currentStreak)", label: "Streak")
            statCard(value: "\(stats.totalCalories)", label: "Calories")
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack {
            Text(value).font(.title3.bold()).foregroundColor(AppTheme.text)
            Text(label).font(.caption).foregroundColor(AppTheme.subtext)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border))
        .cornerRadius(14)
    }

    private var achievementsPreview: some View {
        let unlocked = achievementService.unlocked(for: profileService.profile?.stats)
        let unlockedCount = unlocked.filter(\.isUnlocked).count
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Achievements").font(.headline).foregroundColor(AppTheme.text)
                Spacer()
                Text("\(unlockedCount)/\(unlocked.count)")
                    .foregroundColor(AppTheme.subtext)
            }
            ProgressView(value: unlocked.isEmpty ? 0 : Double(unlockedCount) / Double(unlocked.count))
                .tint(AppTheme.tint)
        }
        .padding()
        .background(AppTheme.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border))
        .cornerRadius(14)
    }

    private var signOutButton: some View {
        Button(role: .destructive) {
            auth.signOut()
        } label: {
            Text(L("auth.logout"))
                .frame(maxWidth: .infinity)
                .padding()
        }
        .background(Color.red.opacity(0.1))
        .foregroundColor(.red)
        .cornerRadius(12)
    }
}
