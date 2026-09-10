import SwiftUI
import UIKit

/// Mirrors constants/theme.ts `Colors.light`/`Colors.dark`. Originally
/// shipped as a single fixed-hex light palette (the RN app forces light
/// mode in a few components), which left every hardcoded-dark-text-on-
/// hardcoded-light-background pairing unreadable whenever the device was
/// actually in Dark Mode — while system-styled chrome (List backgrounds,
/// the keyboard, sheets) followed Dark Mode correctly regardless. Neutral
/// tokens now use UIKit's semantic colors, which track the system
/// appearance the same way that chrome does; the accent/stat tints get an
/// explicit light/dark pair via `Color.adaptive`. No `.preferredColorScheme`
/// override anywhere — the user's system Light/Dark/Auto setting decides.
enum AppTheme {
    static let text = Color(UIColor.label)
    static let background = Color(UIColor.systemBackground)
    static let tint = Color(hex: "0A7EA4")
    static let icon = Color(UIColor.secondaryLabel)
    static let cardBackground = Color(UIColor.systemBackground)
    static let subtext = Color(UIColor.secondaryLabel)
    static let border = Color(UIColor.separator)
    static let modalOverlay = Color.black.opacity(0.5)

    /// From app.json splash backgroundColor — used as the brand accent on
    /// auth/onboarding surfaces. Kept constant across appearances, like
    /// most apps do with their brand color.
    static let brandAccent = Color(hex: "5A62F2")

    /// Fixed dark surface for chrome that pairs with a hardcoded `.white`
    /// foreground — the floating tab bar (MainTabView) and onboarding's
    /// dark pill buttons. Unlike `text`, this one must NOT adapt: swapping
    /// it for `text` broke in Dark Mode (white background + white/adapted
    /// text) because those call sites hardcode `.white`, not `AppTheme.background`.
    static let tabBarBackground = Color(hex: "11181C")

    /// Pastel tile backgrounds for the Home screen's start weight / goal /
    /// daily calories stat row — light-mode pastels would look washed out
    /// (and their dark text would go near-invisible) on a dark background,
    /// so dark mode gets a deeper, desaturated tint of the same hue instead.
    static let statGreen = Color.adaptive(light: "DDF3E4", dark: "1E3A2A")
    static let statBlue = Color.adaptive(light: "DCEEFB", dark: "1B3648")
    static let statOrange = Color.adaptive(light: "FCEAD2", dark: "45301A")
}

/// Shared by ExercisesView's row and ExerciseDetailView's hero. The bundled
/// catalog's `imageUrl` values were placeholder Giphy/Pexels links (never
/// meant for production) and have been cleared to "" — this renders a
/// neutral icon in their place until real artwork is added per exercise.
struct ExerciseThumbnail: View {
    let imageUrl: String
    /// nil width fills available horizontal space (hero use); a fixed
    /// value produces a square row thumbnail.
    var width: CGFloat? = 56
    var height: CGFloat = 56
    var cornerRadius: CGFloat = 12

    var body: some View {
        Group {
            if imageUrl.isEmpty {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.brandAccent.opacity(0.1))
                    .overlay(
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: height * 0.35))
                            .foregroundColor(AppTheme.brandAccent)
                    )
            } else {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    AppTheme.border
                }
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    /// A color that resolves to `light` or `dark` hex depending on the
    /// active trait collection, tracking Dark Mode the same way UIKit's
    /// own semantic colors do (unlike a plain fixed-hex Color).
    static func adaptive(light: String, dark: String) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light))
        })
    }
}
