import SwiftUI

/// Replaces the Firebase auth-state gate: unavailable iCloud account →
/// LoginView (now an "enable iCloud" prompt), available → MainTabView.
struct RootView: View {
    @EnvironmentObject private var account: CloudKitAccountService
    @StateObject private var profileService = UserProfileService()
    @StateObject private var workoutPlanService = WorkoutPlanService()

    /// Lets onboarding be bypassed on this device — e.g. while the
    /// CloudKit container's production schema hasn't been deployed yet, so
    /// setHealthProfile() can't actually persist. Doesn't touch CloudKit;
    /// just a local escape hatch until that's sorted out. See OnboardingView's
    /// "Skip for now" link.
    @AppStorage("onboarding.skipped") private var hasSkippedOnboarding = false

    var body: some View {
        Group {
            if account.isLoading || (account.isAvailable && profileService.isLoading) {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.background)
            } else if account.isAvailable {
                if profileService.profile?.healthProfile == nil && !hasSkippedOnboarding {
                    OnboardingView(
                        onFinished: { Task { await profileService.load() } },
                        onSkip: { hasSkippedOnboarding = true }
                    )
                        .environmentObject(profileService)
                        .environmentObject(workoutPlanService)
                } else {
                    MainTabView()
                        .environmentObject(profileService)
                        .environmentObject(workoutPlanService)
                        .onAppear { workoutPlanService.start(isAccountAvailable: true) }
                }
            } else {
                LoginView()
            }
        }
        // Single-parameter form — the (oldValue, newValue) overload is iOS 17+;
        // this target's deployment floor is iOS 16.
        .onChange(of: account.status) { newStatus in
            profileService.start(isAccountAvailable: newStatus == .available)
        }
    }
}
