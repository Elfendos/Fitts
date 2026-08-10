import SwiftUI

/// Mirrors app/(tabs)/profile.tsx (core: identity, stats). CloudKit has no
/// "sign out" concept (the private database is tied to the device's iCloud
/// account, controlled from Settings — see LoginView), so the RN sign-out
/// button is replaced with a rename action here instead.
/// Not yet ported from the RN screen: profile photo upload, full Edit
/// Profile form, Settings/Subscription rows.
struct ProfileView: View {
    @EnvironmentObject private var profileService: UserProfileService
    @ObservedObject private var achievementService = AchievementService.shared

    @State private var isEditingName = false
    @State private var draftName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    avatarSection
                    statsRow
                    achievementsPreview
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(L("home.profile"))
            .alert("İsmini Düzenle", isPresented: $isEditingName) {
                TextField("İsim", text: $draftName)
                Button(L("common.cancel"), role: .cancel) {}
                Button(L("common.save")) {
                    Task { await profileService.updateProfile(name: draftName) }
                }
            }
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
            Button {
                draftName = profileService.profile?.name ?? ""
                isEditingName = true
            } label: {
                HStack(spacing: 6) {
                    Text(profileService.profile?.name ?? "")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(AppTheme.text)
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(AppTheme.subtext)
                }
            }
            Text("iCloud'a bağlı")
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
}
