import Foundation

/// Loads the bundled exercise catalog (Resources/Data/exercises.json — 160
/// exercises extracted from the RN utils/exercisesData.ts) once at launch.
/// Mirrors hooks/useAllExercises.ts, minus the Firestore `all_exercises`
/// mirror/seed step (native app reads the bundled catalog directly).
@MainActor
final class ExerciseDataStore: ObservableObject {

    static let shared = ExerciseDataStore()

    @Published private(set) var all: [Exercise] = []
    @Published private(set) var loadError: String?

    private init() {
        load()
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            loadError = "exercises.json bundle'da bulunamadı."
            return
        }
        do {
            let data = try Data(contentsOf: url)
            all = try JSONDecoder().decode([Exercise].self, from: data)
        } catch {
            loadError = "exercises.json parse edilemedi: \(error)"
        }
    }

    func exercises(in category: ExerciseCategory?) -> [Exercise] {
        guard let category else { return all }
        return all.filter { $0.category == category }
    }

    func exercises(matching query: String) -> [Exercise] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return all }
        let lowered = query.lowercased()
        return all.filter {
            $0.title.lowercased().contains(lowered) ||
            $0.muscles.contains { $0.lowercased().contains(lowered) }
        }
    }

    func exercise(id: String) -> Exercise? {
        all.first { $0.id == id }
    }

    var categoryCounts: [ExerciseCategory: Int] {
        Dictionary(grouping: all, by: \.category).mapValues(\.count)
    }
}
