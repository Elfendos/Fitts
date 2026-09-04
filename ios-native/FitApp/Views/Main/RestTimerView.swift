import SwiftUI

/// Rest-between-sets timer, opened as a sheet (see HomeView's quick actions
/// and ExerciseDetailView). Presets: 1 dk / 3 dk, plus a custom duration via
/// a stepper (15s increments). See RestTimerService for how the completion
/// beep is delivered in foreground vs. background/locked.
struct RestTimerView: View {
    @StateObject private var timerService = RestTimerService()
    @State private var customSeconds: Int = 60
    @Environment(\.dismiss) private var dismiss

    private var progress: Double {
        guard timerService.duration > 0 else { return 0 }
        return 1 - (Double(timerService.remainingSeconds) / timerService.duration)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                presetPicker

                countdownRing

                controls

                if timerService.notificationPermissionDenied {
                    Label(
                        "Bildirim izni kapalı — uygulama arka plandayken/telefon kilitliyken ses çalmayabilir.",
                        systemImage: "bell.slash"
                    )
                    .font(.footnote)
                    .foregroundColor(.orange)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding(.top, 24)
            .padding(.horizontal)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Dinlenme Sayacı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("common.close")) { dismiss() }
                }
            }
        }
    }

    private var presetPicker: some View {
        HStack(spacing: 12) {
            ForEach(RestTimerService.Preset.allCases) { preset in
                presetButton(label: preset.label, seconds: Int(preset.rawValue))
            }
            customDurationStepper
        }
    }

    private func presetButton(label: String, seconds: Int) -> some View {
        let isSelected = Int(timerService.duration) == seconds
        return Button {
            timerService.setDuration(TimeInterval(seconds))
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(isSelected ? AppTheme.tint : AppTheme.cardBackground)
                .foregroundColor(isSelected ? .white : AppTheme.text)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(isSelected ? Color.clear : AppTheme.border))
                .cornerRadius(14)
        }
        .disabled(timerService.isRunning)
    }

    private var customDurationStepper: some View {
        let isCustomSelected = Int(timerService.duration) == customSeconds
            && customSeconds != 60 && customSeconds != 180
        return Menu {
            Stepper(
                "\(customSeconds) sn",
                value: Binding(
                    get: { customSeconds },
                    set: { newValue in
                        customSeconds = max(15, newValue)
                        timerService.setDuration(TimeInterval(customSeconds))
                    }
                ),
                in: 15...600,
                step: 15
            )
        } label: {
            Text(isCustomSelected ? "\(customSeconds) sn" : "Özel")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(isCustomSelected ? AppTheme.tint : AppTheme.cardBackground)
                .foregroundColor(isCustomSelected ? .white : AppTheme.text)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(isCustomSelected ? Color.clear : AppTheme.border))
                .cornerRadius(14)
        }
        .disabled(timerService.isRunning)
    }

    private var countdownRing: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.border, lineWidth: 14)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    timerService.didFinish ? Color.green : AppTheme.tint,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: progress)

            VStack(spacing: 4) {
                Text(formatted(timerService.remainingSeconds))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.text)
                if timerService.didFinish {
                    Text("Süre bitti 🎉")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.green)
                }
            }
        }
        .frame(width: 220, height: 220)
        .padding(.vertical, 12)
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Button {
                timerService.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .frame(width: 56, height: 56)
                    .background(AppTheme.cardBackground)
                    .overlay(Circle().stroke(AppTheme.border))
                    .clipShape(Circle())
                    .foregroundColor(AppTheme.text)
            }

            Button {
                timerService.isRunning ? timerService.pause() : timerService.start()
            } label: {
                Image(systemName: timerService.isRunning ? "pause.fill" : "play.fill")
                    .font(.title.weight(.bold))
                    .frame(width: 84, height: 84)
                    .background(AppTheme.brandAccent)
                    .clipShape(Circle())
                    .foregroundColor(.white)
            }
        }
    }

    private func formatted(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
