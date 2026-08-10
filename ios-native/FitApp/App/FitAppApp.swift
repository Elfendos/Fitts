import SwiftUI

@main
struct FitAppApp: App {

    @StateObject private var accountService = CloudKitAccountService()
    @StateObject private var localization = LocalizationManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(accountService)
                .environmentObject(localization)
        }
    }
}
