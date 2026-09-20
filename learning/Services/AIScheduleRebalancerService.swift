//
//  AIScheduleRebalancerService.swift
//  learning
//
//  Created by macbook on 9/20/26.
//

import Foundation
import SwiftData
import WidgetKit

// MARK: - 🤖 Rebalance Reason Type
enum RebalanceReasonType: Sendable {
    case overdue
    case conflict
    case prioritySpacing

    var badgeTitle: String {
        switch self {
        case .overdue: return "Terlewat"
        case .conflict: return "Bentrok"
        case .prioritySpacing: return "Prioritas Optimal"
        }
    }

    var icon: String {
        switch self {
        case .overdue: return "clock.badge.exclamationmark"
        case .conflict: return "bolt.horizontal.fill"
        case .prioritySpacing: return "sparkles"
        }
    }
}

// MARK: - 📋 Rebalance Proposal Item
struct RebalanceProposalItem: Identifiable {
    var id: PersistentIdentifier { item.persistentModelID }
    let item: Item
    let originalDate: Date
    var proposedDate: Date
    let reason: String
    let reasonType: RebalanceReasonType
    var isIncluded: Bool = true
}

// MARK: - 🧠 AI Schedule Rebalancer Engine
@MainActor
final class AIScheduleRebalancerService {
    static let shared = AIScheduleRebalancerService()

    private init() {}

    /// Periksa apakah ada tugas terlewat atau jadwal bentrok hari ini
    func hasActionableItems(in items: [Item], referenceDate: Date = Date()) -> Bool {
        let proposals = analyzeAndGenerateProposals(for: items, referenceDate: referenceDate)
        return !proposals.isEmpty
    }

    /// Analisis tugas aktif hari ini dan susun jadwal cerdas baru
    func analyzeAndGenerateProposals(
        for items: [Item],
        referenceDate: Date = Date()
    ) -> [RebalanceProposalItem] {
        let calendar = Calendar.current
        let uncompletedItems = items.filter { !$0.isCompleted }

        // 1. Ambil tugas hari ini atau tugas masa lalu yang belum selesai (Overdue)
        let relevantItems = uncompletedItems.filter { item in
            let isPast = item.timestamp < referenceDate
            let isToday = calendar.isDate(item.timestamp, inSameDayAs: referenceDate)
            return isPast || isToday
        }

        guard !relevantItems.isEmpty else { return [] }

        // 2. Deteksi tabrakan waktu & tugas terlewat
        var overdueItems: [Item] = []
        var conflictingItems: [Item] = []
        var scheduledTodayItems: [Item] = []

        for item in relevantItems {
            let isOverdue = item.timestamp < referenceDate.addingTimeInterval(-10 * 60) // Lebih dari 10 menit terlewat
            if isOverdue {
                overdueItems.append(item)
            } else {
                let conflicts = ScheduleConflictDetector.shared.detectConflicts(
                    for: item.timestamp,
                    toleranceMinutes: 20,
                    in: uncompletedItems,
                    excludingItemId: item.persistentModelID
                )
                if !conflicts.isEmpty {
                    conflictingItems.append(item)
                } else {
                    scheduledTodayItems.append(item)
                }
            }
        }

        // Jika tidak ada tugas terlewat dan tidak ada bentrok, tidak perlu rebalancing
        guard !overdueItems.isEmpty || !conflictingItems.isEmpty else {
            return []
        }

        // 3. Hitung slot waktu mulai berikutnya (dibulatkan ke kelipatan 15 menit berikutnya)
        var nextSlot = roundToNextQuarterHour(referenceDate)

        // Urutkan tugas yang perlu ditata ulang: Prioritas Tinggi duluan, lalu Sedang/Normal, lalu Rendah
        let itemsToReschedule = (overdueItems + conflictingItems).sorted {
            priorityWeight($0.priority) > priorityWeight($1.priority)
        }

        var proposals: [RebalanceProposalItem] = []
        var occupiedSlots: [Date] = scheduledTodayItems.map { $0.timestamp }

        for item in itemsToReschedule {
            // Cari slot waktu luang berikutnya yang tidak tabrakan dengan scheduledTodayItems ataupun slot yang sudah terisi
            var candidateSlot = nextSlot
            while isSlotOccupied(candidateSlot, occupiedSlots: occupiedSlots, bufferMinutes: 30) {
                candidateSlot = candidateSlot.addingTimeInterval(30 * 60)
            }

            let isOverdue = item.timestamp < referenceDate
            let reasonType: RebalanceReasonType = isOverdue ? .overdue : .conflict
            let originalTimeStr = item.timestamp.formatted(date: .omitted, time: .shortened)
            let proposedTimeStr = candidateSlot.formatted(date: .omitted, time: .shortened)

            let reasonDesc = isOverdue
                ? "Tugas terlewat (\(originalTimeStr)) → Digeser ke slot luang \(proposedTimeStr)"
                : "Menghindari tabrakan waktu → Dialihkan ke \(proposedTimeStr)"

            proposals.append(RebalanceProposalItem(
                item: item,
                originalDate: item.timestamp,
                proposedDate: candidateSlot,
                reason: reasonDesc,
                reasonType: reasonType,
                isIncluded: true
            ))

            occupiedSlots.append(candidateSlot)
            nextSlot = candidateSlot.addingTimeInterval(35 * 60) // Beri jeda 35 menit per tugas
        }

        return proposals
    }

    /// Terapkan jadwal baru ke SwiftData dan perbarui notifikasi lokal
    func applyRebalance(
        proposals: [RebalanceProposalItem],
        in modelContext: ModelContext
    ) async {
        let activeProposals = proposals.filter { $0.isIncluded }
        guard !activeProposals.isEmpty else { return }

        for proposal in activeProposals {
            proposal.item.timestamp = proposal.proposedDate
            // Jadwalkan ulang notifikasi lokal
            await NotificationManager.shared.scheduleNotification(for: proposal.item)
        }

        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
            HapticManager.shared.success()
            SoundManager.shared.playSuccessChime()
        } catch {
            print("[AIScheduleRebalancer] Gagal menyimpan rebalance: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers
    private func roundToNextQuarterHour(_ date: Date) -> Date {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: date)
        let remainder = minute % 15
        let addMinutes = (remainder == 0 ? 15 : (15 - remainder))
        return calendar.date(byAdding: .minute, value: addMinutes, to: date) ?? date
    }

    private func isSlotOccupied(_ slot: Date, occupiedSlots: [Date], bufferMinutes: Int) -> Bool {
        for occupied in occupiedSlots {
            let diff = abs(slot.timeIntervalSince(occupied))
            if diff < Double(bufferMinutes * 60) {
                return true
            }
        }
        return false
    }

    private func priorityWeight(_ priority: String) -> Int {
        switch priority.lowercased() {
        case "tinggi", "high", "darurat": return 3
        case "normal", "sedang", "medium": return 2
        default: return 1
        }
    }
}
