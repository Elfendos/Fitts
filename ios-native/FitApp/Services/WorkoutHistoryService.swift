import Foundation
import CloudKit

/// Aggregates this month's `DailyPlan` CKRecords for the Workout History
/// screen (HomeView's History quick action). Same known-recordID
/// batch-fetch pattern as MuscleMapService's weekly aggregation — recordID
/// is deterministic from dateKey, so no CKQuery index is needed.
struct WorkoutHistoryEntry: Identifiable {
    var date: Date
    var items: [PlannedExercise]
    var id: String { DateKey.from(date) }

    var completedCount: Int { items.filter(\.completed).count }
    var progress: Double { items.isEmpty ? 0 : Double(completedCount) / Double(items.count) }
    var isCompleted: Bool { !items.isEmpty && completedCount == items.count }
}

@MainActor
final class WorkoutHistoryService: ObservableObject {

    @Published private(set) var entries: [WorkoutHistoryEntry] = []
    @Published private(set) var isLoading = false

    private let db = CloudKitManager.privateDatabase

    func loadThisMonth() async {
        isLoading = true
        let calendar = Calendar.current
        let now = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: now) else {
            isLoading = false
            return
        }

        var dates: [Date] = []
        var cursor = monthInterval.start
        while cursor <= now {
            dates.append(cursor)
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        let recordIDs = dates.map { DailyPlanDoc.recordID(for: DateKey.from($0)) }
        var loaded: [WorkoutHistoryEntry] = []
        if let results = try? await db.records(for: recordIDs) {
            for (date, recordID) in zip(dates, recordIDs) {
                if case .success(let record) = results[recordID],
                   let doc = DailyPlanDoc(record: record),
                   !doc.items.isEmpty {
                    loaded.append(WorkoutHistoryEntry(date: date, items: doc.items))
                }
            }
        }
        entries = loaded.sorted { $0.date > $1.date }
        isLoading = false
    }
}
