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

// MARK: - ⏱️ Pomodoro Preset Modes
enum PomodoroPreset: String, CaseIterable, Identifiable, Sendable {
    case focus25 = "25 Min (Klasik)"
    case deepWork50 = "50 Min (Deep Work)"
    case shortBreak5 = "5 Min (Istirahat)"
    case longBreak15 = "15 Min (Rehat)"

    var id: String { rawValue }

    var duration: TimeInterval {
        switch self {
        case .focus25: return 25 * 60
        case .deepWork50: return 50 * 60
        case .shortBreak5: return 5 * 60
        case .longBreak15: return 15 * 60
        }
    }

    var isBreak: Bool {
        switch self {
        case .focus25, .deepWork50: return false
        case .shortBreak5, .longBreak15: return true
        }
    }

    var iconName: String {
        switch self {
        case .focus25: return "timer"
        case .deepWork50: return "bolt.fill"
        case .shortBreak5: return "cup.and.saucer.fill"
        case .longBreak15: return "sun.max.fill"
        }
    }

    var themeColor: Color {
        switch self {
        case .focus25: return Color.cartoonCoral
        case .deepWork50: return Color.cartoonOrange
        case .shortBreak5: return Color.cartoonMint
        case .longBreak15: return Color.cartoonBlue
        }
    }
}

enum PomodoroState: Sendable {
    case idle
    case running
    case paused
}

// MARK: - Pomodoro Focus Timer & Live Activity Manager
@MainActor
final class PomodoroManager: ObservableObject {
    static let shared = PomodoroManager()

    // Published State
    @Published var selectedPreset: PomodoroPreset = .focus25
    @Published var state: PomodoroState = .idle
    @Published var timeRemaining: TimeInterval = 25 * 60
    @Published var totalDuration: TimeInterval = 25 * 60
    @Published var taskTitle: String = ""
    @Published var isAutoShieldEnabled: Bool = true
    @Published var completedSessionsCount: Int = 0

