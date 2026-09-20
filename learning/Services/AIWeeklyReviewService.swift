//
//  AIWeeklyReviewService.swift
//  learning
//
//  Created by macbook on 9/20/26.
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - 🎭 Productivity Persona & Badge
enum ProductivityPersona: String, CaseIterable, Sendable {
    case unstoppableDynamo = "The Unstoppable Dynamo"
    case focusMaster = "The Deep Focus Master"
    case habitChampion = "The Habit Champion"
    case mindfulAchiever = "The Mindful Achiever"
    case nightOwl = "The Night Owl Strategist"
    case steadyStarter = "The Steady Starter"

    var badgeIcon: String {
        switch self {
        case .unstoppableDynamo: return "flame.fill"
        case .focusMaster: return "target"
        case .habitChampion: return "trophy.fill"
        case .mindfulAchiever: return "leaf.fill"
        case .nightOwl: return "moon.stars.fill"
        case .steadyStarter: return "sparkles"
        }
    }

    var badgeColorHex: String {
        switch self {
        case .unstoppableDynamo: return "#FF6B6B"
        case .focusMaster: return "#FFD166"
        case .habitChampion: return "#4ECDC4"
        case .mindfulAchiever: return "#B388FF"
        case .nightOwl: return "#118AB2"
        case .steadyStarter: return "#06D6A0"
        }
    }

    var tagline: String {
        switch self {
        case .unstoppableDynamo:
            return "Eksekutor tanpa henti yang menuntaskan target dengan kecepatan luar biasa!"
        case .focusMaster:
            return "Ahli fokus mendalam yang minim distraksi dan memprioritaskan tugas berdampak besar."
        case .habitChampion:
            return "Master konsistensi yang menjaga streak kebiasaan harian tetap menyala tanpa henti."
        case .mindfulAchiever:
            return "Menjaga keseimbangan harmonis antara produktivitas kerja dan kesehatan fisik."
        case .nightOwl:
            return "Mencapai puncak kejernihan berpikir dan produktivitas di saat dunia sedang hening."
        case .steadyStarter:
            return "Membangun pondasi kebiasaan dan ritme produktif yang semakin kokoh setiap hari."
        }
    }
}

// MARK: - 📊 Weekly AI Productivity Report Model
struct WeeklyReport: Identifiable, Sendable {
    let id = UUID()
    let score: Int // 0 - 100
    let scoreGrade: String // "S", "A+", "A", "B", "C"
    let persona: ProductivityPersona
    let completedTasksCount: Int
    let totalTasksCount: Int
    let taskCompletionPercentage: Int
    let completedHabitsCheckins: Int
    let maxHabitStreak: Int
    let pomodoroSessionsCount: Int
    let totalFocusMinutes: Int
    let averageSteps: Int
    let topCategory: String
    let highlights: [String]
    let growthTips: [String]

    var shareableSummaryText: String {
        """
        📊 LAPORAN MINGGUAN PRODUKTIVITAS SAYA 🚀
        ━━━━━━━━━━━━━━━━━━━━
        🏆 Skor Produktivitas: \(score)/100 (Grade: \(scoreGrade))
        🎭 Persona: \(persona.rawValue)
        ✅ Tugas Selesai: \(completedTasksCount)/\(totalTasksCount) (\(taskCompletionPercentage)%)
        🔥 Streak Habit Tertinggi: \(maxHabitStreak) Hari
        ⏱️ Total Fokus Pomodoro: \(totalFocusMinutes) Menit (\(pomodoroSessionsCount) Sesi)
        👣 Rata-rata Langkah: \(averageSteps) langkah/hari
        ━━━━━━━━━━━━━━━━━━━━
        Dibuat dengan Aplikasi Produktivitas Neo-Brutalist iOS ✨
        """
    }
}

// MARK: - 🧠 AI Weekly Review Engine
@MainActor
final class AIWeeklyReviewService {
    static let shared = AIWeeklyReviewService()

    private init() {}

    /// Analisis data 7 hari terakhir dan hasilkan infografik laporan komprehensif
    func generateWeeklyReport(
        items: [Item],
        habits: [Habit],
        pomodoroSessions: Int = 0,
        healthSteps: Int = 0
    ) -> WeeklyReport {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) else {
            return fallbackReport()
        }

        // 1. Filter aktivitas 7 hari terakhir
        let weeklyItems = items.filter { item in
            let date = item.completedAt ?? item.timestamp
            return date >= sevenDaysAgo
        }

        let completedItems = weeklyItems.filter { $0.isCompleted }
        let totalCount = max(weeklyItems.count, 1)
        let completionRate = Double(completedItems.count) / Double(totalCount)

