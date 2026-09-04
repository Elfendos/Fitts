import Foundation
import AVFoundation
import UserNotifications
import UIKit

/// Rest timer between sets — pick a preset (1 dk / 3 dk) or a custom
/// duration, start a countdown, and get a soft beep when it ends.
///
/// Two delivery paths run in parallel so the cue is heard whether the app
/// is in the foreground or the phone is locked/backgrounded (common during
/// a rest period):
///  1. **Foreground**: a repeating `Timer` drives `remainingSeconds` for the
///     UI, and on completion `AVAudioPlayer` plays `rest_timer_beep.wav`
///     directly through the active audio route (headphones included) —
///     this plays even if the phone's silent switch is on, because the
///     audio session category is `.playback`.
///  2. **Background/locked**: a local notification is scheduled up front
///     for `now + duration` with the same sound attached
///     (`UNNotificationSound`). iOS delivers it and plays the sound through
///     whatever output is active — **but, unlike the in-app player, this
///     respects the physical silent switch and Focus/DND settings**, since
///     it's a normal (non-critical) notification. There's no way around
///     that without Apple's Critical Alerts entitlement, which isn't
///     something a fitness app can typically get approved for.
@MainActor
final class RestTimerService: ObservableObject {

    enum Preset: TimeInterval, CaseIterable, Identifiable {
        case oneMinute = 60
        case threeMinutes = 180

        var id: TimeInterval { rawValue }
        var label: String {
            switch self {
            case .oneMinute: return "1 dk"
            case .threeMinutes: return "3 dk"
            }
        }
    }

    @Published private(set) var duration: TimeInterval = Preset.oneMinute.rawValue
    @Published private(set) var remainingSeconds: Int = 60
    @Published private(set) var isRunning = false
    @Published private(set) var didFinish = false
    @Published var notificationPermissionDenied = false

    private var timer: Timer?
    private var endDate: Date?
    private var audioPlayer: AVAudioPlayer?
    private let notificationID = "restTimer.finished"

    // MARK: - Configuration

    func setDuration(_ seconds: TimeInterval) {
        guard !isRunning else { return }
        duration = seconds
        remainingSeconds = Int(seconds)
    }

    // MARK: - Controls

    func start() {
        requestNotificationPermissionIfNeeded()

        didFinish = false
        isRunning = true
        let end = Date().addingTimeInterval(duration)
        endDate = end
        remainingSeconds = Int(duration)

        scheduleCompletionNotification(after: duration)
        prepareAudioPlayer()

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        cancelScheduledNotification()
    }

    func reset() {
        pause()
        didFinish = false
        remainingSeconds = Int(duration)
        endDate = nil
    }

    private func tick() {
        guard let endDate else { return }
        let remaining = endDate.timeIntervalSinceNow
        if remaining <= 0 {
            remainingSeconds = 0
            finish()
        } else {
            remainingSeconds = Int(remaining.rounded(.up))
        }
    }

    private func finish() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        didFinish = true
        playBeep()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        // The notification we scheduled at start() fires independently — if
        // the app is foregrounded when it would've fired, cancel it so the
        // user doesn't get a duplicate sound/banner on top of the one we
        // just played directly.
        cancelScheduledNotification()
    }

    // MARK: - Audio

    private func prepareAudioPlayer() {
        guard let url = Bundle.main.url(forResource: "rest_timer_beep", withExtension: "wav") else { return }
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.prepareToPlay()
    }

    private func playBeep() {
        do {
            // `.playback` (rather than `.ambient`) so the cue is audible
            // even if the phone's silent switch is on — this only applies
            // while the app itself is driving playback (foreground/active).
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
        if audioPlayer == nil { prepareAudioPlayer() }
        audioPlayer?.play()
    }

    // MARK: - Notifications (background/locked delivery)

    private func requestNotificationPermissionIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { [weak self] settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    Task { @MainActor in self?.notificationPermissionDenied = !granted }
                }
            case .denied:
                Task { @MainActor in self?.notificationPermissionDenied = true }
            default:
                break
            }
        }
    }

    private func scheduleCompletionNotification(after seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Dinlenme Bitti"
        content.body = "Sıradaki sete hazır ol 💪"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("rest_timer_beep.wav"))

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(seconds, 1), repeats: false)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelScheduledNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }
}
