//
//  ScheduleConflictDetector.swift
//  learning
//
//  Created by macbook on 9/20/26.
//

import Foundation
import SwiftData

// MARK: - ⚠️ Schedule Conflict Model
struct ScheduleConflict: Identifiable, Sendable {
    var id: String { existingTaskTitle + "\(timeDifferenceMinutes)" }
    let existingTaskTitle: String
    let existingTaskTime: Date
    let timeDifferenceMinutes: Int
    let conflictLevel: ConflictLevel

    enum ConflictLevel: Sendable {
        case exactSameTime    // Tabrakan pas di jam & menit yang sama
        case overlappingRange // Tabrakan dalam rentang 30 menit
        case adjacentSoon     // Dekat dalam rentang 30-60 menit
    }

    var localizedWarningMessage: String {
        let timeStr = existingTaskTime.formatted(date: .omitted, time: .shortened)
        switch conflictLevel {
        case .exactSameTime:
            return "Tabrakan jadwal: Sudah ada tugas '\(existingTaskTitle)' tepat pukul \(timeStr)."
        case .overlappingRange:
            return "Waktu sangat berdekatan dengan tugas '\(existingTaskTitle)' (pukul \(timeStr))."
        case .adjacentSoon:
            return "Tugas '\(existingTaskTitle)' dimulai dalam waktu singkat (pukul \(timeStr))."
        }
    }
}

// MARK: - 🛡️ Smart Schedule Conflict Engine
final class ScheduleConflictDetector {
    static let shared = ScheduleConflictDetector()

    private init() {}

    /// Deteksi konflik waktu dengan daftar item tugas yang belum selesai
    func detectConflicts(
        for targetDate: Date,
        toleranceMinutes: Int = 30,
        in items: [Item],
        excludingItemId: PersistentIdentifier? = nil
    ) -> [ScheduleConflict] {
        let calendar = Calendar.current
        var conflicts: [ScheduleConflict] = []

        // Hanya periksa tugas yang belum selesai
        let activeItems = items.filter { item in
            guard !item.isCompleted else { return false }
            if let excluded = excludingItemId, item.persistentModelID == excluded || item.id == excluded {
                return false
            }
            return true
        }

        for item in activeItems {
            // Periksa apakah di hari yang sama
            guard calendar.isDate(item.timestamp, inSameDayAs: targetDate) else {
                continue
            }

            let diffSeconds = abs(item.timestamp.timeIntervalSince(targetDate))
            let diffMinutes = Int(diffSeconds / 60)

            if diffMinutes == 0 {
                conflicts.append(ScheduleConflict(
                    existingTaskTitle: item.title,
                    existingTaskTime: item.timestamp,
                    timeDifferenceMinutes: 0,
                    conflictLevel: .exactSameTime
                ))
            } else if diffMinutes <= toleranceMinutes {
                conflicts.append(ScheduleConflict(
                    existingTaskTitle: item.title,
                    existingTaskTime: item.timestamp,
                    timeDifferenceMinutes: diffMinutes,
                    conflictLevel: .overlappingRange
                ))
            }
        }

        return conflicts.sorted { $0.timeDifferenceMinutes < $1.timeDifferenceMinutes }
    }

    /// Menyarankan waktu kosong berikutnya tanpa tabrakan
    func suggestNextAvailableSlot(
        startingFrom baseDate: Date,
        in items: [Item],
        durationMinutes: Int = 30,
        excludingItemId: PersistentIdentifier? = nil
    ) -> Date {
        var candidate = baseDate.addingTimeInterval(TimeInterval(durationMinutes * 60))
        let calendar = Calendar.current

        // Coba cari slot kosong hingga 10 iterasi
        for _ in 0..<10 {
            let conflicts = detectConflicts(for: candidate, toleranceMinutes: durationMinutes - 5, in: items, excludingItemId: excludingItemId)
            if conflicts.isEmpty {
                return candidate
            }
            candidate = candidate.addingTimeInterval(TimeInterval(durationMinutes * 60))
        }

        // Fallback jika padat
        return calendar.date(byAdding: .hour, value: 1, to: baseDate) ?? baseDate
    }
}
