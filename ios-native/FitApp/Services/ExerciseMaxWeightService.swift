import Foundation
import CloudKit

/// Remembers the last max weight logged per exercise (by Exercise.id) so
/// that adding the same exercise to a later day pre-fills it instead of
/// starting from 0 every time. A singleton (like ExerciseDataStore.shared),
/// not environment-injected, so any view that adds an exercise — Today's
/// Workout, the Exercise Detail "Add to Today" button, Quick Start day
/// packages — can read/write it without threading it through every init.
/// One CloudKit record (JSON blob), same pattern as WorkoutPlansDoc.
@MainActor
final class ExerciseMaxWeightService: ObservableObject {
    static let shared = ExerciseMaxWeightService()

    @Published private(set) var weights: [String: Double] = [:]
    private var isLoaded = false
    private let db = CloudKitManager.privateDatabase
    private static let recordID = CKRecord.ID(recordName: "CurrentUserMaxWeights")

    private init() {}

    func loadIfNeeded() async {
        guard !isLoaded else { return }
        isLoaded = true
        guard let record = try? await db.record(for: Self.recordID),
              let data = record["weightsJSON"] as? Data,
              let decoded = try? JSONDecoder().decode([String: Double].self, from: data) else {
            return
        }
        weights = decoded
    }

    func weight(for exerciseId: String) -> Double? {
        weights[exerciseId]
    }

    func record(exerciseId: String, weight: Double) {
        guard weight > 0 else { return }
        weights[exerciseId] = weight
        Task { await save() }
    }

    private func save() async {
        let record: CKRecord
        if let existing = try? await db.record(for: Self.recordID) {
            record = existing
        } else {
            record = CKRecord(recordType: CloudKitRecordType.exerciseMaxWeights, recordID: Self.recordID)
        }
        guard let data = try? JSONEncoder().encode(weights) else { return }
        record["weightsJSON"] = data as CKRecordValue
        _ = try? await db.save(record)
    }
}
