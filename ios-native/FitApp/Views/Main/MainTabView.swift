import SwiftUI

/// Mirrors app/(tabs)/_layout.tsx. The RN version uses a custom
/// FloatingTabBar with Home/Exercises visible and Profile/WeeklyPlan reached
/// via header/FAB; this port uses a standard TabView with all four visible
/// for now — swap in a custom `.toolbar`/overlay tab bar later if the
/// floating pill look needs to match exactly.
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label(L("home.hello"), systemImage: "house.fill") }

            ExercisesView()
                .tabItem { Label(L("home.exercises"), systemImage: "figure.strengthtraining.traditional") }

            WeeklyPlanView()
                .tabItem { Label(L("home.weeklyPlan"), systemImage: "calendar") }

            ProfileView()
                .tabItem { Label(L("home.profile"), systemImage: "person.fill") }
        }
        .tint(AppTheme.tint)
    }
}
