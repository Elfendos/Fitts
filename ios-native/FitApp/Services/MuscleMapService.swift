import Foundation
import CloudKit

/// Aggregates trained-vs-untrained muscle groups for "today" and "this
/// week", for the body-map screen (BodyDiagramView/MuscleMapView). Reads
/// the same `DailyPlan` CKRecords as DailyPlanService/WeeklyPlanView —
/// weekly is 7 known-recordID fetches (Mon..Sun), same pattern already
/// used for the week strip in WeeklyPlanView, batched via
/// `CKDatabase.records(for:)` rather than a query (no query index needed).
struct MuscleActivation {
    var counts: [PrimaryMuscle: Int] = [:]
    var otherCount = 0 // cardio / HIIT / mobility — not body-region-specific

    mutating func add(_ muscle: PrimaryMuscle) {
        switch muscle {
        case .cardio, .hiit, .mobility:
            otherCount += 1
        default:
            counts[muscle, default: 0] += 1
        }
    }

    static func from(_ items: [PlannedExercise]) -> MuscleActivation {
        var activation = MuscleActivation()
        for item in items {
            activation.add(item.resolvedPrimaryMuscle)
        }
        return activation
    }

    static func merging(_ activations: [MuscleActivation]) -> MuscleActivation {
        var result = MuscleActivation()
        for a in activations {
            for (muscle, count) in a.counts {
                result.counts[muscle, default: 0] += count
            }
            result.otherCount += a.otherCount
        }
        return result
    }
}

@MainActor
final class MuscleMapService: ObservableObject {

    @Published private(set) var today = MuscleActivation()
    @Published private(set) var thisWeek = MuscleActivation()
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let db = CloudKitManager.privateDatabase

    func loadToday() async {
        isLoading = true
        errorMessage = nil
        let items = await fetchItems(dateKey: DateKey.today)
        today = MuscleActivation.from(items)
        isLoading = false
    }

    func loadThisWeek() async {
        isLoading = true
        errorMessage = nil
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let dateKeys = (0..<7).compactMap { offset -> String? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else { return nil }
            return DateKey.from(date)
        }

        let recordIDs = dateKeys.map { DailyPlanDoc.recordID(for: $0) }
        var allItems: [PlannedExercise] = []
        do {
            let results = try await db.records(for: recordIDs)
            for id in recordIDs {
                if case .success(let record) = results[id], let doc = DailyPlanDoc(record: record) {
                    allItems.append(contentsOf: doc.items)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        thisWeek = MuscleActivation.from(allItems)
        isLoading = false
    }

    private func fetchItems(dateKey: String) async -> [PlannedExercise] {
        do {
            let record = try await db.record(for: DailyPlanDoc.recordID(for: dateKey))
            return DailyPlanDoc(record: record)?.items ?? []
        } catch {
            return []
        }
    }
}
