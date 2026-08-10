import SwiftUI
import FirebaseCore

@main
struct FitAppApp: App {

    init() {
        FirebaseApp.configure()
    }

    @StateObject private var authService = AuthService()
    @StateObject private var localization = LocalizationManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .environmentObject(localization)
                .onOpenURL { url in
                    Task {
                        await authService.handleIncomingURL(url)
                    }
                }
        }
    }
}
