//
//  NotificationManager.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import Foundation
import SwiftData
import UserNotifications

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

    /// Meminta izin notifikasi kepada pengguna
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }

    /// Mengirim notifikasi uji coba langsung setelah jeda beberapa detik
    func sendTestNotification(seconds: TimeInterval = 3, completion: ((Bool) -> Void)? = nil) {
        requestAuthorization { granted in
            guard granted else {
                completion?(false)
                return
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

            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Gagal menjadwalkan notifikasi tes: \(error.localizedDescription)")
                        completion?(false)
                    } else {
                        completion?(true)
                    }
                }
            }
        }
    }

    /// Menjadwalkan notifikasi lokal untuk tugas tertentu
    func scheduleNotification(for item: Item) {
        guard item.timestamp > Date() else { return }

        // Minta izin jika belum
        requestAuthorization { granted in
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

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Gagal menjadwalkan notifikasi: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - 🔁 Daily Recurring Reminders (Pengingat Rutin Harian Otomatis)
    static let morningReminderId = "daily_morning_reminder"
    static let eveningReminderId = "daily_evening_reminder"

    /// Menjadwalkan pengingat rutin harian di jam dan menit tertentu (berjalan otomatis di background oleh iOS)
    func scheduleDailyReminder(hour: Int, minute: Int, title: String, body: String, identifier: String) {
        requestAuthorization { granted in
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

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Gagal menjadwalkan daily reminder (\(identifier)): \(error.localizedDescription)")
                } else {
                    print("Berhasil menjadwalkan daily reminder (\(identifier)) pada \(String(format: "%02d:%02d", hour, minute))")
                }
            }
        }
    }

    /// Membatalkan pengingat rutin harian berdasarkan identifier
    func cancelReminder(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Pengingat (\(identifier)) berhasil dibatalkan")
    }

    /// Membatalkan notifikasi untuk tugas yang dihapus / selesai
    func cancelNotification(for item: Item) {
        let identifier = String(describing: item.persistentModelID)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
