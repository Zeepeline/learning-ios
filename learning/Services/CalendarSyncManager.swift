//
//  CalendarSyncManager.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import EventKit
import SwiftUI

// MARK: - 📅 Calendar Sync Errors
enum CalendarSyncError: LocalizedError {
    case permissionDenied
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Izin akses Apple Calendar tidak diberikan."
        case .saveFailed(let message):
            return message
        }
    }
}

// MARK: - 📅 EventKit Calendar Sync Manager (Apple Calendar)
@MainActor
final class CalendarSyncManager {
    static let shared = CalendarSyncManager()
    private let eventStore = EKEventStore()

    private init() {}

    /// Meminta izin sinkronisasi ke Kalender Apple dengan async/await
    @discardableResult
    func requestAccess() async throws -> Bool {
        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = try await eventStore.requestFullAccessToEvents()
        } else {
            granted = try await eventStore.requestAccess(to: .event)
        }
        return granted
    }

    /// Menyimpan tugas sebagai jadwal baru di aplikasi Apple Calendar dengan async/await
    @discardableResult
    func addEventToCalendar(title: String, startDate: Date, notes: String) async throws -> Bool {
        let granted = (try? await requestAccess()) ?? false
        guard granted else {
            HapticManager.shared.error()
            throw CalendarSyncError.permissionDenied
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(3600) // Default durasi 1 jam
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(event, span: .thisEvent)
            HapticManager.shared.success()
            return true
        } catch {
            HapticManager.shared.error()
            throw CalendarSyncError.saveFailed(error.localizedDescription)
        }
    }
}
