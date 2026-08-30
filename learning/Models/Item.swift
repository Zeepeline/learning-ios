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
    var title: String
    var notes: String
    var timestamp: Date
    var isCompleted: Bool
    var priority: String
    
    init(
        title: String = "Aktivitas Baru",
        notes: String = "",
        timestamp: Date = Date(),
        isCompleted: Bool = false,
        priority: String = "Normal"
    ) {
        self.title = title
        self.notes = notes
        self.timestamp = timestamp
        self.isCompleted = isCompleted
        self.priority = priority
    }
}
