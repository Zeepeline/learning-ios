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
        content.sound = .default
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

    /// Menjadwalkan notifikasi lokal untuk tugas tertentu dengan async/await
    func scheduleNotification(for item: Item) async {
        guard item.timestamp > Date() else { return }

        let granted = await requestAuthorization()
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = "Waktunya Tugas: \(item.title)"
        content.body = item.notes.isEmpty ? "Jangan lupa selesaikan tugas ini tepat waktu ya!" : item.notes
        content.sound = .default
        content.badge = 1

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: item.timestamp)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let identifier = String(describing: item.persistentModelID)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Gagal menjadwalkan notifikasi: \(error.localizedDescription)")
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
        content.sound = .default
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
    func cancelPendingNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Membatalkan notifikasi untuk tugas yang dihapus / selesai
    func cancelNotification(for item: Item) {
        let identifier = String(describing: item.persistentModelID)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
