import SwiftUI

/// Mirrors app/(tabs)/home.tsx — greeting header, start/goal/calories stat
/// row, today's workout card, a this-week date strip, quick actions (Today /
/// History) and a My Plans preview. Wired to real CloudKit data
/// (UserProfileService, DailyPlanService); the RN version's AI suggestion /
/// rest-day-swap modals (AISuggestionModal, RestDaySuggestionModal) and the
/// floating pill tab bar are not ported yet.
struct HomeView: View {
    @EnvironmentObject private var profileService: UserProfileService
    @EnvironmentObject private var planService: WorkoutPlanService
    @StateObject private var dailyPlan = DailyPlanService(dateKey: DateKey.today)
    @State private var selectedDate = Date()

    /// MainTabView keeps every tab mounted (opacity toggle, not a real
    /// TabView), so a plain `.onAppear` only fires once at launch — editing
    /// today's plan from the Today tab or Exercises never showed up back
    /// here. Passing whether this tab is currently selected lets `.task(id:)`
    /// reload every time the user returns to Home, not just the first time.
    var isActive: Bool = true

    private var selectedDateKey: String { DateKey.from(selectedDate) }

    private var weekDates: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if profileService.profile?.healthProfile != nil {
                        statRow
                    }

                    todaysWorkoutCard

                    dateStrip

                    quickActions

