import SwiftUI

/// New screen (not in the RN app): a simple geometric body diagram showing
/// which muscle groups were trained today vs. this week, and which weren't
/// touched at all. See BodyDiagramView for the drawing, MuscleMapService
/// for the CloudKit aggregation.
struct MuscleMapView: View {
    private enum Period: String, CaseIterable, Identifiable {
        case today = "Bugün"
        case week = "Bu Hafta"
        case month = "Bu Ay"
        var id: String { rawValue }
    }

    @StateObject private var service = MuscleMapService()
    @State private var period: Period = .today

    private var activation: MuscleActivation {
        switch period {
        case .today: return service.today
        case .week: return service.thisWeek
        case .month: return service.thisMonth
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    periodPicker

                    if service.isLoading {
                        ProgressView().padding(.top, 40)
                    } else {
                        diagrams
                        legend
                        otherActivitiesNote
                    }
                }
                .padding()
                .padding(.bottom, 90)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Kas Haritası")
            .navigationBarTitleDisplayMode(.inline)
            .task { await service.loadToday() }
            .onChange(of: period) { newValue in
                Task {
                    switch newValue {
                    case .today: await service.loadToday()
                    case .week: await service.loadThisWeek()
                    case .month: await service.loadThisMonth()
                    }
                }
            }
        }
    }

    private var periodPicker: some View {
        Picker("Dönem", selection: $period) {
            ForEach(Period.allCases) { p in
                Text(p.rawValue).tag(p)
            }
        }
        .pickerStyle(.segmented)
    }

    private var diagrams: some View {
        HStack(spacing: 24) {
            VStack(spacing: 8) {
                BodyDiagramView(side: .front, colorFor: color(for:))
                Text("Ön").font(.caption).foregroundColor(AppTheme.subtext)
            }
            VStack(spacing: 8) {
                BodyDiagramView(side: .back, colorFor: color(for:))
                Text("Arka").font(.caption).foregroundColor(AppTheme.subtext)
            }
        }
    }

    private func color(for muscle: PrimaryMuscle) -> Color {
        let count = activation.counts[muscle] ?? 0
        guard count > 0 else { return Color(hex: "E5E5EA") }
        let opacity = min(1.0, 0.4 + Double(count) * 0.2)
        return AppTheme.tint.opacity(opacity)
    }

    private let trackedMuscles: [PrimaryMuscle] = [.chest, .back, .shoulders, .biceps, .triceps, .legs, .core]

    private var legendTitle: String {
        switch period {
        case .today: return "Bugün Çalışılanlar"
        case .week: return "Bu Hafta Çalışılanlar"
        case .month: return "Bu Ay Çalışılanlar"
        }
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(legendTitle)
                .font(.headline)
                .foregroundColor(AppTheme.text)

            ForEach(trackedMuscles) { muscle in
                let count = activation.counts[muscle] ?? 0
                HStack {
                    Circle()
                        .fill(count > 0 ? AppTheme.tint : Color(hex: "E5E5EA"))
                        .frame(width: 10, height: 10)
                    Text(muscleLabel(muscle))
                        .foregroundColor(AppTheme.text)
                    Spacer()
                    Text(count > 0 ? "\(count) egzersiz" : "Çalışılmadı")
                        .font(.footnote)
                        .foregroundColor(count > 0 ? AppTheme.tint : AppTheme.subtext)
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border))
        .cornerRadius(16)
    }

    private var otherActivitiesNote: some View {
        Group {
            if activation.otherCount > 0 {
                Text("+ \(activation.otherCount) kardiyo/HIIT/esneme hareketi (belirli bir kas bölgesine bağlı değil)")
                    .font(.footnote)
                    .foregroundColor(AppTheme.subtext)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func muscleLabel(_ muscle: PrimaryMuscle) -> String {
        switch muscle {
        case .chest: return "Göğüs"
        case .back: return "Sırt"
        case .shoulders: return "Omuz"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .legs: return "Bacak"
        case .core: return "Karın"
        case .cardio, .hiit, .mobility: return muscle.rawValue
        }
    }
}
