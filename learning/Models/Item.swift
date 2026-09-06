//
//  Item.swift
//  learning
//
//  Created by macbook on 8/29/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var title: String = "Aktivitas Baru"
    var notes: String = ""
    var timestamp: Date = Date()
    var isCompleted: Bool = false
    var priority: String = "Normal"
    var category: String = "Design"
    
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
