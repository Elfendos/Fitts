import SwiftUI

/// Full port of app/(tabs)/weekly-plan.tsx's core loop: multiple named plans,
/// one marked active, each with its own Mon–Sun exercise schedule, plus the
/// "Smart Plan Generator" preview/save flow. Replaces the first native pass
/// (single implicit plan editing that week's concrete DailyPlan records —
/// see WorkoutPlanService for the new recurring-template model). Drag-
/// reorder and AI import from the RN screen are still not ported.
struct WeeklyPlanView: View {
    @EnvironmentObject private var planService: WorkoutPlanService
    @State private var selectedPlanId: String?
    @State private var isEditingName = false
    @State private var draftName = ""
    @State private var showingExercisePicker: String?
    @State private var showingSmartGenerator = false

    private var selectedPlan: WorkoutPlan? {
        guard let selectedPlanId else { return planService.plans.first }
        return planService.plans.first { $0.id == selectedPlanId } ?? planService.plans.first
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                if planService.isLoading {
                    ProgressView().frame(maxHeight: .infinity)
                } else if planService.plans.isEmpty {
                    emptyState
                } else {
                    planPicker
                    planNameRow
                    dayList
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                planService.start(isAccountAvailable: true)
            }
            .sheet(item: Binding(
                get: { showingExercisePicker.map { IdentifiableString(value: $0) } },
                set: { showingExercisePicker = $0?.value }
            )) { day in
                ExercisePickerSheet { exercise in
                    if let planId = selectedPlan?.id {
                        planService.addExercise(exercise, planId: planId, day: day.value)
                    }
                }
            }
            .sheet(isPresented: $showingSmartGenerator) {
                SmartPlanGeneratorSheet { name, days in
                    planService.addPlan(name: name, days: days)
                    showingSmartGenerator = false
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(L("home.weeklyPlan"))
                    .font(.title2.bold())
                    .foregroundColor(AppTheme.text)
                Text(L("home.buildWeeklyProgram"))
                    .font(.footnote)
                    .foregroundColor(AppTheme.subtext)
            }
            Spacer()
            Button {
                showingSmartGenerator = true
            } label: {
                Image(systemName: "sparkles")
                    .frame(width: 40, height: 40)
                    .background(AppTheme.brandAccent.opacity(0.12))
                    .foregroundColor(AppTheme.brandAccent)
                    .cornerRadius(12)
            }
            Button {
                let newPlan = planService.addPlan(name: L("home.createPlan"))
                selectedPlanId = newPlan.id
            } label: {
                Image(systemName: "plus")
                    .frame(width: 40, height: 40)
                    .background(AppTheme.brandAccent.opacity(0.12))
                    .foregroundColor(AppTheme.brandAccent)
                    .cornerRadius(12)
            }
        }
        .padding()
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.subtext)
            Text(L("home.createFirstPlan"))
                .font(.headline)
                .foregroundColor(AppTheme.text)
            Text(L("home.buildWeeklyProgram"))
                .font(.subheadline)
                .foregroundColor(AppTheme.subtext)
            Button {
                showingSmartGenerator = true
            } label: {
                Label(L("onboarding.pickingExercises"), systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .padding()
                    .frame(maxWidth: .infinity)
            }
            .background(AppTheme.brandAccent)
            .foregroundColor(.white)
            .cornerRadius(14)
            .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Plan picker

    private var planPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(planService.plans) { plan in
                    let isSelected = plan.id == selectedPlan?.id
                    Button {
                        selectedPlanId = plan.id
                    } label: {
                        HStack(spacing: 6) {
                            if plan.isActive {
                                Circle().fill(Color.green).frame(width: 8, height: 8)
                            }
                            Text(plan.name)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(isSelected ? AppTheme.brandAccent : AppTheme.cardBackground)
                        .foregroundColor(isSelected ? .white : AppTheme.text)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? Color.clear : AppTheme.border))
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    private var planNameRow: some View {
        guard let plan = selectedPlan else { return AnyView(EmptyView()) }
        return AnyView(
            HStack {
                if isEditingName {
                    TextField(L("home.createPlan"), text: $draftName, onCommit: {
                        planService.rename(planId: plan.id, name: draftName)
                        isEditingName = false
                    })
                    .font(.title3.bold())
                    .textFieldStyle(.roundedBorder)
                } else {
                    Text(plan.name)
                        .font(.title3.bold())
                        .foregroundColor(AppTheme.text)
                }

                Button {
                    if isEditingName {
                        planService.rename(planId: plan.id, name: draftName)
                    } else {
                        draftName = plan.name
                    }
                    isEditingName.toggle()
                } label: {
                    Image(systemName: "pencil")
                        .frame(width: 32, height: 32)
                        .background(AppTheme.brandAccent.opacity(0.12))
                        .foregroundColor(AppTheme.brandAccent)
                        .cornerRadius(8)
                }

                Spacer()

                if plan.isActive {
                    Text(L("home.active"))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(10)
                } else {
                    Button(L("common.confirm")) {
                        planService.setActive(planId: plan.id)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppTheme.brandAccent)
                }

                if planService.plans.count > 1 {
                    Button {
                        planService.deletePlan(planId: plan.id)
                        selectedPlanId = planService.plans.first?.id
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        )
    }

    // MARK: - Day list

    private var dayList: some View {
        guard let plan = selectedPlan else { return AnyView(EmptyView()) }
        return AnyView(
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(WorkoutPlan.weekdays, id: \.self) { day in
                        dayCard(plan: plan, day: day)
                    }
                }
                .padding()
            }
        )
    }

    private func dayCard(plan: WorkoutPlan, day: String) -> some View {
        let items = plan.exercises(on: day)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(localizedWeekday(day))
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(items.isEmpty ? AppTheme.subtext : AppTheme.brandAccent)
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(fullWeekday(day))
                        .font(.headline)
                        .foregroundColor(AppTheme.text)
                    Text(items.isEmpty
                        ? L("home.restDay")
                        : "\(items.count) \(L("exercises.title"))")
                        .font(.footnote)
                        .foregroundColor(AppTheme.subtext)
                }

                Spacer()

                Button {
                    showingExercisePicker = day
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 32, height: 32)
                        .background(AppTheme.brandAccent.opacity(0.12))
                        .foregroundColor(AppTheme.brandAccent)
                        .cornerRadius(8)
                }
            }

            if !items.isEmpty {
                Divider()
                ForEach(items) { item in
                    exerciseRow(planId: plan.id, day: day, item: item)
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border))
        .cornerRadius(16)
    }

