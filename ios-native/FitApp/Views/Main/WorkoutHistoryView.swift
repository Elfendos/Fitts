import SwiftUI

/// New screen: HomeView's History quick action. Lists this month's
/// completed / in-progress days from CloudKit `DailyPlan` records — not
/// previously ported to this native app.
struct WorkoutHistoryView: View {
    @StateObject private var service = WorkoutHistoryService()

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        formatter.locale = LocalizationManager.shared.language == .tr
            ? Locale(identifier: "tr_TR")
            : Locale(identifier: "en_US")
        return formatter.string(from: Date())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(monthTitle)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.subtext)

                if service.isLoading {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                } else if service.entries.isEmpty {
                    Text(L("home.noWorkoutScheduled"))
                        .foregroundColor(AppTheme.subtext)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else {
                    ForEach(service.entries) { entry in
                        dayCard(entry)
                    }
                }

                footerNote
            }
            .padding()
            .padding(.bottom, 90)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(L("home.history"))
        .navigationBarTitleDisplayMode(.large)
        .task { await service.loadThisMonth() }
    }

    private func dayCard(_ entry: WorkoutHistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(entry.isCompleted ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                        .font(.headline)
                        .foregroundColor(AppTheme.text)
                    Text("\(entry.completedCount)/\(entry.items.count) \(L("exercises.title"))")
                        .font(.footnote)
                        .foregroundColor(AppTheme.subtext)
                }
                Spacer()
                Text(entry.isCompleted ? L("common.done") : "\(Int(entry.progress * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(entry.isCompleted ? .green : .orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background((entry.isCompleted ? Color.green : Color.orange).opacity(0.12))
                    .cornerRadius(10)
            }

            Divider()

            ForEach(entry.items.prefix(4)) { item in
                HStack {
                    Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(item.completed ? .green : AppTheme.border)
                    Text(item.title)
                        .strikethrough(item.completed)
                        .foregroundColor(item.completed ? AppTheme.subtext : AppTheme.text)
                    Spacer()
                    Text("\(item.sets)×\(item.reps)")
                        .font(.footnote)
                        .foregroundColor(AppTheme.subtext)
                }
            }

            if entry.items.count > 4 {
                Text(moreLabel(entry.items.count - 4))
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(AppTheme.brandAccent)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border))
        .cornerRadius(16)
    }

    private func moreLabel(_ count: Int) -> String {
        LocalizationManager.shared.language == .tr ? "+\(count) egzersiz daha" : "+\(count) more"
    }

    private var footerNote: some View {
        Label(
            LocalizationManager.shared.language == .tr
                ? "Geçmiş her ayın başında sıfırlanır"
                : "History resets at the beginning of each month",
            systemImage: "info.circle"
        )
        .font(.footnote)
        .foregroundColor(AppTheme.subtext)
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.border.opacity(0.3))
        .cornerRadius(12)
    }
}
