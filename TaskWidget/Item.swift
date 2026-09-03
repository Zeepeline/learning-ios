//
//  Item.swift
//  TaskWidget
//
//  Model data Item yang sinkron dengan aplikasi utama
//

import Foundation
import SwiftData

@Model
final class Item {
    var title: String
    var notes: String
    var timestamp: Date
    var isCompleted: Bool
    var priority: String
    var category: String
    
    init(
        title: String = "Aktivitas Baru",
        notes: String = "",
        timestamp: Date = Date(),
        isCompleted: Bool = false,
        priority: String = "Normal",
        category: String = "Design"
    ) {
        self.title = title
        self.notes = notes
        self.timestamp = timestamp
        self.isCompleted = isCompleted
        self.priority = priority
        self.category = category
    }
}