    private func exerciseRow(planId: String, day: String, item: PlannedExercise) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppTheme.text)
            HStack(spacing: 10) {
                compactStepper(value: item.sets, suffix: L("exercises.sets")) { newValue in
                    planService.updateSets(planId: planId, day: day, plannedId: item.plannedId, sets: newValue)
                }
                Text("×").foregroundColor(AppTheme.subtext)
                compactStepper(value: item.reps, suffix: L("exercises.reps")) { newValue in
                    planService.updateReps(planId: planId, day: day, plannedId: item.plannedId, reps: newValue)
                }
                Spacer()
                Button {
                    planService.removeExercise(planId: planId, day: day, plannedId: item.plannedId)
                } label: {
                    Image(systemName: "trash")
                        .font(.footnote)
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func compactStepper(value: Int, suffix: String, onChange: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 6) {
            Button { onChange(max(1, value - 1)) } label: {
                Image(systemName: "minus")
                    .font(.caption2.weight(.semibold))
                    .frame(width: 24, height: 24)
                    .background(AppTheme.border.opacity(0.5))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            Text("\(value) \(suffix)")
                .font(.caption.weight(.semibold))
                .foregroundColor(AppTheme.text)
            Button { onChange(value + 1) } label: {
                Image(systemName: "plus")
                    .font(.caption2.weight(.semibold))
                    .frame(width: 24, height: 24)
                    .background(AppTheme.border.opacity(0.5))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .foregroundColor(AppTheme.text)
    }

    private func localizedWeekday(_ abbrev: String) -> String {
        LocalizationManager.shared.language == .tr ? trAbbrev(abbrev) : abbrev
    }

    private func fullWeekday(_ abbrev: String) -> String {
        let map: [String: (en: String, tr: String)] = [
            "Mon": ("Monday", "Pazartesi"), "Tue": ("Tuesday", "Salı"),
            "Wed": ("Wednesday", "Çarşamba"), "Thu": ("Thursday", "Perşembe"),
            "Fri": ("Friday", "Cuma"), "Sat": ("Saturday", "Cumartesi"),
            "Sun": ("Sunday", "Pazar"),
        ]
        guard let pair = map[abbrev] else { return abbrev }
        return LocalizationManager.shared.language == .tr ? pair.tr : pair.en
    }

    private func trAbbrev(_ abbrev: String) -> String {
        let map = ["Mon": "Pzt", "Tue": "Sal", "Wed": "Çar", "Thu": "Per", "Fri": "Cum", "Sat": "Cmt", "Sun": "Paz"]
        return map[abbrev] ?? abbrev
    }
}

private struct IdentifiableString: Identifiable {
    let value: String
    var id: String { value }
}

/// Shared by WeeklyPlanView and TodayWorkoutView.
struct ExercisePickerSheet: View {
    @ObservedObject private var store = ExerciseDataStore.shared
    @Environment(\.dismiss) private var dismiss
    let onPick: (Exercise) -> Void

    var body: some View {
        NavigationStack {
            List(store.all) { exercise in
                Button {
                    onPick(exercise)
                    dismiss()
                } label: {
                    Text(exercise.title).foregroundColor(AppTheme.text)
                }
            }
            .navigationTitle(L("home.addExercise"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("common.close")) { dismiss() }
                }
            }
        }
    }
}

/// "Smart Plan Generator" preview/save sheet — see WorkoutTemplateGenerator
/// for the fixed push/pull/legs template this previews.
private struct SmartPlanGeneratorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String, [String: [PlannedExercise]]) -> Void

    private let split = WorkoutTemplateGenerator.resolvedWeeklySplit()
    private let order = ["Mon", "Wed", "Fri"]
    private let fullNames = ["Mon": "Monday", "Wed": "Wednesday", "Fri": "Friday"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "sparkles")
                        .frame(width: 44, height: 44)
                        .background(AppTheme.brandAccent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    VStack(alignment: .leading) {
                        Text(L("smartPlan.title")).font(.headline).foregroundColor(AppTheme.text)
                        Text(L("smartPlan.subtitle")).font(.caption).foregroundColor(AppTheme.subtext)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .frame(width: 32, height: 32)
                            .background(AppTheme.border.opacity(0.4))
                            .clipShape(Circle())
                    }
                }
                .padding()

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(order, id: \.self) { day in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(fullNames[day] ?? day)
                                    .font(.headline)
                                    .foregroundColor(AppTheme.text)
                                ForEach(split[day] ?? []) { item in
                                    HStack {
                                        Image(systemName: "dumbbell.fill")
                                            .foregroundColor(AppTheme.brandAccent)
                                        Text(item.title).foregroundColor(AppTheme.text)
                                        Spacer()
                                        Text("\(item.sets)×\(item.reps)")
                                            .font(.footnote)
                                            .foregroundColor(AppTheme.subtext)
                                    }
                                }
                            }
                            .padding()
                            .background(AppTheme.background)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }

                HStack(spacing: 12) {
                    Button(L("common.back")) { dismiss() }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(AppTheme.brandAccent)
                        .background(AppTheme.brandAccent.opacity(0.12))
                        .cornerRadius(14)

                    Button {
                        onSave(L("onboarding.firstPlanName"), split)
                    } label: {
                        Label(L("common.save"), systemImage: "square.and.arrow.down")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .foregroundColor(.white)
                    .background(AppTheme.brandAccent)
                    .cornerRadius(14)
                }
                .padding()
            }
            .background(AppTheme.cardBackground.ignoresSafeArea())
        }
    }
}
