//
//  CalendarSyncManager.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import EventKit

// MARK: - 📅 EventKit Calendar Sync Manager (Apple Calendar)
final class CalendarSyncManager {
    static let shared = CalendarSyncManager()
    private let eventStore = EKEventStore()

    private init() {}

    /// Meminta izin sinkronisasi ke Kalender Apple
    func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, _ in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, _ in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
    }

    /// Menyimpan tugas sebagai jadwal baru di aplikasi Apple Calendar
    func addEventToCalendar(title: String, startDate: Date, notes: String, completion: @escaping (Bool, String?) -> Void) {
        requestAccess { granted in
            guard granted else {
                completion(false, "Izin akses kalender tidak diberikan.")
                return
            }

            let event = EKEvent(eventStore: self.eventStore)
            event.title = title
            event.startDate = startDate
            event.endDate = startDate.addingTimeInterval(3600) // Default durasi 1 jam
            event.notes = notes
            event.calendar = self.eventStore.defaultCalendarForNewEvents

            do {
                try self.eventStore.save(event, span: .thisEvent)
                HapticManager.shared.success()
                completion(true, nil)
            } catch {
                HapticManager.shared.error()
                completion(false, error.localizedDescription)
            }
        }
    }
}
