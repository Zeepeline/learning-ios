//
//  Item.swift
//  TaskWidget
//
//  Model data Item yang sinkron dengan aplikasi utama
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
}

// MARK: - 📋 Subtask Item Model
public struct SubtaskItem: Codable, Identifiable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var isCompleted: Bool

    public init(id: String = UUID().uuidString, title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

// MARK: - 📦 SwiftData Model: Item
@Model
final class Item {
    var title: String = "Aktivitas Baru"
    var notes: String = ""
    var timestamp: Date = Date()
    var isCompleted: Bool = false
    var completedAt: Date? = nil
    var priority: String = "Normal"
    var category: String = "Design"
    var isRecurring: Bool = false
    var recurrenceRule: String = "Sekali Saja"
    var customSoundName: String? = nil
    var subtasks: [SubtaskItem] = []
    @Attribute(.externalStorage) var imageAttachmentData: Data? = nil
    
    init(
        title: String = "Aktivitas Baru",
        notes: String = "",
        timestamp: Date = Date(),
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        priority: String = "Normal",
        category: String = "Design",
        isRecurring: Bool = false,
        recurrenceRule: String = "Sekali Saja",
        customSoundName: String? = nil,
        subtasks: [SubtaskItem] = [],
        imageAttachmentData: Data? = nil
    ) {
        self.title = title
        self.notes = notes
        self.timestamp = timestamp
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.priority = priority
        self.category = category
        self.isRecurring = isRecurring
        self.recurrenceRule = recurrenceRule
        self.customSoundName = customSoundName
        self.subtasks = subtasks
        self.imageAttachmentData = imageAttachmentData
    }

    convenience init(
        title: String,
        notes: String = "",
        timestamp: Date = Date(),
        isCompleted: Bool = false,
        priority: TaskPriority,
        category: TaskCategory,
        recurrence: RecurrenceRule = .none,
        customSoundName: String? = nil,
        subtasks: [SubtaskItem] = [],
        imageAttachmentData: Data? = nil
    ) {
        self.init(
            title: title,
            notes: notes,
            timestamp: timestamp,
            isCompleted: isCompleted,
            priority: priority.rawValue,
            category: category.rawValue,
            isRecurring: recurrence != .none,
            recurrenceRule: recurrence.rawValue,
            customSoundName: customSoundName,
            subtasks: subtasks,
            imageAttachmentData: imageAttachmentData
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

    var completedSubtasksCount: Int {
        subtasks.filter { $0.isCompleted }.count
    }

    var totalSubtasksCount: Int {
        subtasks.count
    }

    var subtaskProgress: Double {
        guard !subtasks.isEmpty else { return 0.0 }
        return Double(completedSubtasksCount) / Double(totalSubtasksCount)
    }
}
