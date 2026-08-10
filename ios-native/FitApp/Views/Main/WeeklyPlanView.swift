import SwiftUI

/// Simplified port of app/(tabs)/weekly-plan.tsx. The RN version is a 46KB
/// screen supporting multiple named plans, drag-reorder, AI import, and a
/// rename/duplicate flow — out of scope for this first pass. This view
/// covers the core loop: pick a day this week, add/remove/complete
/// exercises for that day's CloudKit `DailyPlan` record.
struct WeeklyPlanView: View {
    @State private var selectedDate = Date()
    @State private var showingExercisePicker = false
    @StateObject private var dailyPlan = DailyPlanService(dateKey: DateKey.today)

    private var weekDates: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                weekStrip

                if dailyPlan.isLoading {
                    ProgressView().frame(maxHeight: .infinity)
                } else {
                    dayPlanList
                }
            }
            .padding(.top)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(L("home.weeklyPlan"))
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
            .onAppear { reload() }
            .onChange(of: selectedDate) { _, _ in reload() }
        }
    }

    private func reload() {
        dailyPlan.start(isAccountAvailable: true)
    }

    private var weekStrip: some View {
        HStack(spacing: 8) {
            ForEach(weekDates, id: \.self) { date in
                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                Button {
                    selectedDate = date
                } label: {
                    VStack(spacing: 4) {
                        Text(date.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.caption2)
                        Text(date.formatted(.dateTime.day()))
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isSelected ? AppTheme.tint : AppTheme.cardBackground)
                    .foregroundColor(isSelected ? .white : AppTheme.text)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal)
    }

    private var dayPlanList: some View {
        List {
            if dailyPlan.plan.items.isEmpty {
                Text(L("home.noWorkoutScheduled"))
                    .foregroundColor(AppTheme.subtext)
            }
            ForEach(dailyPlan.plan.items) { item in
                HStack {
                    Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(item.completed ? .green : AppTheme.border)
                        .onTapGesture {
                            dailyPlan.toggleCompleted(plannedId: item.plannedId)
                            Task { await dailyPlan.save() }
                        }
                    VStack(alignment: .leading) {
                        Text(item.title).foregroundColor(AppTheme.text)
                        Text("\(item.sets) x \(item.reps)")
                            .font(.footnote)
                            .foregroundColor(AppTheme.subtext)
                    }
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    dailyPlan.removeExercise(plannedId: dailyPlan.plan.items[index].plannedId)
                }
                Task { await dailyPlan.save() }
            }
        }
        .listStyle(.plain)
    }
}

private struct ExercisePickerSheet: View {
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
