//
//  PomodoroManager.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import SwiftUI
import ActivityKit
import UserNotifications
import Combine
import Observation

// MARK: - ⏱️ Enum Preset Pomodoro Kartun
enum PomodoroPreset: String, CaseIterable, Identifiable {
    case quickFocus = "Fokus Cepat"
    case deepWork = "Deep Work"
    case shortBreak = "Rehat Singkat"
    case longBreak = "Rehat Panjang"

    var id: String { rawValue }

    var minutes: Int {
        switch self {
        case .quickFocus: return 25
        case .deepWork: return 45
        case .shortBreak: return 5
        case .longBreak: return 15
        }
    }

    var duration: TimeInterval {
        TimeInterval(minutes * 60)
    }

    var iconName: String {
        switch self {
        case .quickFocus: return "brain.head.profile"
        case .deepWork: return "flame.fill"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "sparkles"
        }
    }

    var themeColor: Color {
        switch self {
        case .quickFocus: return Color.cartoonYellow
        case .deepWork: return Color.cartoonPink
        case .shortBreak: return Color.cartoonMint
        case .longBreak: return Color.cartoonBlue
        }
    }

    var colorHex: String {
        switch self {
        case .quickFocus: return "#FFD166"
        case .deepWork: return "#FF99C8"
        case .shortBreak: return "#6EE7B7"
        case .longBreak: return "#A0C4FF"
        }
    }

    var isBreak: Bool {
        switch self {
        case .quickFocus, .deepWork: return false
        case .shortBreak, .longBreak: return true
        }
    }
}

// MARK: - 🍅 Status Pomodoro Timer
enum PomodoroState {
    case idle
    case running
    case paused
}

// MARK: - 🍅 Pomodoro Timer State & Live Activity Controller
@Observable
@MainActor
final class PomodoroManager {
    static let shared = PomodoroManager()

    // MARK: - State Properties
    var selectedPreset: PomodoroPreset = .quickFocus
    var remainingSeconds: Int = 25 * 60
    var totalDuration: Int = 25 * 60
    var state: PomodoroState = .idle
    var taskTitle: String = ""
    var isAutoShieldEnabled: Bool = false
    var completedSessionsCount: Int = 0

    var isRunning: Bool {
        state == .running
    }

    var isPaused: Bool {
        state == .paused
    }

    // Live Activity Reference
    @ObservationIgnored private var liveActivity: Activity<PomodoroAttributes>? = nil
    @ObservationIgnored private var timerCancellable: AnyCancellable? = nil
    @ObservationIgnored private var targetEndTime: Date? = nil

    private init() {
        self.totalDuration = selectedPreset.minutes * 60
        self.remainingSeconds = selectedPreset.minutes * 60
    }

    // MARK: - Timer Actions

    /// Memilih preset durasi pomodoro
    func selectPreset(_ preset: PomodoroPreset) {
        guard state == .idle else { return }
        self.selectedPreset = preset
        self.totalDuration = preset.minutes * 60
        self.remainingSeconds = preset.minutes * 60
    }

