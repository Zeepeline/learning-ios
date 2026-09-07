//
//  PomodoroManager.swift
//  learning
//
//  Created by macbook on 9/5/26.
//

import Foundation
import SwiftUI
import Combine
import ActivityKit
import UserNotifications
import Observation

// MARK: - ⏱️ Pomodoro Presets (Durasi Standar & Cepat)
enum PomodoroPreset: String, CaseIterable, Identifiable {
    case quickFocus = "25 Menit"
    case deepFocus = "50 Menit"
    case shortBreak = "5 Menit"
    case longBreak = "15 Menit"

    var id: String { rawValue }

    var minutes: Int {
        switch self {
        case .quickFocus: return 25
        case .deepFocus: return 50
        case .shortBreak: return 5
        case .longBreak: return 15
        }
    }

    var duration: TimeInterval {
        TimeInterval(minutes * 60)
    }

    var isBreak: Bool {
        switch self {
        case .quickFocus, .deepFocus:
            return false
        case .shortBreak, .longBreak:
            return true
        }
    }

    var themeColor: Color {
        switch self {
        case .quickFocus: return Color.cartoonYellow
        case .deepFocus: return Color.cartoonCoral
        case .shortBreak: return Color.cartoonMint
        case .longBreak: return Color.cartoonLavender
        }
    }

    var iconName: String {
        switch self {
        case .quickFocus: return "bolt.fill"
        case .deepFocus: return "flame.fill"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "leaf.fill"
        }
    }
}

// MARK: - 🎯 Pomodoro State
enum PomodoroState {
    case idle
    case running
    case paused
}

// MARK: - 🍅 Pomodoro Manager Service (Live Activity & Background Timer)
@Observable
@MainActor
final class PomodoroManager {
    static let shared = PomodoroManager()

    var state: PomodoroState = .idle
    var selectedPreset: PomodoroPreset = .quickFocus
    var remainingSeconds: Int = 25 * 60
    var totalDuration: Int = 25 * 60
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

        // Mulai ambient background sound jika auto-play aktif
        if SoundManager.shared.isAutoPlayAmbientWithPomodoro && SoundManager.shared.selectedAmbient != .none {
            SoundManager.shared.playAmbient(SoundManager.shared.selectedAmbient)
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

        if SoundManager.shared.isAutoPlayAmbientWithPomodoro {
            SoundManager.shared.stopAmbient()
        }

        // Perbarui Live Activity state menjadi paused
        updateLiveActivity(isPaused: true)

        // Batalkan notifikasi lama karena waktu bergeser
        NotificationManager.shared.cancelNotification(identifier: notificationId)
    }

    /// Melanjutkan Timer (Resume)
    func resumeTimer() {
        guard state == .paused else { return }

        HapticManager.shared.selection()
        self.state = .running
        self.targetEndTime = Date().addingTimeInterval(TimeInterval(remainingSeconds))

        if SoundManager.shared.isAutoPlayAmbientWithPomodoro && SoundManager.shared.selectedAmbient != .none {
            SoundManager.shared.playAmbient(SoundManager.shared.selectedAmbient)
        }

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

        if SoundManager.shared.isAutoPlayAmbientWithPomodoro {
            SoundManager.shared.stopAmbient()
        }

        if ScreenTimeManager.shared.isShieldActive {
            ScreenTimeManager.shared.disableAppShield()
        }

        // Batalkan notifikasi
        NotificationManager.shared.cancelNotification(identifier: notificationId)

        // Akhiri Live Activity
        endLiveActivity()
    }

    /// Event saat waktu timer habis
    private func timerDidComplete() {
        HapticManager.shared.impact(style: .heavy)
        SoundManager.shared.playPomodoroFinishSound()
        
        self.timerCancellable?.cancel()
        self.timerCancellable = nil
        self.state = .idle
        self.remainingSeconds = 0
        self.completedSessionsCount += 1

        if SoundManager.shared.isAutoPlayAmbientWithPomodoro {
            SoundManager.shared.stopAmbient()
        }

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
            taskName: taskTitle.isEmpty ? "Fokus Pomodoro" : taskTitle,
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
            content.title = selectedPreset.isBreak ? "⏰ Waktu Istirahat Selesai!" : "🎉 Sesi Fokus Selesai!"
            content.body = selectedPreset.isBreak
                ? "Rehat selesai. Saatnya kembali produktif!"
                : "Kerja bagus! Waktunya rehat sejenak sebelum lanjut ke sesi berikutnya."
            content.sound = SoundManager.shared.selectedTone.notificationSound
            content.badge = 1

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
            let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)

            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                print("⚠️ Gagal menjadwalkan notifikasi pomodoro: \(error.localizedDescription)")
            }
        }
    }
}