        // 2. Filter kebiasaan 7 hari terakhir
        var habitCheckinCount = 0
        for habit in habits {
            for offset in 0..<7 {
                if let day = calendar.date(byAdding: .day, value: -offset, to: today) {
                    if habit.isCompleted(on: day) {
                        habitCheckinCount += 1
                    }
                }
            }
        }

        let maxStreak = habits.map { $0.currentStreak }.max() ?? 0
        let totalPossibleHabits = max(habits.count * 7, 1)
        let habitRate = Double(habitCheckinCount) / Double(totalPossibleHabits)

        // 3. Kategori paling aktif
        var categoryCounts: [String: Int] = [:]
        for item in completedItems {
            categoryCounts[item.category, default: 0] += 1
        }
        let topCategory = categoryCounts.max(by: { $0.value < $1.value })?.key ?? "Umum"

        // 4. Hitung Skor Produktivitas (0-100)
        let taskScore = completionRate * 45.0
        let habitScore = min(1.0, habitRate * 1.5) * 30.0
        let focusScore = min(15.0, Double(pomodoroSessions) * 3.0)
        let physicalScore = min(10.0, (Double(healthSteps) / 7000.0) * 10.0)

        let rawScore = Int(taskScore + habitScore + focusScore + physicalScore)
        let finalScore = max(10, min(100, rawScore))

        // 5. Hitung Grade
        let grade: String
        switch finalScore {
        case 95...100: grade = "S"
        case 85..<95: grade = "A+"
        case 75..<85: grade = "A"
        case 60..<75: grade = "B"
        default: grade = "C"
        }

        // 6. Tentukan Persona Produktivitas
        let persona: ProductivityPersona
        if finalScore >= 88 && pomodoroSessions >= 4 {
            persona = .focusMaster
        } else if maxStreak >= 5 || habitRate >= 0.75 {
            persona = .habitChampion
        } else if completedItems.count >= 10 {
            persona = .unstoppableDynamo
        } else if healthSteps >= 8000 {
            persona = .mindfulAchiever
        } else if finalScore >= 70 {
            persona = .nightOwl
        } else {
            persona = .steadyStarter
        }

        // 7. Highlights
        var highlights: [String] = []
        if completedItems.count > 0 {
            highlights.append("Berhasil menyelesaikan \(completedItems.count) target tugas pekan ini.")
        }
        if maxStreak >= 3 {
            highlights.append("Mempertahankan rekor \(maxStreak) hari berturut-turut pada kebiasaanmu.")
        }
        if pomodoroSessions > 0 {
            highlights.append("Mengalokasikan \(pomodoroSessions * 25) menit untuk sesi deep work.")
        }
        if highlights.isEmpty {
            highlights.append("Mulai membangun ritme baru dan mencatat target kegiatan harian.")
        }

        // 8. Actionable Growth Tips
        var tips: [String] = []
        if completionRate < 0.6 {
            tips.append("Coba pecah tugas besar menjadi subtask kecil (15-20 menit) menggunakan fitur AI Task Breakdown.")
        }
        if habitRate < 0.5 && !habits.isEmpty {
            tips.append("Gunakan pengingat alarm kartun atau jadwalkan habit di pagi hari agar tidak terlewat.")
        }
        if pomodoroSessions < 2 {
            tips.append("Luangkan minimal 1 sesi Pomodoro 25 menit per hari untuk melatih fokus tanpa distraksi.")
        }
        tips.append("Pertahankan kategori '\(topCategory)' yang menjadi kekuatan produktivitas utamamu pekan ini!")

        let focusMinutes = pomodoroSessions * 25

        return WeeklyReport(
            score: finalScore,
            scoreGrade: grade,
            persona: persona,
            completedTasksCount: completedItems.count,
            totalTasksCount: weeklyItems.count,
            taskCompletionPercentage: Int(completionRate * 100),
            completedHabitsCheckins: habitCheckinCount,
            maxHabitStreak: maxStreak,
            pomodoroSessionsCount: pomodoroSessions,
            totalFocusMinutes: focusMinutes,
            averageSteps: healthSteps,
            topCategory: topCategory,
            highlights: highlights,
            growthTips: tips
        )
    }

    private func fallbackReport() -> WeeklyReport {
        WeeklyReport(
            score: 75,
            scoreGrade: "A",
            persona: .steadyStarter,
            completedTasksCount: 0,
            totalTasksCount: 0,
            taskCompletionPercentage: 0,
            completedHabitsCheckins: 0,
            maxHabitStreak: 0,
            pomodoroSessionsCount: 0,
            totalFocusMinutes: 0,
            averageSteps: 0,
            topCategory: "Umum",
            highlights: ["Siap memulai pekan baru dengan energi positif!"],
            growthTips: ["Catat tugas pertamamu hari ini untuk mulai membangun skor produktivitas."],
        )
    }
}
