import Foundation
import SwiftUI

/// Mirrors i18n/index.tsx — detects device language (tr/en) via
/// `Locale.preferredLanguages`, the SwiftUI equivalent of
/// `expo-localization`'s `Localization.getLocales()`. Falls back to English
/// for any language other than Turkish, matching the RN app's supported set.
@MainActor
final class LocalizationManager: ObservableObject {

    static let shared = LocalizationManager()

    enum Language: String {
        case en, tr
    }

    @Published var language: Language

    private var bundle: Bundle

    private init() {
        let preferred = Locale.preferredLanguages.first ?? "en"
        let detected: Language = preferred.hasPrefix("tr") ? .tr : .en
        self.language = detected
        self.bundle = LocalizationManager.bundle(for: detected)
    }

    private static func bundle(for language: Language) -> Bundle {
        guard
            let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return .main
        }
        return bundle
    }

    func setLanguage(_ language: Language) {
        self.language = language
        self.bundle = LocalizationManager.bundle(for: language)
    }

    /// Looks up a flattened i18n key, e.g. `t("home.todaysWorkout")`,
    /// matching the RN `t.home.todaysWorkout` namespace access pattern.
    func t(_ key: String) -> String {
        NSLocalizedString(key, tableName: "Localizable", bundle: bundle, comment: "")
    }
}

/// Convenience so views can call `L(key)` instead of threading the
/// environment object through every string.
@MainActor
func L(_ key: String) -> String {
    LocalizationManager.shared.t(key)
}