                    myPlansSection
                }
                .padding()
                .padding(.bottom, 90)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .task(id: isActive) {
            guard isActive else { return }
            dailyPlan.start(isAccountAvailable: true)
            planService.start(isAccountAvailable: true)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(L("home.hello")), \(profileService.profile?.name ?? "")")
                    .font(.title.bold())
                    .foregroundColor(AppTheme.text)
                Text(L("home.letsKeepGoing"))
                    .font(.subheadline)
                    .foregroundColor(AppTheme.subtext)
            }
            Spacer()
            NavigationLink(destination: ProfileView()) {
                Circle()
                    .fill(AppTheme.brandAccent)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(profileService.profile?.initials ?? "U")
                            .font(.headline)
                            .foregroundColor(.white)
                    )
            }
        }
    }

    // MARK: - Stat row

    private var statRow: some View {
        let health = profileService.profile?.healthProfile
        return HStack(spacing: 12) {
            statTile(
                label: L("home.startWeight"),
                value: health.map { String(format: "%.1f kg", $0.startWeightKg) } ?? "--",
                background: AppTheme.statGreen
            )
            statTile(
                label: L("home.goal"),
                value: health.map { String(format: "%.1f kg", $0.targetWeightKg) } ?? "--",
                background: AppTheme.statBlue
            )
            statTile(
                label: L("home.dailyCalories"),
                value: health.map { "\(Int($0.dailyCalories)) kcal" } ?? "--",
                background: AppTheme.statOrange
            )
        }
    }

    private func statTile(label: String, value: String, background: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(background)
        .cornerRadius(14)
    }

    // MARK: - Today's workout card

    private var todaysWorkoutCard: some View {
        let items = dailyPlan.plan.items
        let completedCount = items.filter(\.completed).count
        let progress = items.isEmpty ? 0 : Double(completedCount) / Double(items.count)
        let isToday = Calendar.current.isDateInToday(selectedDate)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.brandAccent)
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L("home.todaysWorkout"))
                        .font(.headline)
                        .foregroundColor(AppTheme.text)
                    Text(items.isEmpty
                        ? L("home.noWorkoutScheduled")
                        : "\(items.count) \(L("home.exercisesPlanned"))")
                        .font(.footnote)
                        .foregroundColor(AppTheme.subtext)
                }

                Spacer()

                NavigationLink(destination: TodayWorkoutView(dateKey: selectedDateKey)) {
                    HStack(spacing: 4) {
                        Text(isToday ? L("home.start") : L("home.check"))
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppTheme.background)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border))
                    .cornerRadius(10)
                }
            }

            if dailyPlan.isLoading {
                ProgressView().frame(maxWidth: .infinity)
            } else if !items.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        ProgressView(value: progress)
                            .tint(AppTheme.brandAccent)
                        Text("\(completedCount)/\(items.count) \(L("common.done"))")
                            .font(.caption)
                            .foregroundColor(AppTheme.subtext)
                            .lineLimit(1)
                    }

                    ForEach(items.prefix(4)) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.completed ? Color.green : AppTheme.brandAccent)
                                .frame(width: 8, height: 8)
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(AppTheme.text)
                            Text("• \(item.sets) \(L("exercises.sets")) × \(item.reps) \(L("exercises.reps"))")
                                .font(.footnote)
                                .foregroundColor(AppTheme.subtext)
                        }
                    }

                    if items.count > 4 {
                        Text(moreExercisesLabel(items.count - 4))
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(AppTheme.brandAccent)
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

    private func moreExercisesLabel(_ count: Int) -> String {
        LocalizationManager.shared.language == .tr
            ? "+\(count) egzersiz daha"
            : "+\(count) more exercises"
    }

    // MARK: - Date strip

    private var dateStrip: some View {
        HStack(spacing: 6) {
            ForEach(weekDates, id: \.self) { date in
                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                Button {
                    selectedDate = date
                    dailyPlan.switchTo(dateKey: DateKey.from(date))
                } label: {
                    VStack(spacing: 4) {
                        Text(date.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.caption2)
                        Text(date.formatted(.dateTime.day()))
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isSelected ? AppTheme.text : Color.clear)
                    .foregroundColor(isSelected ? AppTheme.background : AppTheme.text)
                    .cornerRadius(14)
                }
            }
        }
    }

    // MARK: - Quick actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("home.quickActions"))
                .font(.headline)
                .foregroundColor(AppTheme.text)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    NavigationLink(destination: TodayWorkoutView(dateKey: DateKey.today)) {
                        quickActionCard(
                            icon: "heart.text.square.fill",
                            iconBackground: AppTheme.brandAccent.opacity(0.12),
                            iconColor: AppTheme.brandAccent,
                            title: L("home.workoutLabel"),
                            subtitle: L("home.todaysWorkout")
                        )
                    }
                    NavigationLink(destination: WorkoutHistoryView()) {
                        quickActionCard(
                            icon: "clock.fill",
                            iconBackground: Color.orange.opacity(0.12),
                            iconColor: .orange,
                            title: L("home.history"),
                            subtitle: L("home.thisMonth")
                        )
                    }
                    NavigationLink(destination: MuscleMapView()) {
                        quickActionCard(
                            icon: "figure.arms.open",
                            iconBackground: Color.green.opacity(0.12),
                            iconColor: .green,
                            title: L("home.muscleMap"),
                            subtitle: L("home.muscleMapSubtitle")
                        )
                    }
                }
            }
        }
    }

    private func quickActionCard(icon: String, iconBackground: Color, iconColor: Color, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
                .background(iconBackground)
                .cornerRadius(12)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppTheme.text)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(AppTheme.subtext)
        }
        .frame(width: 140, alignment: .leading)
        .padding()
        .background(AppTheme.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border))
        .cornerRadius(14)
    }

    // MARK: - My plans

    private var myPlansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("home.myPlans"))
                    .font(.headline)
                    .foregroundColor(AppTheme.text)
                Spacer()
                NavigationLink(L("home.seeAll"), destination: WeeklyPlanView())
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.brandAccent)
            }

            if planService.plans.isEmpty {
                NavigationLink(destination: WeeklyPlanView()) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(AppTheme.brandAccent)
                            .cornerRadius(10)
                        Text(L("home.createFirstPlan"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppTheme.text)
                        Spacer()
                    }
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border))
                    .cornerRadius(14)
                }
            } else {
                ForEach(planService.plans.prefix(3)) { plan in
                    NavigationLink(destination: WeeklyPlanView()) {
                        planRow(plan)
                    }
                }
            }
        }
    }

    private func planRow(_ plan: WorkoutPlan) -> some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(AppTheme.brandAccent)
                .cornerRadius(10)
            Text(plan.name)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppTheme.text)
            Spacer()
            if plan.isActive {
                Text(L("home.active"))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(8)
            }
        }
        .padding()
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(plan.isActive ? AppTheme.brandAccent : AppTheme.border, lineWidth: plan.isActive ? 1.5 : 1))
        .cornerRadius(14)
    }
}
