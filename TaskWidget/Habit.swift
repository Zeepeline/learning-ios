//
//  Habit.swift
//  TaskWidget
//
//  Model data Habit yang sinkron dengan aplikasi utama
//

import Foundation
import SwiftData

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
}
