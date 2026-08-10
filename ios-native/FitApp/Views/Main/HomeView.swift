import SwiftUI

/// Mirrors app/(tabs)/home.tsx — greeting header + today's workout card +
/// quick actions. Wired to real Firestore data (UserProfileService,
/// DailyPlanService); the RN version's AI suggestion / rest-day-swap modals
/// (AISuggestionModal, RestDaySuggestionModal) are not ported yet.
struct HomeView: View {
    @EnvironmentObject private var profileService: UserProfileService
    @StateObject private var dailyPlan = DailyPlanService(dateKey: DateKey.today)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    todaysWorkoutCard

                    quickActions
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("FitApp")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            dailyPlan.start(for: profileService.profile?.uid)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(L("home.hello")), \(profileService.profile?.name ?? "")")
                .font(.title2.bold())
                .foregroundColor(AppTheme.text)
            Text(L("home.letsKeepGoing"))
                .font(.subheadline)
                .foregroundColor(AppTheme.subtext)
        }
    }

    private var todaysWorkoutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("home.todaysWorkout"))
                .font(.headline)
                .foregroundColor(AppTheme.text)

            if dailyPlan.isLoading {
                ProgressView()
            } else if dailyPlan.plan.items.isEmpty {
                Text(L("home.noWorkoutScheduled"))
                    .foregroundColor(AppTheme.subtext)
            } else {
                Text("\(dailyPlan.plan.items.count) \(L("home.exercisesPlanned"))")
                    .foregroundColor(AppTheme.subtext)
                ForEach(dailyPlan.plan.items.prefix(3)) { item in
                    HStack {
                        Text(item.title)
                            .foregroundColor(AppTheme.text)
                        Spacer()
                        Text("\(item.sets)x\(item.reps)")
                            .foregroundColor(AppTheme.subtext)
                            .font(.footnote)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border))
        .cornerRadius(16)
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("home.quickActions"))
                .font(.headline)
                .foregroundColor(AppTheme.text)

            HStack(spacing: 12) {
                NavigationLink(destination: ExercisesView()) {
                    quickActionChip(icon: "figure.strengthtraining.traditional", label: L("home.browse"))
                }
                NavigationLink(destination: WeeklyPlanView()) {
                    quickActionChip(icon: "calendar", label: L("home.weeklyPlan"))
                }
            }
        }
    }

    private func quickActionChip(icon: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
            Text(label)
                .font(.footnote)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border))
        .cornerRadius(14)
        .foregroundColor(AppTheme.tint)
    }
}
