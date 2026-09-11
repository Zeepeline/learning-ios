//
//  Item.swift
//  learning
//
//  Created by macbook on 8/29/26.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - 🎯 Strongly-Typed Task Priority
public enum TaskPriority: String, Codable, CaseIterable, Identifiable, Sendable {
    case low = "Rendah"
    case normal = "Normal"
    case high = "Tinggi"

    public var id: String { rawValue }

    public var title: String { rawValue }

    public var icon: String {
        switch self {
        case .low: return "arrow.down.circle.fill"
        case .normal: return "minus.circle.fill"
        case .high: return "exclamationmark.circle.fill"
        }
    }

    public var color: Color {
        switch self {
        case .low: return .cartoonMint
        case .normal: return .cartoonYellow
        case .high: return .cartoonCoral
        }
    }
}

// MARK: - 🏷️ Strongly-Typed Task Category
public enum TaskCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case learning = "Belajar"
    case health = "Kesehatan"
    case work = "Pekerjaan"
    case personal = "Pribadi"
    case finance = "Keuangan"
    case spiritual = "Ibadah"
    case home = "Rumah"
    case social = "Sosial"
    case shopping = "Belanja"
    case design = "Design"
    case coding = "Coding"
    case meeting = "Meeting"
    case subtask = "Subtask"
    case general = "Umum"

    public var id: String { rawValue }

    public var title: String { rawValue }

    public var icon: String {
        switch self {
        case .learning: return "book.fill"
        case .health: return "heart.fill"
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .finance: return "creditcard.fill"
        case .spiritual: return "sparkles"
        case .home: return "house.fill"
        case .social: return "person.2.fill"
        case .shopping: return "cart.fill"
        case .design: return "paintbrush.fill"
        case .coding: return "curlybraces"
        case .meeting: return "bubble.left.and.bubble.right.fill"
        case .subtask: return "list.bullet.indent"
        case .general: return "tray.fill"
        }
    }

    public var color: Color {
        switch self {
        case .learning: return .cartoonYellow
        case .health: return .cartoonPink
        case .work: return .cartoonLavender
        case .personal: return .cartoonMint
        case .finance: return .cartoonBlue
        case .spiritual: return .cartoonOrange
        case .home: return .cartoonYellow
        case .social: return .cartoonPink
        case .shopping: return .cartoonMint
        case .design: return .cartoonLavender
        case .coding: return .cartoonBlue
        case .meeting: return .cartoonOrange
        case .subtask: return .cartoonBlue
        case .general: return .cartoonMint
        }
    }
}

// MARK: - 🔁 Strongly-Typed Recurrence Rule (Scheduler)
public enum RecurrenceRule: String, Codable, CaseIterable, Identifiable, Sendable {
    case none = "Sekali Saja"
    case daily = "Setiap Hari"
    case weekdays = "Hari Kerja (Sen-Jum)"
    case weekends = "Akhir Pekan (Sab-Min)"
    case weekly = "Setiap Minggu"

    public var id: String { rawValue }
    public var title: String { rawValue }

    public var shortTitle: String {
        switch self {
        case .none: return "Sekali"
        case .daily: return "Harian"
        case .weekdays: return "Hari Kerja"
        case .weekends: return "Akhir Pekan"
        case .weekly: return "Mingguan"
        }
    }

    public var icon: String {
        switch self {
        case .none: return "calendar"
        case .daily: return "repeat"
        case .weekdays: return "briefcase.fill"
        case .weekends: return "sun.and.horizon.fill"
        case .weekly: return "calendar.badge.clock"
        }
    }

    public var badgeColor: Color {
        switch self {
        case .none: return .gray.opacity(0.15)
        case .daily: return .cartoonLavender
        case .weekdays: return .cartoonBlue
        case .weekends: return .cartoonYellow
        case .weekly: return .cartoonMint
        }
    }
}

// MARK: - 📦 SwiftData Model: Item
@Model
final class Item {
    var title: String = "Aktivitas Baru"
    var notes: String = ""
    var timestamp: Date = Date()
    var isCompleted: Bool = false
    var priority: String = "Normal"
    var category: String = "Design"
    var isRecurring: Bool = false
    var recurrenceRule: String = "Sekali Saja"
    
    init(
        title: String = "Aktivitas Baru",
        notes: String = "",
        timestamp: Date = Date(),
        isCompleted: Bool = false,
        priority: String = "Normal",
        category: String = "Design",
        isRecurring: Bool = false,
        recurrenceRule: String = "Sekali Saja"
    ) {
        self.title = title
        self.notes = notes
        self.timestamp = timestamp
        self.isCompleted = isCompleted
        self.priority = priority
        self.category = category
        self.isRecurring = isRecurring
        self.recurrenceRule = recurrenceRule
    }

    convenience init(
        title: String,
        notes: String = "",
        timestamp: Date = Date(),
        isCompleted: Bool = false,
        priority: TaskPriority,
        category: TaskCategory,
        recurrence: RecurrenceRule = .none
    ) {
        self.init(
            title: title,
            notes: notes,
            timestamp: timestamp,
            isCompleted: isCompleted,
            priority: priority.rawValue,
            category: category.rawValue,
            isRecurring: recurrence != .none,
            recurrenceRule: recurrence.rawValue
        )
    }

    // MARK: - Strongly-Typed Helpers
    var taskPriority: TaskPriority {
        get { TaskPriority(rawValue: priority) ?? .normal }
        set { priority = newValue.rawValue }
    }

    var taskCategory: TaskCategory {
        get { TaskCategory(rawValue: category) ?? .general }
        set { category = newValue.rawValue }
    }

    var recurrence: RecurrenceRule {
        get {
            guard isRecurring else { return .none }
            return RecurrenceRule(rawValue: recurrenceRule) ?? .none
        }
        set {
            recurrenceRule = newValue.rawValue
            isRecurring = (newValue != .none)
        }
    }
}
