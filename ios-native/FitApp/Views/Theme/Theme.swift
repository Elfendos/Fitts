import SwiftUI

/// Mirrors constants/theme.ts `Colors.light`. The RN app forces light mode in
/// several key components (see WeeklyPlanCard.tsx), so this port ships with
/// a single light palette; wire up `Colors.dark` here if dark mode should
/// return.
enum AppTheme {
    static let text = Color(hex: "11181C")
    static let background = Color(hex: "FFFFFF")
    static let tint = Color(hex: "0A7EA4")
    static let icon = Color(hex: "687076")
    static let cardBackground = Color(hex: "FFFFFF")
    static let subtext = Color(hex: "666666")
    static let border = Color(hex: "E5E5EA")
    static let modalOverlay = Color.black.opacity(0.5)

    /// From app.json splash backgroundColor — used as the brand accent on
    /// auth/onboarding surfaces.
    static let brandAccent = Color(hex: "5A62F2")

    /// Pastel tile backgrounds for the Home screen's start weight / goal /
    /// daily calories stat row.
    static let statGreen = Color(hex: "DDF3E4")
    static let statBlue = Color(hex: "DCEEFB")
    static let statOrange = Color(hex: "FCEAD2")
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
}
