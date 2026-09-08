import SwiftUI

/// New screen: the detail view HomeView's "Start"/"Check" button and Today
/// quick action navigate to — per-exercise sets/reps/max-weight editing and
/// a "Mark as Done" toggle for one day's CloudKit `DailyPlan`. Not in the
/// current codebase before this pass; the RN app's live workout-session
/// stopwatch ("Ready to train?" bar) isn't ported here.
struct TodayWorkoutView: View {
    @StateObject private var dailyPlan: DailyPlanService
    @State private var showingExercisePicker = false

    /// True by default (a fresh push from Home always loads once on
    /// appear). MainTabView's "Today" tab passes whether it's the currently
    /// selected tab instead — that tab instance stays mounted the whole
    /// session (see HomeView's isActive for why), so without this, edits
    /// made elsewhere (Exercises' Add to Today, Quick Start packages)
    /// wouldn't show up here until the app restarted.
    var isActive: Bool = true

    init(dateKey: String, isActive: Bool = true) {
        _dailyPlan = StateObject(wrappedValue: DailyPlanService(dateKey: dateKey))
        self.isActive = isActive
    }

    private var completedCount: Int { dailyPlan.plan.items.filter(\.completed).count }
    private var progress: Double {
        dailyPlan.plan.items.isEmpty ? 0 : Double(completedCount) / Double(dailyPlan.plan.items.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                progressCard

                if dailyPlan.isLoading {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                } else {
                    ForEach(Array(dailyPlan.plan.items.enumerated()), id: \.element.plannedId) { index, item in
                        exerciseCard(index: index, item: item)
                    }
                }

                addMoreButton
            }
            .padding()
            .padding(.bottom, 90)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(L("home.todaysWorkout"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingExercisePicker = true } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerSheet { exercise in
                dailyPlan.addExercise(exercise)
                Task { await dailyPlan.save() }
            }
        }
        .task(id: isActive) {
            guard isActive else { return }
            dailyPlan.start(isAccountAvailable: true)
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L("workout.progress"))
                    .font(.subheadline)
                    .foregroundColor(AppTheme.subtext)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.subheadline.bold())
                    .foregroundColor(.green)
            }
            ProgressView(value: progress).tint(.green)
            Text("\(completedCount) \(L("workout.of")) \(dailyPlan.plan.items.count) \(L("workout.exercisesCompleted"))")
                .font(.footnote)
                .foregroundColor(AppTheme.subtext)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(AppTheme.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border))
        .cornerRadius(16)
    }

    private func exerciseCard(index: Int, item: PlannedExercise) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text("\(index + 1)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28)
                .frame(maxHeight: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.brandAccent)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(AppTheme.text)
                    Spacer()
                    Button {
                        dailyPlan.removeExercise(plannedId: item.plannedId)
                        Task { await dailyPlan.save() }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(AppTheme.subtext)
                            .padding(8)
                            .background(AppTheme.border.opacity(0.4))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 12) {
                    stepperField(label: L("exercises.sets"), value: item.sets) { newValue in
                        dailyPlan.updateSets(plannedId: item.plannedId, sets: newValue)
                        Task { await dailyPlan.save() }
                    }
                    stepperField(label: L("exercises.reps"), value: item.reps) { newValue in
                        dailyPlan.updateReps(plannedId: item.plannedId, reps: newValue)
                        Task { await dailyPlan.save() }
                    }
                }

                maxWeightField(item: item)

                Button {
                    dailyPlan.toggleCompleted(plannedId: item.plannedId)
                    Task { await dailyPlan.save() }
                } label: {
                    Label(L("workout.markAsDone"), systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .background(item.completed ? Color.green : AppTheme.border.opacity(0.4))
                .foregroundColor(item.completed ? .white : AppTheme.subtext)
                .cornerRadius(12)
            }
            .padding()
        }
        .background(AppTheme.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border))
        .cornerRadius(16)
    }

    private func stepperField(label: String, value: Int, onChange: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundColor(AppTheme.subtext)
            HStack {
                stepButton(systemImage: "minus") { onChange(max(1, value - 1)) }
                Text("\(value)")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                stepButton(systemImage: "plus") { onChange(value + 1) }
            }
            .padding(.vertical, 8)
            .background(AppTheme.background)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border))
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity)
    }

    /// 2.5 kg steps (0, 2.5, 5, 7.5, 10, 12.5, ...) — matches how weight
    /// plates actually stack, unlike a plain +1 kg counter.
    private static let maxWeightStep: Double = 2.5

    private func maxWeightField(item: PlannedExercise) -> some View {
        HStack {
            Label(L("workout.maxWeight"), systemImage: "scalemass")
                .font(.subheadline)
                .foregroundColor(AppTheme.text)
            Spacer()
            stepButton(systemImage: "minus") {
                setMaxWeight(item: item, to: (item.maxWeight ?? 0) - Self.maxWeightStep)
            }
            Text(formatWeight(item.maxWeight ?? 0))
                .font(.subheadline.weight(.semibold))
                .frame(minWidth: 40)
            stepButton(systemImage: "plus") {
                setMaxWeight(item: item, to: (item.maxWeight ?? 0) + Self.maxWeightStep)
            }
            Text("kg").font(.caption).foregroundColor(AppTheme.subtext)
        }
        .padding()
        .background(AppTheme.background)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border))
        .cornerRadius(10)
    }

    private func setMaxWeight(item: PlannedExercise, to newValue: Double) {
        let clamped = max(0, newValue)
        dailyPlan.updateMaxWeight(plannedId: item.plannedId, maxWeight: clamped)
        ExerciseMaxWeightService.shared.record(exerciseId: item.id, weight: clamped)
        Task { await dailyPlan.save() }
    }

    private func formatWeight(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }

    private func stepButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.footnote.weight(.semibold))
                .frame(width: 28, height: 28)
                .background(AppTheme.border.opacity(0.5))
                .foregroundColor(AppTheme.text)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var addMoreButton: some View {
        Button {
            showingExercisePicker = true
        } label: {
            Label(L("workout.addMoreExercises"), systemImage: "plus.circle")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding()
        }
        .foregroundColor(AppTheme.brandAccent)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppTheme.brandAccent, style: StrokeStyle(lineWidth: 1.5, dash: [6]))
        )
    }
}
