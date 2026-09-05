//
//  ScreenTimeManager.swift
//  learning
//
//  Created by macbook on 9/5/26.
//

import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI
import Combine

// MARK: - Activity & Event Names
extension DeviceActivityName {
    static let dailyLimitActivity = Self("dailyLimitActivity")
}

extension DeviceActivityEvent.Name {
    static let dailyLimitThresholdEvent = Self("dailyLimitThresholdEvent")
}

@MainActor
final class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()

    // 1. Menyimpan aplikasi & kategori yang dipilih user
    @Published var activitySelection = FamilyActivitySelection() {
        didSet {
            saveSelectionToSharedDefaults()
            if isDailyLimitEnabled {
                startDailyLimitMonitoring()
            }
        }
    }

    @Published var isAuthorized: Bool = false
    @Published var isShieldActive: Bool = false

    // Fitur Batas Durasi Harian Otomatis (Threshold Lock)
    @Published var isDailyLimitEnabled: Bool = false
    @Published var dailyLimitMinutes: Int = 60

    // Store ManagedSettings untuk mengunci aplikasi
    private let store = ManagedSettingsStore()
    private let deviceActivityCenter = DeviceActivityCenter()
    private let sharedDefaults = UserDefaults(suiteName: "group.com.gmedia.xlearning")

    private init() {
        checkAuthorizationStatus()
        loadSavedSettings()
    }

    // 2. Cek status izin saat ini
    func checkAuthorizationStatus() {
        isAuthorized = (AuthorizationCenter.shared.authorizationStatus == .approved)
    }

    // 3. Meminta Izin Screen Time ke Pengguna
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            self.isAuthorized = (AuthorizationCenter.shared.authorizationStatus == .approved)
            print("[ScreenTime] Izin Screen Time Disetujui!")
            if isAuthorized && isDailyLimitEnabled {
                startDailyLimitMonitoring()
            }
        } catch {
            print("[ScreenTime] Gagal meminta izin Screen Time: \(error.localizedDescription)")
            self.isAuthorized = false
        }
    }

    // 4. Fitur Mode Fokus Instan: Mengunci (Shield) Aplikasi yang Dipilih
    func enableAppShield() {
        guard !activitySelection.applicationTokens.isEmpty || !activitySelection.categoryTokens.isEmpty else {
            print("Belum ada aplikasi yang dipilih")
            return
        }

        store.shield.applications = activitySelection.applicationTokens
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(activitySelection.categoryTokens)
        self.isShieldActive = true
        print("[ScreenTime] Aplikasi berhasil dikunci untuk Mode Fokus.")
    }

    // 5. Matikan Kunci (Buka kembali semua aplikasi)
    func disableAppShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        self.isShieldActive = false
        print("[ScreenTime] Semua aplikasi kembali dibuka.")
    }

    // MARK: - ⏱️ Batas Durasi Otomatis (Threshold Monitoring)
    func toggleDailyLimit(_ enabled: Bool) {
        isDailyLimitEnabled = enabled
        sharedDefaults?.set(enabled, forKey: "isDailyLimitEnabled")

        if enabled {
            startDailyLimitMonitoring()
        } else {
            stopDailyLimitMonitoring()
        }
    }

    func updateDailyLimitMinutes(_ minutes: Int) {
        dailyLimitMinutes = minutes
        sharedDefaults?.set(minutes, forKey: "dailyLimitMinutes")

        if isDailyLimitEnabled {
            startDailyLimitMonitoring()
        }
    }

    func startDailyLimitMonitoring() {
        guard isAuthorized else { return }
        guard !activitySelection.applicationTokens.isEmpty || !activitySelection.categoryTokens.isEmpty else { return }

        // Jadwal harian dari 00:00 hingga 23:59:59
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )

        // Ambang batas pemakaian aktif aplikasi
        let threshold = DateComponents(minute: max(1, dailyLimitMinutes))
        let event = DeviceActivityEvent(
            applications: activitySelection.applicationTokens,
            categories: activitySelection.categoryTokens,
            threshold: threshold
        )

        do {
            try deviceActivityCenter.startMonitoring(
                .dailyLimitActivity,
                during: schedule,
                events: [.dailyLimitThresholdEvent: event]
            )
            print("[ScreenTime] Berhasil mendaftarkan pemantauan batas otomatis: \(dailyLimitMinutes) menit")
        } catch {
            print("[ScreenTime] Gagal memulai pemantauan: \(error.localizedDescription)")
        }
    }

    func stopDailyLimitMonitoring() {
        deviceActivityCenter.stopMonitoring([.dailyLimitActivity])
        print("[ScreenTime] Pemantauan batas otomatis dihentikan.")
    }

    // MARK: - Persistence
    private func saveSelectionToSharedDefaults() {
        if let encoded = try? JSONEncoder().encode(activitySelection) {
            sharedDefaults?.set(encoded, forKey: "ScreenTimeActivitySelection")
        }
    }

    private func loadSavedSettings() {
        if let data = sharedDefaults?.data(forKey: "ScreenTimeActivitySelection"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            self.activitySelection = selection
        }

        if let savedEnabled = sharedDefaults?.object(forKey: "isDailyLimitEnabled") as? Bool {
            self.isDailyLimitEnabled = savedEnabled
        }

        if let savedMinutes = sharedDefaults?.object(forKey: "dailyLimitMinutes") as? Int, savedMinutes > 0 {
            self.dailyLimitMinutes = savedMinutes
        }
    }
}
