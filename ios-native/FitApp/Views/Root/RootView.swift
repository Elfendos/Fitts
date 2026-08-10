import SwiftUI

/// Mirrors the protected-route redirect logic in context/AuthContext.tsx:
/// unauthenticated → LoginView, authenticated → MainTabView.
struct RootView: View {
    @EnvironmentObject private var auth: AuthService
    @StateObject private var profileService = UserProfileService()

    var body: some View {
        Group {
            if auth.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.background)
            } else if let user = auth.user {
                MainTabView()
                    .environmentObject(profileService)
                    .onAppear { profileService.start(for: user.uid) }
            } else {
                LoginView()
            }
        }
        .onChange(of: auth.user?.uid) { _, uid in
            profileService.start(for: uid)
        }
    }
}
