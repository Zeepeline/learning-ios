//
//  Habit.swift
//  TaskWidget
//
//  Model data Habit yang sinkron dengan aplikasi utama
//

import Foundation
import SwiftData

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
}
