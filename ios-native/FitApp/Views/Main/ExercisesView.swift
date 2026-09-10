import SwiftUI

/// Mirrors app/(tabs)/exercises.tsx — category filter chips + searchable
/// grid over the bundled exercise catalog (ExerciseDataStore). Adds a
/// "Quick Start" row of ready-made body-part-split day packages (Leg Day,
/// Back & Biceps, ...) above the full catalog — most people pick a day's
/// workout by split rather than browsing 160 exercises one at a time.
struct ExercisesView: View {
    @ObservedObject private var store = ExerciseDataStore.shared
    @State private var selectedCategory: ExerciseCategory?
    @State private var searchText = ""
    @State private var selectedPackage: WorkoutTemplateGenerator.DayPackage?

    private var filtered: [Exercise] {
        let base = store.exercises(in: selectedCategory)
        guard !searchText.isEmpty else { return base }
        let lowered = searchText.lowercased()
        return base.filter { $0.title.lowercased().contains(lowered) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    quickStartSection

                    Text(L("quickStart.allExercises"))
                        .font(.headline)
                        .foregroundColor(AppTheme.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 12)

                    categoryChips
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { exercise in
                            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                ExerciseRow(exercise: exercise)
                            }
                            Divider().padding(.leading)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 90)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(L("home.exercises"))
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: L("common.search")
            )
            .sheet(item: $selectedPackage) { package in
                DayPackageDetailSheet(package: package)
            }
        }
    }

    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("quickStart.title"))
                .font(.headline)
                .foregroundColor(AppTheme.text)
                .padding(.horizontal)
                .padding(.top, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: [GridItem(.fixed(128), spacing: 12), GridItem(.fixed(128), spacing: 12)], spacing: 12) {
                    ForEach(WorkoutTemplateGenerator.dayPackages) { package in
                        Button {
                            selectedPackage = package
                        } label: {
                            quickStartCard(package)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 268)
        }
    }

    private func quickStartCard(_ package: WorkoutTemplateGenerator.DayPackage) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: package.icon)
                .font(.system(size: 22))
                .foregroundColor(AppTheme.brandAccent)
                .frame(width: 44, height: 44)
                .background(AppTheme.brandAccent.opacity(0.12))
                .cornerRadius(12)

            Spacer(minLength: 0)

            Text(packageTitle(package.id))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppTheme.text)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(package.exercises.count) \(L("exercises.title"))")
                .font(.caption)
                .foregroundColor(AppTheme.subtext)
        }
        .padding(14)
        .frame(width: 128, height: 128, alignment: .leading)
        .background(AppTheme.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border))
        .cornerRadius(16)
    }

    private func packageTitle(_ id: String) -> String {
        L("quickStart.\(id)")
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
            ExerciseThumbnail(imageUrl: exercise.imageUrl, width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.title)
                    .font(.body.weight(.semibold))
                    .foregroundColor(AppTheme.text)
                    .lineLimit(1)
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

/// Preview for a single Quick Start day package — resolved exercise list
/// plus a one-tap "add all to today" action (reuses the same DailyPlan
/// write path as ExerciseDetailView's single-exercise Add to Today).
private struct DayPackageDetailSheet: View {
    let package: WorkoutTemplateGenerator.DayPackage
    @Environment(\.dismiss) private var dismiss
    @StateObject private var todayPlan = DailyPlanService(dateKey: DateKey.today)
    @State private var didAdd = false

    private var resolved: [PlannedExercise] {
        WorkoutTemplateGenerator.resolve(package.exercises)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List(resolved) { item in
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
                .listStyle(.plain)

                Button {
                    for item in resolved {
                        if let exercise = ExerciseDataStore.shared.exercise(id: item.id) {
                            todayPlan.addExercise(exercise, sets: item.sets, reps: item.reps)
                        }
                    }
                    Task { await todayPlan.save() }
                    didAdd = true
                } label: {
                    Label(
                        didAdd ? L("quickStart.addedToToday") : L("quickStart.addAllToToday"),
                        systemImage: didAdd ? "checkmark.circle.fill" : "plus.circle.fill"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .background(didAdd ? Color.green : AppTheme.brandAccent)
                .foregroundColor(.white)
                .cornerRadius(14)
                .disabled(didAdd)
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(L("quickStart.\(package.id)"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("common.close")) { dismiss() }
                }
            }
            .onAppear { todayPlan.start(isAccountAvailable: true) }
        }
    }
}
