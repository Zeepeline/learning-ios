//
//  NotificationManager.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import Foundation
import SwiftData
import UserNotifications

// MARK: - 🔔 Notification Errors
enum NotificationError: LocalizedError {
    case permissionDenied
    case schedulingFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Izin notifikasi tidak diberikan oleh pengguna."
        case .schedulingFailed(let message):
            return message
        }
    }
}

// MARK: - 🔔 UserNotifications Manager (Local Reminder Service)
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    /// Menangani tampilan notifikasi saat aplikasi berada di foreground (aktif di layar)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge, .list])
    }

    /// Meminta izin notifikasi kepada pengguna secara asinkron
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Gagal meminta izin notifikasi: \(error.localizedDescription)")
            return false
        }
    }

    /// Mengirim notifikasi uji coba langsung setelah jeda beberapa detik dengan async/await
    @discardableResult
    func sendTestNotification(seconds: TimeInterval = 3) async throws -> Bool {
        let granted = await requestAuthorization()
        guard granted else {
            throw NotificationError.permissionDenied
        }

        let content = UNMutableNotificationContent()
        content.title = "Waktunya Tugas: Belajar SwiftUI & Desain Kartun!"
        content.body = "Ini adalah contoh hasil notifikasi lokal. Jangan lupa selesaikan tugas tepat waktu!"
        content.sound = await MainActor.run { SoundManager.shared.selectedTone.notificationSound }
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(
            identifier: "test_notification_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            return true
        } catch {
            print("Gagal menjadwalkan notifikasi tes: \(error.localizedDescription)")
            throw NotificationError.schedulingFailed(error.localizedDescription)
        }
    }

    /// Menjadwalkan notifikasi lokal untuk tugas tertentu (termasuk jadwal rutin/scheduler)
    func scheduleNotification(for item: Item) async {
        let granted = await requestAuthorization()
        guard granted else { return }

        // Batalkan notifikasi lama terkait item ini sebelum membuat yang baru
        cancelNotification(for: item)

        let content = UNMutableNotificationContent()
        content.title = item.isRecurring ? "⏰ Jadwal Rutin: \(item.title)" : "Waktunya Tugas: \(item.title)"
        content.body = item.notes.isEmpty ? "Jangan lupa selesaikan aktivitas ini tepat waktu ya!" : item.notes
        content.sound = await MainActor.run { SoundManager.shared.selectedTone.notificationSound }
        content.badge = 1

        let calendar = Calendar.current
        let baseIdentifier = String(describing: item.persistentModelID)
        let hour = calendar.component(.hour, from: item.timestamp)
        let minute = calendar.component(.minute, from: item.timestamp)

        if item.isRecurring {
            switch item.recurrence {
            case .daily:
                var dateComponents = DateComponents()
                dateComponents.hour = hour
                dateComponents.minute = minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: baseIdentifier, content: content, trigger: trigger)
                try? await UNUserNotificationCenter.current().add(request)

            case .weekdays:
                // Senin sampai Jumat (weekday 2..6 di Calendar Gregorian)
                for weekday in 2...6 {
                    var dateComponents = DateComponents()
                    dateComponents.weekday = weekday
                    dateComponents.hour = hour
                    dateComponents.minute = minute
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                    let request = UNNotificationRequest(identifier: "\(baseIdentifier)_wd_\(weekday)", content: content, trigger: trigger)
                    try? await UNUserNotificationCenter.current().add(request)
                }

            case .weekends:
                // Minggu (1) dan Sabtu (7)
                for weekday in [1, 7] {
                    var dateComponents = DateComponents()
                    dateComponents.weekday = weekday
                    dateComponents.hour = hour
                    dateComponents.minute = minute
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                    let request = UNNotificationRequest(identifier: "\(baseIdentifier)_we_\(weekday)", content: content, trigger: trigger)
                    try? await UNUserNotificationCenter.current().add(request)
                }

            case .weekly:
                var dateComponents = DateComponents()
                dateComponents.weekday = calendar.component(.weekday, from: item.timestamp)
                dateComponents.hour = hour
                dateComponents.minute = minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: baseIdentifier, content: content, trigger: trigger)
                try? await UNUserNotificationCenter.current().add(request)

            case .none:
                break
            }
        } else {
            guard item.timestamp > Date() else { return }
            let triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: item.timestamp)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let request = UNNotificationRequest(identifier: baseIdentifier, content: content, trigger: trigger)
            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    // MARK: - 🔁 Daily Recurring Reminders (Pengingat Rutin Harian Otomatis)
    static let morningReminderId = "daily_morning_reminder"
    static let eveningReminderId = "daily_evening_reminder"

    /// Menjadwalkan pengingat rutin harian di jam dan menit tertentu secara asinkron
    func scheduleDailyReminder(hour: Int, minute: Int, title: String, body: String, identifier: String) async {
        let granted = await requestAuthorization()
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = await MainActor.run { SoundManager.shared.selectedTone.notificationSound }
        content.badge = 1

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        // repeats: true memastikan iOS menjadwalkannya setiap hari tanpa perlu membuka aplikasi
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Berhasil menjadwalkan daily reminder (\(identifier)) pada \(String(format: "%02d:%02d", hour, minute))")
        } catch {
            print("Gagal menjadwalkan daily reminder (\(identifier)): \(error.localizedDescription)")
        }
    }

    /// Membatalkan pengingat rutin harian berdasarkan identifier
    func cancelReminder(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Pengingat (\(identifier)) berhasil dibatalkan")
    }

    /// Membatalkan pending notifikasi berdasarkan identifier string
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Membatalkan pending notifikasi untuk tugas Item tertentu (termasuk sub-jadwal mingguan/harian)
    func cancelNotification(for item: Item) {
        let baseIdentifier = String(describing: item.persistentModelID)
        var idsToRemove = [baseIdentifier]
        for i in 1...7 {
            idsToRemove.append("\(baseIdentifier)_wd_\(i)")
            idsToRemove.append("\(baseIdentifier)_we_\(i)")
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToRemove)
    }
}
