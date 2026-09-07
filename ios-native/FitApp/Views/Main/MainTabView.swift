import SwiftUI

/// Custom floating pill tab bar, replacing the plain TabView this port
/// originally shipped with (see the old comment here about the RN app's
/// FloatingTabBar). All four tabs stay mounted in a ZStack (shown/hidden via
/// opacity) rather than recreated on each switch, so per-tab state
/// (scroll position, loaded CloudKit data) survives tab changes the same
/// way TabView's did. "Create" maps to the Weekly Plan screen — the RN
/// app's dedicated create-workout hub behind that tab isn't ported.
struct MainTabView: View {
    private enum Tab: CaseIterable, Hashable {
        case home, exercises, create, profile

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .exercises: return "figure.strengthtraining.traditional"
            case .create: return "plus.circle.fill"
            case .profile: return "person.fill"
            }
        }

        @MainActor
        func label() -> String {
            switch self {
            case .home: return LocalizationManager.shared.language == .tr ? "Ana Sayfa" : "Home"
            case .exercises: return L("home.exercises")
            case .create: return LocalizationManager.shared.language == .tr ? "Oluştur" : "Create"
            case .profile: return L("home.profile")
            }
        }
    }

    @State private var selectedTab: Tab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            HomeView()
                .bottomBarInset()
                .opacity(selectedTab == .home ? 1 : 0)
                .allowsHitTesting(selectedTab == .home)
            ExercisesView()
                .bottomBarInset()
                .opacity(selectedTab == .exercises ? 1 : 0)
                .allowsHitTesting(selectedTab == .exercises)
            WeeklyPlanView()
                .bottomBarInset()
                .opacity(selectedTab == .create ? 1 : 0)
                .allowsHitTesting(selectedTab == .create)
            ProfileView()
                .bottomBarInset()
                .opacity(selectedTab == .profile ? 1 : 0)
                .allowsHitTesting(selectedTab == .profile)

            floatingBar
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    private var floatingBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                        Text(tab.label())
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundColor(selectedTab == tab ? AppTheme.brandAccent : .white.opacity(0.55))
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 28).fill(AppTheme.text))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

private extension View {
    /// Keeps scrollable content from being hidden behind the floating tab
    /// bar overlay.
    func bottomBarInset() -> some View {
        safeAreaInset(edge: .bottom) { Color.clear.frame(height: 78) }
    }
}
