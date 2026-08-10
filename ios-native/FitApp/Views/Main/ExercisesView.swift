import SwiftUI

/// Mirrors app/(tabs)/exercises.tsx — category filter chips + searchable
/// grid over the bundled exercise catalog (ExerciseDataStore).
struct ExercisesView: View {
    @ObservedObject private var store = ExerciseDataStore.shared
    @State private var selectedCategory: ExerciseCategory?
    @State private var searchText = ""

    private var filtered: [Exercise] {
        let base = store.exercises(in: selectedCategory)
        guard !searchText.isEmpty else { return base }
        let lowered = searchText.lowercased()
        return base.filter { $0.title.lowercased().contains(lowered) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                categoryChips

                List(filtered) { exercise in
                    NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                        ExerciseRow(exercise: exercise)
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: L("common.search"))
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(L("home.exercises"))
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: L("common.all"), isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(ExerciseCategory.allCases) { category in
                    chip(
                        title: category.rawValue.capitalized,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.tint : AppTheme.cardBackground)
                .foregroundColor(isSelected ? .white : AppTheme.text)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : AppTheme.border)
                )
                .cornerRadius(20)
        }
    }
}

private struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: exercise.imageUrl)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                AppTheme.border
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.title)
                    .font(.body.weight(.semibold))
                    .foregroundColor(AppTheme.text)
                Text(exercise.muscles.joined(separator: ", "))
                    .font(.footnote)
                    .foregroundColor(AppTheme.subtext)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Image(systemName: "person.2.fill")
                Text("%\(exercise.popularity)")
                    .font(.caption2)
            }
            .foregroundColor(AppTheme.tint)
        }
        .padding(.vertical, 4)
    }
}
