//
//  Habit.swift
//  learning
//
//  Created by macbook on 9/6/26.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Habit {
    var title: String
    var icon: String
    var colorHex: String
    var category: String
    var targetFrequency: String // "Harian", "Hari Kerja", "Akhir Pekan"
    var completedDates: [Date]
    var createdAt: Date
    
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
        if let index = completedDates.firstIndex(where: { calendar.isDate($0, inSameDayAs: date) }) {
            completedDates.remove(at: index)
        } else {
            completedDates.append(date)
        }
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
