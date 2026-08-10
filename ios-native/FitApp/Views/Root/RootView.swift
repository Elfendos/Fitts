import SwiftUI

/// Replaces the Firebase auth-state gate: unavailable iCloud account →
/// LoginView (now an "enable iCloud" prompt), available → MainTabView.
struct RootView: View {
    @EnvironmentObject private var account: CloudKitAccountService
    @StateObject private var profileService = UserProfileService()

    var body: some View {
        Group {
            if account.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.background)
            } else if account.isAvailable {
                MainTabView()
                    .environmentObject(profileService)
                    .onAppear { profileService.start(isAccountAvailable: true) }
            } else {
                LoginView()
            }
        }
        .onChange(of: account.status) { _, newStatus in
            profileService.start(isAccountAvailable: newStatus == .available)
        }
    }
}
