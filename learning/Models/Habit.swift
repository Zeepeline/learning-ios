//
//  Habit.swift
//  learning
//
//  Created by macbook on 9/6/26.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - 🔁 Strongly-Typed Habit Frequency
public enum HabitFrequency: String, Codable, CaseIterable, Identifiable, Sendable {
    case daily = "Harian"
    case weekdays = "Hari Kerja"
    case weekends = "Akhir Pekan"

    public var id: String { rawValue }
    public var title: String { rawValue }

    public var icon: String {
        switch self {
        case .daily: return "calendar"
        case .weekdays: return "briefcase.fill"
        case .weekends: return "sun.max.fill"
        }
    }
}

// MARK: - 🏷️ Strongly-Typed Habit Category
public enum HabitCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case productivity = "Produktivitas"
    case health = "Kesehatan"
    case sports = "Olahraga"
    case learning = "Belajar"
    case mindfulness = "Mindfulness"
    case finance = "Keuangan"

    public var id: String { rawValue }
    public var title: String { rawValue }

    public var defaultIcon: String {
        switch self {
        case .productivity: return "bolt.fill"
        case .health: return "heart.fill"
        case .sports: return "figure.run"
        case .learning: return "book.fill"
        case .mindfulness: return "sparkles"
        case .finance: return "creditcard.fill"
        }
    }

    public var defaultColorHex: String {
        switch self {
        case .productivity: return "#FFD166"
        case .health: return "#4ECDC4"
        case .sports: return "#FF6B6B"
        case .learning: return "#118AB2"
        case .mindfulness: return "#B388FF"
        case .finance: return "#06D6A0"
        }
    }
}

// MARK: - 📦 SwiftData Model: Habit
@Model
final class Habit {
    var title: String = "Kebiasaan Baru"
    var icon: String = "flame.fill"
    var colorHex: String = "#FFD166"
    var category: String = "Produktivitas"
    var targetFrequency: String = "Harian"
    var completedDates: [Date] = []
    var createdAt: Date = Date()
    
    init(
        title: String = "Kebiasaan Baru",
        icon: String = "flame.fill",
        colorHex: String = "#FFD166",
        category: String = "Produktivitas",
        targetFrequency: String = "Harian",
        completedDates: [Date] = [],
        createdAt: Date = Date()
    ) {
        self.title = title
        self.icon = icon
        self.colorHex = colorHex
        self.category = category
        self.targetFrequency = targetFrequency
        self.completedDates = completedDates
        self.createdAt = createdAt
    }

    convenience init(
        title: String,
        icon: String = "flame.fill",
        colorHex: String = "#FFD166",
        category: HabitCategory,
        frequency: HabitFrequency = .daily,
        completedDates: [Date] = [],
        createdAt: Date = Date()
    ) {
        self.init(
            title: title,
            icon: icon,
            colorHex: colorHex,
            category: category.rawValue,
            targetFrequency: frequency.rawValue,
            completedDates: completedDates,
            createdAt: createdAt
        )
    }

    // MARK: - Strongly-Typed Helpers
    var frequency: HabitFrequency {
        get { HabitFrequency(rawValue: targetFrequency) ?? .daily }
        set { targetFrequency = newValue.rawValue }
    }

    var habitCategory: HabitCategory {
        get { HabitCategory(rawValue: category) ?? .productivity }
        set { category = newValue.rawValue }
    }
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    // Cek apakah habit sudah diselesaikan pada tanggal tertentu (ignore time)
    func isCompleted(on date: Date) -> Bool {
        let calendar = Calendar.current
        return completedDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }
    
    // Cek apakah hari ini selesai
    var isCompletedToday: Bool {
        isCompleted(on: Date())
    }
    
    // Toggle penyelesaian untuk tanggal tertentu
    func toggleCompletion(on date: Date = Date()) {
        let calendar = Calendar.current
        var dates = completedDates
        if let index = dates.firstIndex(where: { calendar.isDate($0, inSameDayAs: date) }) {
            dates.remove(at: index)
        } else {
            dates.append(date)
        }
        self.completedDates = dates
    }
    
    // Perhitungan Current Streak (berurutan dari hari ini/kemarin)
    var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()
        
        // Jika hari ini belum dicek, periksa apakah kemarin selesai
        if !isCompleted(on: checkDate) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate),
                  isCompleted(on: yesterday) else {
                return 0
            }
            checkDate = yesterday
        }
        
        while isCompleted(on: checkDate) {
            streak += 1
            guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prevDay
        }
        
        return streak
    }
    
    // Persentase penyelesaian dalam 7 hari terakhir
    var weeklyCompletionRate: Double {
        let calendar = Calendar.current
        var completedCount = 0
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                if isCompleted(on: date) {
                    completedCount += 1
                }
            }
        }
        return Double(completedCount) / 7.0
    }
}
