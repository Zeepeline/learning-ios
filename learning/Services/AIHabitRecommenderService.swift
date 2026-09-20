//
//  AIHabitRecommenderService.swift
//  learning
//
//  Created by macbook on 9/20/26.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - ⚠️ Streak Risk Level
enum HabitStreakRiskLevel: String, Sendable {
    case safe = "Aman"
    case moderate = "Perlu Perhatian"
    case high = "Risiko Tinggi"
    case critical = "Darurat (Streak Terancam Putus)"

    var badgeColor: Color {
        switch self {
        case .safe: return .cartoonMint
        case .moderate: return .cartoonYellow
        case .high: return .cartoonCoral
        case .critical: return Color(red: 0.95, green: 0.25, blue: 0.25)
        }
    }

    var icon: String {
        switch self {
        case .safe: return "shield.checkmark.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .high: return "flame.fill"
        case .critical: return "bolt.trianglebadge.exclamationmark.fill"
        }
    }
}

// MARK: - 📊 Streak Risk Assessment Item
struct HabitStreakRiskItem: Identifiable, Sendable {
    let id: PersistentIdentifier
    let title: String
    let category: String
    let icon: String
    let currentStreak: Int
    let riskLevel: HabitStreakRiskLevel
    let reason: String
    let motivationalTip: String
}

// MARK: - 💡 AI Habit Recommendation Proposal
struct AIHabitRecommendation: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let category: HabitCategory
    let icon: String
    let colorHex: String
    let frequency: HabitFrequency
    let timeOfDay: String
    let benefit: String
    var isSelected: Bool = true
}

// MARK: - 🤖 AI Habit Recommender Engine
final class AIHabitRecommenderService: Sendable {
    static let shared = AIHabitRecommenderService()

    private init() {}

    // MARK: - 1. Streak Risk Predictor
    func assessStreakRisks(for habits: [Habit]) -> [HabitStreakRiskItem] {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)

        var riskItems: [HabitStreakRiskItem] = []

        for habit in habits {
            // Jika sudah selesai hari ini, streak aman
            if habit.isCompletedToday {
                continue
            }

            let streak = habit.currentStreak
            let weeklyRate = habit.weeklyCompletionRate

            // Tentukan level risiko berdasarkan jam sekarang dan streak yang sudah terkumpul
            if streak >= 3 {
                if currentHour >= 18 {
                    // Malam hari & streak >= 3 belum diceklis -> Critical
                    riskItems.append(HabitStreakRiskItem(
                        id: habit.id,
                        title: habit.title,
                        category: habit.category,
                        icon: habit.icon,
                        currentStreak: streak,
                        riskLevel: .critical,
                        reason: "Sudah malam hari (\(currentHour):00). Streak \(streak) hari kamu akan hilang jika tidak diceklis sebelum tengah malam!",
                        motivationalTip: "Luangkan 5 menit sekarang untuk menyelesaikan '\(habit.title)' dan jaga momentum apimu! 🔥"
                    ))
                } else if currentHour >= 13 {
                    // Siang/Sore & streak >= 3 belum diceklis -> High
                    riskItems.append(HabitStreakRiskItem(
                        id: habit.id,
                        title: habit.title,
                        category: habit.category,
                        icon: habit.icon,
                        currentStreak: streak,
                        riskLevel: .high,
                        reason: "Streak \(streak) hari belum diceklis hari ini. Jangan sampai terlupa di sore hari.",
                        motivationalTip: "Selesaikan sekarang selagi masih siang agar malam hari kamu bisa beristirahat santai."
                    ))
                } else {
                    // Pagi hari -> Moderate
                    riskItems.append(HabitStreakRiskItem(
                        id: habit.id,
                        title: habit.title,
                        category: habit.category,
                        icon: habit.icon,
                        currentStreak: streak,
                        riskLevel: .moderate,
                        reason: "Streak \(streak) hari aktif. Rencanakan waktu terbaik hari ini untuk melakukannya.",
                        motivationalTip: "Pagi adalah waktu terbaik untuk menetapkan niat kebiasaan harian."
                    ))
                }
            } else if weeklyRate < 0.4 && streak > 0 {
                // Streak kecil dan konsistensi mingguan rendah
                riskItems.append(HabitStreakRiskItem(
                    id: habit.id,
                    title: habit.title,
                    category: habit.category,
                    icon: habit.icon,
                    currentStreak: streak,
                    riskLevel: .moderate,
                    reason: "Tingkat konsistensi 7 hari terakhir hanya \(Int(weeklyRate * 100))%.",
                    motivationalTip: "Kecilkan target agar lebih mudah dicapai setiap hari tanpa beban."
                ))
            }
        }