    // Internal Properties
    private var timerSubscription: AnyCancellable?
    private var targetEndTime: Date?
    private var liveActivity: Activity<PomodoroAttributes>?

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (timeRemaining / totalDuration)
    }

    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private init() {
        self.timeRemaining = selectedPreset.duration
        self.totalDuration = selectedPreset.duration
    }

    // MARK: - Timer Controls
    func selectPreset(_ preset: PomodoroPreset) {
        guard state == .idle else { return }
        selectedPreset = preset
        totalDuration = preset.duration
        timeRemaining = preset.duration
        HapticManager.shared.impact(style: .light)
    }

    func startTimer() {
        guard state != .running else { return }

        let target = Date().addingTimeInterval(timeRemaining)
        self.targetEndTime = target
        self.state = .running

        // Haptic feedback
        HapticManager.shared.success()

        // Otomatis aktifkan App Shielding jika diaktifkan dan bukan sesi break
        if isAutoShieldEnabled && !selectedPreset.isBreak {
            ScreenTimeManager.shared.enableAppShield()
        }

        // Jalankan Timer Loop
        startInternalTimer()

        // Mulai atau perbarui Live Activity
        if liveActivity == nil {
            startLiveActivity(endTime: target)
        } else {
            updateLiveActivity(isPaused: false, endTime: target)
        }

        // Jadwalkan Notifikasi Selesai
        scheduleCompletionNotification(in: timeRemaining)
    }

    func pauseTimer() {
        guard state == .running else { return }

        timerSubscription?.cancel()
        timerSubscription = nil
        state = .paused

        HapticManager.shared.impact(style: .medium)

        // Buka shield saat jeda
        if isAutoShieldEnabled {
            ScreenTimeManager.shared.disableAppShield()
        }

        // Perbarui Live Activity status Dijeda
        updateLiveActivity(isPaused: true)

        // Batalkan Notifikasi terjadwal
        cancelCompletionNotification()
    }

    func resumeTimer() {
        guard state == .paused else { return }
        startTimer()
    }

    func resetTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil

        state = .idle
        timeRemaining = selectedPreset.duration
        totalDuration = selectedPreset.duration
        targetEndTime = nil

        HapticManager.shared.impact(style: .heavy)

        // Matikan Shield
        if isAutoShieldEnabled {
            ScreenTimeManager.shared.disableAppShield()
        }

        // Batalkan Notifikasi
        cancelCompletionNotification()

        // Akhiri Live Activity
        endLiveActivity()
    }

    func skipToNextPreset() {
        resetTimer()
        if selectedPreset.isBreak {
            selectedPreset = .focus25
        } else {
            completedSessionsCount += 1
            selectedPreset = (completedSessionsCount % 4 == 0) ? .longBreak15 : .shortBreak5
        }
        totalDuration = selectedPreset.duration
        timeRemaining = selectedPreset.duration
    }

    // MARK: - Internal Timer Loop
    private func startInternalTimer() {
        timerSubscription?.cancel()
        timerSubscription = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let target = self.targetEndTime else { return }

                let remaining = target.timeIntervalSinceNow
                if remaining <= 0 {
                    self.timeRemaining = 0
                    self.timerCompleted()
                } else {
                    self.timeRemaining = remaining
                }
            }
    }

    private func timerCompleted() {
        timerSubscription?.cancel()
        timerSubscription = nil
        state = .idle

        HapticManager.shared.success()

        if !selectedPreset.isBreak {
            completedSessionsCount += 1
        }

        // Matikan Shield
        if isAutoShieldEnabled {
            ScreenTimeManager.shared.disableAppShield()
        }

        // Akhiri Live Activity
        endLiveActivity()
    }

    // MARK: - Live Activity & Dynamic Island (ActivityKit)
    private func startLiveActivity(endTime: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities tidak diizinkan oleh sistem.")
            return
        }

        let attributes = PomodoroAttributes(
            taskName: taskTitle.isEmpty ? "Sesi Fokus" : taskTitle,
            categoryIcon: selectedPreset.iconName
        )

        let initialContentState = PomodoroAttributes.ContentState(
            endTime: endTime,
            isPaused: false,
            isBreak: selectedPreset.isBreak,
            sessionTitle: selectedPreset.rawValue,
            totalDurationSeconds: totalDuration,
            remainingSecondsWhenPaused: timeRemaining
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialContentState, staleDate: endTime.addingTimeInterval(60))
            )
            self.liveActivity = activity
            print("Live Activity Pomodoro berhasil dimulai: \(activity.id)")
        } catch {
            print("Gagal memulai Live Activity: \(error.localizedDescription)")
        }
    }

    private func updateLiveActivity(isPaused: Bool, endTime: Date? = nil) {
        guard let activity = liveActivity else { return }

        let currentEndTime = endTime ?? (targetEndTime ?? Date().addingTimeInterval(timeRemaining))
        let updatedState = PomodoroAttributes.ContentState(
            endTime: currentEndTime,
            isPaused: isPaused,
            isBreak: selectedPreset.isBreak,
            sessionTitle: selectedPreset.rawValue,
            totalDurationSeconds: totalDuration,
            remainingSecondsWhenPaused: timeRemaining
        )

        let content = ActivityContent(state: updatedState, staleDate: currentEndTime.addingTimeInterval(60))
        Task { @MainActor in
            await activity.update(content)
        }
    }

    private func endLiveActivity() {
        guard let activity = liveActivity else { return }
        let finalState = PomodoroAttributes.ContentState(
            endTime: Date(),
            isPaused: false,
            isBreak: selectedPreset.isBreak,
            sessionTitle: "Selesai!",
            totalDurationSeconds: totalDuration,
            remainingSecondsWhenPaused: 0
        )

        let content = ActivityContent(state: finalState, staleDate: nil)
        Task { @MainActor in
            await activity.end(content, dismissalPolicy: .immediate)
        }
        self.liveActivity = nil
    }

    // MARK: - Local Notifications
    private let notificationId = "pomodoro_timer_completed_notification"

    private func scheduleCompletionNotification(in seconds: TimeInterval) {
        NotificationManager.shared.requestAuthorization { granted in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = self.selectedPreset.isBreak ? "Waktu Istirahat Selesai!" : "Sesi Fokus Selesai!"
            content.body = self.selectedPreset.isBreak ? "Ayo mulai sesi fokus berikutnya!" : "Kerja bagus! Istirahatlah sejenak untuk menyegarkan pikiran."
            content.sound = .default
            content.badge = 1

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
            let request = UNNotificationRequest(identifier: self.notificationId, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Gagal menjadwalkan notifikasi Pomodoro: \(error.localizedDescription)")
                }
            }
        }
    }

    private func cancelCompletionNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
    }
}
