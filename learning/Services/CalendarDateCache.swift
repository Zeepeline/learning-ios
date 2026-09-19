//
//  CalendarDateCache.swift
//  learning
//
//  Created by macbook on 9/18/26.
//

import Foundation

// MARK: - ⚡ High-Performance Zero-Allocation Calendar & Date Formatter Cache
final class CalendarDateCache: @unchecked Sendable {
    static let shared = CalendarDateCache()

    private let calendar = Calendar.current
    private let timeFormatter: DateFormatter
    private let dayFormatter: DateFormatter
    private let weekdayFormatter: DateFormatter

    private init() {
        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"
        self.timeFormatter = tf

        let df = DateFormatter()
        df.dateFormat = "d"
        self.dayFormatter = df

        let wf = DateFormatter()
        wf.dateFormat = "EEE"
        self.weekdayFormatter = wf
    }

    /// Format waktu 24 jam cepat (misal: "09:30")
    func formatTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    /// Format tanggal cepat (misal: "18")
    func formatDay(_ date: Date) -> String {
        dayFormatter.string(from: date)
    }

    /// Format hari cepat (misal: "JUM" / "FRI")
    func formatWeekday(_ date: Date) -> String {
        weekdayFormatter.string(from: date).uppercased()
    }
}
