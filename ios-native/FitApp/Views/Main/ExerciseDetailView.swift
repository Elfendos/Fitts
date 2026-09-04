import SwiftUI

/// Mirrors components/ExerciseDetailModal.tsx — hero image, instructions,
/// tips, and variation chips. The RN "tap to play" GIF autoplay gate isn't
/// ported (AsyncImage renders GIFs as static frames); revisit with a proper
/// animated-image view if that matters for launch.
struct ExerciseDetailView: View {
    let exercise: Exercise
    @State private var selectedVariation: ExerciseVariation?
    @State private var showingRestTimer = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: URL(string: exercise.imageUrl)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    AppTheme.border
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack {
                    Label(exercise.difficulty.rawValue.capitalized, systemImage: "gauge")
                    Spacer()
                    Label("\(exercise.duration) min", systemImage: "clock")
                    Spacer()
                    Label("\(exercise.calories) cal", systemImage: "flame")
                }
                .font(.footnote)
                .foregroundColor(AppTheme.subtext)

                Button {
                    showingRestTimer = true
                } label: {
                    Label("Dinlenme Sayacı Başlat", systemImage: "timer")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .background(AppTheme.tint.opacity(0.12))
                .foregroundColor(AppTheme.tint)
                .cornerRadius(12)
                .sheet(isPresented: $showingRestTimer) {
                    RestTimerView()
                }

                if let variations = exercise.variations, !variations.isEmpty {
                    variationPicker(variations)
                }

                sectionTitle(L("exercises.howToDoIt"))
                ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .foregroundColor(AppTheme.tint)
                            .fontWeight(.semibold)
                        Text(step)
                            .foregroundColor(AppTheme.text)
                    }
                }

                if let tips = exercise.tips, !tips.isEmpty {
                    sectionTitle("Tips")
                    ForEach(tips, id: \.self) { tip in
                        Label(tip, systemImage: "lightbulb")
                            .foregroundColor(AppTheme.subtext)
                            .font(.footnote)
                    }
                }
            }
            .padding()
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(exercise.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundColor(AppTheme.text)
            .padding(.top, 8)
    }

    private func variationPicker(_ variations: [ExerciseVariation]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Variations")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(variations) { variation in
                        let isSelected = selectedVariation?.id == variation.id
                        Button {
                            selectedVariation = variation
                        } label: {
                            Text(LocalizationManager.shared.language == .tr ? variation.label.tr : variation.label.en)
                                .font(.footnote.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isSelected ? AppTheme.tint : AppTheme.cardBackground)
                                .foregroundColor(isSelected ? .white : AppTheme.text)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border))
                                .cornerRadius(16)
                        }
                    }
                }
            }
            if let selectedVariation {
                Text(LocalizationManager.shared.language == .tr ? selectedVariation.cue.tr : selectedVariation.cue.en)
                    .font(.footnote)
                    .foregroundColor(AppTheme.subtext)
            }
        }
    }
}