        // Urutkan dari risiko paling gawat (critical -> high -> moderate)
        return riskItems.sorted { itemA, itemB in
            riskPriority(itemA.riskLevel) > riskPriority(itemB.riskLevel)
        }
    }

    private func riskPriority(_ level: HabitStreakRiskLevel) -> Int {
        switch level {
        case .critical: return 3
        case .high: return 2
        case .moderate: return 1
        case .safe: return 0
        }
    }

    // MARK: - 2. AI Routine Recommender
    func generateRecommendations(existingHabits: [Habit], existingTasks: [Item]) -> [AIHabitRecommendation] {
        let existingTitles = Set(existingHabits.map { $0.title.lowercased() })
        let existingCategories = Set(existingHabits.map { $0.category.lowercased() })

        var candidates: [AIHabitRecommendation] = [
            AIHabitRecommendation(
                title: "Minum 2 Liter Air",
                category: .health,
                icon: "drop.fill",
                colorHex: "#4ECDC4",
                frequency: .daily,
                timeOfDay: "Sepanjang Hari",
                benefit: "Meningkatkan energi otak, metabolisme tubuh, dan menjaga fokus saat belajar/bekerja."
            ),
            AIHabitRecommendation(
                title: "Membaca Buku 15 Menit",
                category: .learning,
                icon: "book.fill",
                colorHex: "#118AB2",
                frequency: .daily,
                timeOfDay: "Pagi / Sebelum Tidur",
                benefit: "Memperluas wawasan, melatih konsentrasi, dan memperkaya kosa kata baru."
            ),
            AIHabitRecommendation(
                title: "Stretching & Peregangan 5 Menit",
                category: .sports,
                icon: "figure.walk",
                colorHex: "#FF6B6B",
                frequency: .daily,
                timeOfDay: "Setelah Bekerja / Pagi",
                benefit: "Mencegah pegal leher dan punggung akibat terlalu lama duduk di depan layar."
            ),
            AIHabitRecommendation(
                title: "Meditasi & Mindfulness 10 Menit",
                category: .mindfulness,
                icon: "sparkles",
                colorHex: "#B388FF",
                frequency: .daily,
                timeOfDay: "Pagi Hari",
                benefit: "Meredakan stres, menstabilkan emosi, dan meningkatkan kejernihan berpikir."
            ),
            AIHabitRecommendation(
                title: "Pencatatan Pengeluaran Harian",
                category: .finance,
                icon: "creditcard.fill",
                colorHex: "#06D6A0",
                frequency: .daily,
                timeOfDay: "Malam Hari",
                benefit: "Menjaga arus kas pribadi tetap sehat dan mencegah pemborosan impulsif."
            ),
            AIHabitRecommendation(
                title: "Deep Work Tanpa Notifikasi 25m",
                category: .productivity,
                icon: "bolt.fill",
                colorHex: "#FFD166",
                frequency: .weekdays,
                timeOfDay: "Jam Produktif Pagi",
                benefit: "Menyelesaikan target tugas penting dengan kecepatan 2x lipat."
            ),
            AIHabitRecommendation(
                title: "Tidur Teratur Sebelum Jam 23:00",
                category: .health,
                icon: "bed.double.fill",
                colorHex: "#4ECDC4",
                frequency: .daily,
                timeOfDay: "Malam Hari",
                benefit: "Memperbaiki ritme sirkadian untuk performa puncak di esok hari."
            )
        ]

        // Filter rekomendasi yang belum dimiliki pengguna
        var filtered = candidates.filter { !existingTitles.contains($0.title.lowercased()) }

        // Berikan prioritas pada kategori yang belum pernah ada
        filtered.sort { a, b in
            let aHasCat = existingCategories.contains(a.category.rawValue.lowercased())
            let bHasCat = existingCategories.contains(b.category.rawValue.lowercased())
            if !aHasCat && bHasCat { return true }
            return false
        }

        return Array(filtered.prefix(4))
    }

    // MARK: - 3. Quick Adopt Habit
    @MainActor
    func adoptHabit(recommendation: AIHabitRecommendation, in modelContext: ModelContext) {
        let newHabit = Habit(
            title: recommendation.title,
            icon: recommendation.icon,
            colorHex: recommendation.colorHex,
            category: recommendation.category.rawValue,
            targetFrequency: recommendation.frequency.rawValue,
            completedDates: [],
            createdAt: Date()
        )
        modelContext.insert(newHabit)
        try? modelContext.save()
    }
}