    /// Memulai Timer
    func startTimer() {
        guard state == .idle else { return }

        HapticManager.shared.impact(style: .heavy)
        HapticManager.shared.success()

        self.state = .running
        self.targetEndTime = Date().addingTimeInterval(TimeInterval(remainingSeconds))

        if isAutoShieldEnabled {
            ScreenTimeManager.shared.enableAppShield()
        }

        // Mulai ActivityKit Dynamic Island / Live Activity
        startLiveActivity()

        // Jadwalkan Notifikasi Selesai di Background
        scheduleCompletionNotification(in: TimeInterval(remainingSeconds))

        // Timer Tick Interval
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    self.timerDidComplete()
                }
            }
    }

    /// Menghentikan Sementara (Pause)
    func pauseTimer() {
        guard state == .running else { return }

        HapticManager.shared.impact(style: .medium)
        self.state = .paused
        self.timerCancellable?.cancel()
        self.timerCancellable = nil

        // Perbarui Live Activity state menjadi paused
        updateLiveActivity(isPaused: true)

        // Batalkan notifikasi lama karena waktu bergeser
        NotificationManager.shared.cancelPendingNotification(identifier: notificationId)
    }

    /// Melanjutkan Timer (Resume)
    func resumeTimer() {
        guard state == .paused else { return }

        HapticManager.shared.selection()
        self.state = .running
        self.targetEndTime = Date().addingTimeInterval(TimeInterval(remainingSeconds))

        // Perbarui Live Activity state
        updateLiveActivity(isPaused: false)

        // Jadwalkan ulang notifikasi lokal
        scheduleCompletionNotification(in: TimeInterval(remainingSeconds))

        // Lanjutkan timer tick
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    self.timerDidComplete()
                }
            }
    }

    /// Mereset Timer
    func resetTimer() {
        HapticManager.shared.impact(style: .light)
        self.timerCancellable?.cancel()
        self.timerCancellable = nil
        self.state = .idle
        self.remainingSeconds = totalDuration
        self.targetEndTime = nil

        if ScreenTimeManager.shared.isShieldActive {
            ScreenTimeManager.shared.disableAppShield()
        }

        // Batalkan notifikasi
        NotificationManager.shared.cancelPendingNotification(identifier: notificationId)

        // Akhiri Live Activity
        endLiveActivity()
    }

    /// Event saat waktu timer habis
    private func timerDidComplete() {
        HapticManager.shared.impact(style: .heavy)
        self.timerCancellable?.cancel()
        self.timerCancellable = nil
        self.state = .idle
        self.remainingSeconds = 0
        self.completedSessionsCount += 1

        if ScreenTimeManager.shared.isShieldActive {
            ScreenTimeManager.shared.disableAppShield()
        }

        // Akhiri Live Activity
        endLiveActivity()

        // Otomatis ganti ke mode istirahat jika baru selesai sesi fokus
        if !selectedPreset.isBreak {
            selectPreset(.shortBreak)
        } else {
            selectPreset(.quickFocus)
        }
    }

    // MARK: - Helper Formatting
    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(totalDuration))
    }

    // MARK: - 🏝️ Live Activity & Dynamic Island Control

    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // Bersihkan aktivitas lama jika masih ada
        endLiveActivity()

        let attributes = PomodoroAttributes(
            taskName: taskTitle.isEmpty ? selectedPreset.rawValue : taskTitle,
            categoryIcon: selectedPreset.iconName
        )

        let initialContentState = PomodoroAttributes.ContentState(
            endTime: Date().addingTimeInterval(TimeInterval(remainingSeconds)),
            isPaused: false,
            isBreak: selectedPreset.isBreak,
            sessionTitle: selectedPreset.isBreak ? "Rehat Sejenak" : "Sesi Fokus",
            totalDurationSeconds: Double(totalDuration),
            remainingSecondsWhenPaused: Double(remainingSeconds)
        )

        do {
            let activity = try Activity<PomodoroAttributes>.request(
                attributes: attributes,
                content: .init(state: initialContentState, staleDate: nil),
                pushType: nil
            )
            self.liveActivity = activity
            print("🚀 Berhasil memulai Live Activity Pomodoro: \(activity.id)")
        } catch {
            print("⚠️ Gagal memulai Live Activity: \(error.localizedDescription)")
        }
    }

    private func updateLiveActivity(isPaused: Bool) {
        guard let activity = liveActivity else { return }

        let updatedContentState = PomodoroAttributes.ContentState(
            endTime: Date().addingTimeInterval(TimeInterval(remainingSeconds)),
            isPaused: isPaused,
            isBreak: selectedPreset.isBreak,
            sessionTitle: isPaused ? "Dijeda" : (selectedPreset.isBreak ? "Rehat Sejenak" : "Sesi Fokus"),
            totalDurationSeconds: Double(totalDuration),
            remainingSecondsWhenPaused: Double(remainingSeconds)
        )

        Task {
            await activity.update(ActivityContent(state: updatedContentState, staleDate: nil))
        }
    }

    private func endLiveActivity() {
        guard let activity = liveActivity else { return }

        let finalState = PomodoroAttributes.ContentState(
            endTime: Date(),
            isPaused: false,
            isBreak: selectedPreset.isBreak,
            sessionTitle: "Selesai!",
            totalDurationSeconds: Double(totalDuration),
            remainingSecondsWhenPaused: 0
        )

        let content = ActivityContent(state: finalState, staleDate: nil)
        Task {
            await activity.end(content, dismissalPolicy: .immediate)
        }
        self.liveActivity = nil
    }

    // MARK: - Local Notifications
    private let notificationId = "pomodoro_timer_completed_notification"

    private func scheduleCompletionNotification(in seconds: TimeInterval) {
        Task {
            let granted = await NotificationManager.shared.requestAuthorization()
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = self.selectedPreset.isBreak ? "Waktu Istirahat Selesai!" : "Sesi Fokus Selesai!"
            content.body = self.selectedPreset.isBreak ? "Ayo mulai sesi fokus berikutnya!" : "Kerja bagus! Istirahatlah sejenak untuk menyegarkan pikiran."
            content.sound = .default
            content.badge = 1

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
            let request = UNNotificationRequest(identifier: self.notificationId, content: content, trigger: trigger)

            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                print("Gagal membuat notifikasi lokal: \(error.localizedDescription)")
            }
        }
    }
}
