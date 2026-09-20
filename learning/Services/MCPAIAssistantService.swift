//
//  MCPAIAssistantService.swift
//  learning
//
//  Created by macbook on 9/19/26.
//

import SwiftUI
import SwiftData
import WidgetKit
import Combine

// MARK: - 🤖 AI Provider Type
enum AIProviderType: String, CaseIterable, Sendable {
    case googleAccount = "googleAccount"
    case geminiApiKey = "geminiApiKey"
    case ninerouter = "ninerouter"

    var displayName: String {
        switch self {
        case .googleAccount: return "Akun Google Pribadi (Gratis)"
        case .geminiApiKey: return "Gemini Developer API Key"
        case .ninerouter: return "OpenRouter / Ninerouter"
        }
    }
}

// MARK: - 🤖 MCP Tool Invocation Record
struct MCPToolInvocation: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let argumentsSummary: String
    let icon: String
    let badgeColorHex: String
}

// MARK: - 📋 AI Action Proposal Model
struct AIActionProposal: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let subtitle: String
    let category: String
    let priority: String
    let targetDate: Date
    let subtasks: [String]
}

// MARK: - 💬 AI Chat Message Model
struct AIMessage: Identifiable, Sendable {
    let id = UUID()
    let isUser: Bool
    var content: String
    var toolCall: MCPToolInvocation?
    var toolResult: String?
    var proposal: AIActionProposal?
    var isStreaming: Bool = false
}

// MARK: - 🧠 MCPAIAssistantService
@MainActor
final class MCPAIAssistantService: ObservableObject {
    static let shared = MCPAIAssistantService()

    @Published var messages: [AIMessage] = []
    @Published var isProcessing: Bool = false
    @Published var activeToolName: String? = nil

    private init() {
        setupWelcomeMessage()
    }

    private func setupWelcomeMessage() {
        let greeting = """
        Halo! Saya **AI Asisten Produktivitas & MCP Router** pribadimu 🤖✨

        Saya dapat membantu kamu:
        • 🌅 Menyusun rencana harian (*"Susun rencana hari ini"*)
        • 📊 Laporan mingguan & skor produktivitas (*"Laporan mingguan"*)
        • 🌙 Evaluasi malam & kesehatan (*"Evaluasi hari ini"*)
        • 🪄 Pecah tugas jadi subtask (*"Pecah tugas presentasi"*)
        • 💡 Rekomendasi kebiasaan baru (*"Rekomendasikan habit"*)
        • 🛡️ Cek radar risiko streak habit (*"Cek risiko streak"*)
        • ⚡ Tambah tugas cerdas (*"Coding besok jam 8 malam"*)
        • 🤖 Menata ulang jadwal terlewat (*"Tata ulang jadwalku"*)
        • ⏱️ Mulai timer Pomodoro (*"Mulai fokus 25 menit"*)
        • 🛡️ Batasi distraksi (*"Kunci aplikasi pengganggu"*)
        • 🔥 Check-in habit harian (*"Ceklis habit membaca"*)

        Ada yang bisa saya bantu sekarang?
        """
        messages.append(AIMessage(isUser: false, content: greeting))
    }

    func clearHistory() {
        messages.removeAll()
        setupWelcomeMessage()
    }

    // MARK: - 🚀 Dispatch User Message & Local MCP Tools
    func sendMessage(
        _ text: String,
        provider: AIProviderType,
        apiKey: String,
        ninerouterBaseUrl: String,
        ninerouterModel: String,
        modelContext: ModelContext
    ) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Tambahkan Bubble User
        messages.append(AIMessage(isUser: true, content: trimmed))
        isProcessing = true
        defer { isProcessing = false }

        let lower = trimmed.lowercased()

        // 1. Cek Apakah Pesan Merupakan Perintah Local MCP Tools

        // Weekly Review & Productivity Score Infographic
        if lower.contains("laporan mingguan") || lower.contains("weekly review") || lower.contains("skor produktivitas") || lower.contains("performa minggu") || lower.contains("review mingguan") {
            await executeWeeklyReviewTool(modelContext: modelContext)
            return
        }

        // Morning Briefing
        if lower.contains("morning") || lower.contains("pagi") || lower.contains("susun rencana") || lower.contains("briefing") {
            await executeMorningBriefingTool(modelContext: modelContext)
            return
        }

        // Evening Review
        if lower.contains("evening") || lower.contains("malam") || lower.contains("evaluasi") || lower.contains("review") {
            await executeEveningReviewTool(modelContext: modelContext)
            return
        }

        // AI Task Breakdown & Auto Subtask
        if lower.contains("pecah") || lower.contains("breakdown") || lower.contains("subtask") || lower.contains("bagi tugas") {
            await executeTaskBreakdownTool(prompt: trimmed, modelContext: modelContext)
            return
        }

        // AI Habit Recommendation
        if lower.contains("rekomendasi habit") || lower.contains("rekomendasikan habit") || lower.contains("kebiasaan baru") || lower.contains("saran habit") {
            await executeHabitRecommenderTool(modelContext: modelContext)
            return
        }

        // AI Streak Risk Radar
        if lower.contains("risiko streak") || lower.contains("streak terancam") || lower.contains("radar streak") || lower.contains("cek streak") {
            await executeStreakRiskTool(modelContext: modelContext)
            return
        }

        // AI Schedule Rebalancer
        if lower.contains("tata ulang") || lower.contains("rebalance") || lower.contains("rapikan jadwal") || lower.contains("atur ulang jadwal") || lower.contains("jadwal berantakan") {
            await executeRebalanceScheduleTool(modelContext: modelContext)
            return
        }

        // Pomodoro Timer
        if lower.contains("pomodoro") || lower.contains("fokus") || lower.contains("mulai timer") {
            await executePomodoroTool(prompt: trimmed)
            return
        }

        // Ceklis Habit
        if lower.contains("habit") || lower.contains("ceklis") || lower.contains("kebiasaan") {
            await executeHabitCheckInTool(prompt: trimmed, modelContext: modelContext)
            return
        }

        // Rangkum Status Aktivitas & HealthKit
        if lower.contains("rangkum") || lower.contains("status") || lower.contains("rekap") || lower.contains("langkah") || lower.contains("kesehatan") || lower.contains("health") {
            await executeActivitySummaryTool(modelContext: modelContext)
            return
        }

        // Kunci Aplikasi Screen Time
        if lower.contains("kunci") || lower.contains("screen time") || lower.contains("distraksi") || lower.contains("blokir") {
            await executeScreenTimeTool()
            return
        }

        // Bersihkan Tugas Selesai
        if lower.contains("bersihkan") || lower.contains("hapus selesai") || lower.contains("clear completed") {
            await executeClearCompletedTool(modelContext: modelContext)
            return
        }

        // 2. Jika Bukan Tools Lokal, Teruskan ke LLM (Gemini Headless / OpenRouter API)
        await sendToAIEngine(
            prompt: trimmed,
            provider: provider,
            apiKey: apiKey,
            ninerouterBaseUrl: ninerouterBaseUrl,
            ninerouterModel: ninerouterModel,
            modelContext: modelContext
        )
    }

    // MARK: - 📊 Eksekusi MCP Tool: Weekly Review & Productivity Infographic
    private func executeWeeklyReviewTool(modelContext: ModelContext) async {
        let itemDescriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(itemDescriptor)) ?? []

        let habitDescriptor = FetchDescriptor<Habit>()
        let habits = (try? modelContext.fetch(habitDescriptor)) ?? []

        let pomodoroCount = PomodoroManager.shared.completedSessionsCount
        let steps = HealthKitManager.shared.todaySummary.steps

        let report = AIWeeklyReviewService.shared.generateWeeklyReport(
            items: items,
            habits: habits,
            pomodoroSessions: pomodoroCount,
            healthSteps: steps
        )

        HapticManager.shared.success()

        let toolCall = MCPToolInvocation(
            name: "generate_weekly_productivity_report",
            argumentsSummary: "score: \(report.score)/100, persona: \(report.persona.rawValue)",
            icon: "sparkles",
            badgeColorHex: "#FDE047"
        )

        let highlightsList = report.highlights.map { "• \($0)" }.joined(separator: "\n")
        let growthTipsList = report.growthTips.map { "• \($0)" }.joined(separator: "\n")

        let reply = """
        📊 **Laporan Mingguan & Skor Produktivitas AI** 🚀

        🏆 **Skor Produktivitas:** **\(report.score)/100 (Grade: \(report.scoreGrade))**
        🎭 **Persona:** **\(report.persona.rawValue)**
        *\(report.persona.tagline)*

        📈 **Performa 7 Hari:**
        • ✅ Tugas Tuntas: **\(report.completedTasksCount)/\(report.totalTasksCount) (\(report.taskCompletionPercentage)%)**
        • 🔥 Max Habit Streak: **\(report.maxHabitStreak) Hari**
        • ⏱️ Fokus Pomodoro: **\(report.totalFocusMinutes) Menit (\(report.pomodoroSessionsCount) sesi)**
        • 👣 Rata-rata Langkah: **\(report.averageSteps) langkah/hari**

        ✨ **Highlight Pencapaian:**
        \(highlightsList)

        💡 **Saran Strategis Pekan Depan:**
        \(growthTipsList)

        *Kamu juga dapat melihat visual infografik lengkap pada tab Profil > Statistik.*
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Score \(report.score)")
    }

    // MARK: - 🌅 Eksekusi MCP Tool: Morning Briefing
    private func executeMorningBriefingTool(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>(sortBy: [SortDescriptor(\.timestamp, order: .forward)])
        let items = (try? modelContext.fetch(descriptor)) ?? []

        let calendar = Calendar.current
        let todayItems = items.filter { calendar.isDateInToday($0.timestamp) && !$0.isCompleted }
        let highPriority = todayItems.filter { $0.priority == "Tinggi" }

        let health = HealthKitManager.shared.todaySummary
        HapticManager.shared.impact(style: .medium)

        let toolCall = MCPToolInvocation(
            name: "generate_morning_briefing",
            argumentsSummary: "tasks: \(todayItems.count), urgent: \(highPriority.count)",
            icon: "sun.max.fill",
            badgeColorHex: "#FDE047"
        )

        var reply = """
        🌅 **Selamat Pagi! Berikut Rencana Fokus Hari Ini:**

        📋 **Agenda Tugas:**
        Kamu memiliki **\(todayItems.count) tugas aktif** untuk diselesaikan hari ini.
        """

        if !highPriority.isEmpty {
            reply += "\n\n🔥 **Prioritas Utama (Must-Do):**\n"
            for item in highPriority {
                reply += "• **\(item.title)** (\(item.category)) - \(CalendarDateCache.shared.formatTime(item.timestamp))\n"
            }
        }

        if health.sleepDurationHours > 0 {
            reply += "\n\n😴 **Kebugaran & Pemulihan:**\nTidur semalam: **\(health.sleepFormatted)** (\(String(format: "%.1f", health.sleepDurationHours)) jam). Kondisimu siap untuk produktif!"
        }

        reply += "\n\n💡 *Saran AI:* Mulai kerjakan tugas prioritas tertinggi di sesi pagi dengan Pomodoro 25 menit!"

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "\(todayItems.count) tasks briefed")
    }

    // MARK: - 🌙 Eksekusi MCP Tool: Evening Review
    private func executeEveningReviewTool(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []

        let calendar = Calendar.current
        let todayCompleted = items.filter { calendar.isDateInToday($0.timestamp) && $0.isCompleted }.count
        let todayPending = items.filter { calendar.isDateInToday($0.timestamp) && !$0.isCompleted }.count

        let health = HealthKitManager.shared.todaySummary
        HapticManager.shared.impact(style: .light)

        let toolCall = MCPToolInvocation(
            name: "generate_evening_review",
            argumentsSummary: "completed: \(todayCompleted), steps: \(health.steps)",
            icon: "moon.stars.fill",
            badgeColorHex: "#C084FC"
        )

        let reply = """
        🌙 **Evaluasi & Rekapitulasi Hari Ini:**

        🎯 **Pencapaian Tugas:**
        • Selesai: **\(todayCompleted) tugas** 🎉
        • Tertunda: **\(todayPending) tugas**

        🏃 **Aktivitas Fisik:**
        • Langkah: **\(health.steps)** langkah
        • Kalori Terbakar: **\(Int(health.activeCalories))** kkal

        ✨ **Refleksi Malam:**
        Kerja keras yang luar biasa hari ini! Jangan lupa istirahat cukup untuk memulihkan energi esok hari.
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Review generated")
    }

    // MARK: - 🪄 Eksekusi MCP Tool: AI Task Breakdown
    private func executeTaskBreakdownTool(prompt: String, modelContext: ModelContext) async {
        var cleanPrompt = prompt
            .replacingOccurrences(of: "pecah tugas", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "breakdown", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "subtask", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "bagi tugas", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "tolong", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanPrompt.isEmpty {
            cleanPrompt = "Persiapan Proyek & Tugas Penting"
        }

        let subtasks = AITaskBreakdownService.shared.generateSubtasks(for: cleanPrompt, notes: "")
        let tagSuggestion = AITaskBreakdownService.shared.suggestTags(for: cleanPrompt)

        HapticManager.shared.success()

        let toolCall = MCPToolInvocation(
            name: "generate_task_subtasks",
            argumentsSummary: "subtasks: \(subtasks.count), priority: \(tagSuggestion.priority.rawValue)",
            icon: "wand.and.stars",
            badgeColorHex: "#A7F3D0"
        )

        let subtaskListText = subtasks.map { "• \($0.title)" }.joined(separator: "\n")

        let reply = """
        🪄 **AI Task Breakdown Selesai!**

        Target Utama: **\(cleanPrompt)**
        Rekomendasi Prioritas: **\(tagSuggestion.priority.rawValue)** (\(tagSuggestion.reasoning))
        Estimasi Durasi: **\(tagSuggestion.estimatedDurationMinutes) Menit**

        📋 **Rekomendasi Langkah Subtask:**
        \(subtaskListText)

        💡 *Tips:* Kamu juga bisa langsung membuat tugas baru dan menekan tombol *"Pecah Tugas Otomatis 🪄"* di form Add Activity.
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "\(subtasks.count) subtasks generated")
    }

    // MARK: - 💡 Eksekusi MCP Tool: Habit Recommendation
    private func executeHabitRecommenderTool(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Habit>()
        let existingHabits = (try? modelContext.fetch(descriptor)) ?? []

        let itemDescriptor = FetchDescriptor<Item>()
        let existingTasks = (try? modelContext.fetch(itemDescriptor)) ?? []

        let proposals = AIHabitRecommenderService.shared.generateRecommendations(
            existingHabits: existingHabits,
            existingTasks: existingTasks
        )

        HapticManager.shared.success()

        let toolCall = MCPToolInvocation(
            name: "recommend_positive_habits",
            argumentsSummary: "proposals: \(proposals.count)",
            icon: "wand.and.stars",
            badgeColorHex: "#FDE047"
        )

        var proposalText = ""
        for (idx, p) in proposals.prefix(3).enumerated() {
            proposalText += "\n\(idx + 1). **\(p.title)** (\(p.category.rawValue))\n   • Target: \(p.frequency.rawValue) (\(p.timeOfDay))\n   • Manfaat: *\(p.benefit)*\n"
        }

        let reply = """
        💡 **Rekomendasi Kebiasaan Positif AI:**
        \(proposalText)
        Kamu bisa langsung mengadopsi kebiasaan ini dalam 1 ketukan pada tab **Kebiasaan > AI Rutinitas 🪄**!
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "\(proposals.count) habit proposals")
    }

    // MARK: - 🛡️ Eksekusi MCP Tool: Streak Risk Radar
    private func executeStreakRiskTool(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Habit>()
        let habits = (try? modelContext.fetch(descriptor)) ?? []

        let risks = AIHabitRecommenderService.shared.assessStreakRisks(for: habits)
        let endangered = risks.filter { item in
            item.riskLevel == .critical || item.riskLevel == .high || item.riskLevel == .moderate
        }

        HapticManager.shared.impact(style: .medium)

        let toolCall = MCPToolInvocation(
            name: "assess_streak_risks",
            argumentsSummary: "endangered: \(endangered.count)",
            icon: "flame.fill",
            badgeColorHex: "#FCA5A5"
        )

        let reply: String
        if endangered.isEmpty {
            reply = """
            🛡️ **Radar Streak Aman!**

            Seluruh kebiasaan aktifmu sudah diceklis hari ini atau berada dalam kondisi aman. Pertahankan konsistensi luar biasamu! 🔥✨
            """
        } else {
            var riskList = ""
            for r in endangered {
                riskList += "\n• **\(r.title)** (Streak: \(r.currentStreak) hari) → Risiko: **\(r.riskLevel.rawValue)** (\(r.reason))"
            }
            reply = """
            ⚠️ **Perhatian! Ditemukan Streak yang Terancam Putus:**
            \(riskList)

            ⚡ *Saran AI:* Segera luangkan waktu 5 menit untuk menyelesaikan kebiasaan ini sebelum hari berganti!
            """
        }

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "\(endangered.count) endangered streaks")
    }

    // MARK: - 🤖 Eksekusi MCP Tool: Schedule Rebalancer
    private func executeRebalanceScheduleTool(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>(sortBy: [SortDescriptor(\.timestamp, order: .forward)])
        let items = (try? modelContext.fetch(descriptor)) ?? []

        let proposals = AIScheduleRebalancerService.shared.analyzeAndGenerateProposals(for: items)

        if proposals.isEmpty {
            await streamAssistantMessage(fullContent: "Jadwal harianmu sudah sangat rapi dan tidak ada tugas yang bertabrakan atau terlewat!")
            return
        }

        // Terapkan perubahan jadwal
        await AIScheduleRebalancerService.shared.applyRebalance(proposals: proposals, in: modelContext)
        HapticManager.shared.success()

        let toolCall = MCPToolInvocation(
            name: "rebalance_overdue_and_conflicts",
            argumentsSummary: "rescheduled: \(proposals.count) tasks",
            icon: "arrow.triangle.2.circlepath",
            badgeColorHex: "#A7F3D0"
        )

        let proposalListText = proposals.map { "• **\($0.item.title)** dipindahkan ke: \(CalendarDateCache.shared.formatTime($0.proposedDate))" }.joined(separator: "\n")

        let reply = """
        🤖 **Jadwal Berhasil Ditata Ulang!**

        Ditemukan **\(proposals.count) tugas** yang terlewat atau bertabrakan. AI telah mengatur ulang jadwalnya ke slot kosong terbaik:
        \(proposalListText)

        Pengingat notifikasi dan widget juga telah diperbarui secara otomatis. Tetap semangat! 🚀
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "\(proposals.count) rebalanced")
    }

    // MARK: - ⏱️ Eksekusi MCP Tool: Pomodoro Timer
    private func executePomodoroTool(prompt: String) async {
        let pomodoro = PomodoroManager.shared
        if prompt.localizedCaseInsensitiveContains("istirahat") {
            pomodoro.selectPreset(.shortBreak)
        } else if prompt.localizedCaseInsensitiveContains("deep") || prompt.localizedCaseInsensitiveContains("panjang") {
            pomodoro.selectPreset(.deepFocus)
        } else {
            pomodoro.selectPreset(.quickFocus)
        }

        pomodoro.startTimer()
        HapticManager.shared.success()

        let toolCall = MCPToolInvocation(
            name: "start_pomodoro_focus",
            argumentsSummary: "preset: \(pomodoro.selectedPreset.rawValue)",
            icon: "timer",
            badgeColorHex: "#FCA5A5"
        )

        let reply = """
        ⏱️ **Sesi Pomodoro Berhasil Dimulai!**

        • Mode: **\(pomodoro.selectedPreset.rawValue)**
        • Durasi: **\(pomodoro.remainingSeconds / 60) Menit**
        • Dynamic Island & Live Activity telah aktif di layar kunci 🎯

        Jauhkan distraksi dan mari mulai fokus menyelesaikan tugas pertamamu!
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Pomodoro started")
    }

    // MARK: - 🔥 Eksekusi MCP Tool: Check-In Habit
    private func executeHabitCheckInTool(prompt: String, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Habit>()
        let habits = (try? modelContext.fetch(descriptor)) ?? []

        guard let target = habits.first(where: { prompt.localizedCaseInsensitiveContains($0.title) }) ?? habits.first else {
            await streamAssistantMessage(fullContent: "Belum ada kebiasaan/habit yang tersimpan di aplikasi.")
            return
        }

        target.toggleCompletion(on: Date())
        try? modelContext.save()
        HapticManager.shared.success()

        let toolCall = MCPToolInvocation(
            name: "log_habit_checkin",
            argumentsSummary: "habit: \(target.title)",
            icon: "flame.fill",
            badgeColorHex: "#FDBA74"
        )

        let reply = """
        🔥 **Check-in Habit Berhasil!**

        Target kebiasaan **\(target.title)** telah diceklis hari ini!
        Streak kamu saat ini: **\(target.currentStreak) hari berturut-turut!** 🚀
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Streak \(target.currentStreak)")
    }

    // MARK: - 📊 Eksekusi MCP Tool: Summary Aktivitas & HealthKit
    private func executeActivitySummaryTool(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        let pending = items.filter { !$0.isCompleted }.count
        let completed = items.filter { $0.isCompleted }.count

        let health = HealthKitManager.shared.todaySummary

        let toolCall = MCPToolInvocation(
            name: "get_health_activity_summary",
            argumentsSummary: "pending: \(pending), steps: \(health.steps)",
            icon: "chart.bar.fill",
            badgeColorHex: "#6EE7B7"
        )

        let reply = """
        📊 **Ringkasan Aktivitas & Kebugaran Hari Ini:**

        📋 **Status Tugas:**
        • ⏳ Perlu Dikerjakan: **\(pending) tugas**
        • ✅ Telah Selesai: **\(completed) tugas**

        🏃 **HealthKit Kebugaran:**
        • 👣 Langkah: **\(health.steps)** / 10.000 langkah
        • 🔥 Kalori Aktif: **\(Int(health.activeCalories))** kkal
        • 📏 Jarak Tempuh: **\(String(format: "%.2f", health.distanceKm))** km
        • 🌙 Tidur Semalam: **\(health.sleepFormatted)**

        Kondisi fisik dan produktivitas harianmu terpantau sangat baik! 🌟
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Summary generated")
    }

    // MARK: - 🛡️ Eksekusi MCP Tool: Screen Time Shield
    private func executeScreenTimeTool() async {
        let screenTime = ScreenTimeManager.shared
        if screenTime.isShieldActive {
            screenTime.disableAppShield()
        } else {
            screenTime.enableAppShield()
        }
        HapticManager.shared.warning()

        let toolCall = MCPToolInvocation(
            name: "toggle_app_shield",
            argumentsSummary: "isActive: \(screenTime.isShieldActive)",
            icon: "shield.lefthalf.filled",
            badgeColorHex: "#93C5FD"
        )

        let reply = screenTime.isShieldActive ?
            "🛡️ **Screen Time Shield Diaktifkan!**\nAplikasi distraksi (Instagram, TikTok, YouTube, Games) dibatasi agar kamu fokus penuh." :
            "🔓 **Screen Time Shield Dinonaktifkan.**\nAkses ke seluruh aplikasi telah dibuka kembali."

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Shield set to \(screenTime.isShieldActive)")
    }

    // MARK: - 🧹 Eksekusi MCP Tool: Bersihkan Tugas Selesai
    private func executeClearCompletedTool(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        let completed = items.filter { $0.isCompleted }

        for item in completed {
            modelContext.delete(item)
        }
        try? modelContext.save()
        HapticManager.shared.success()

        let toolCall = MCPToolInvocation(
            name: "cleanup_completed_activities",
            argumentsSummary: "deleted: \(completed.count) items",
            icon: "trash.slash.fill",
            badgeColorHex: "#FDE047"
        )

        let reply = """
        🧹 **Daftar Tugas Telah Dibersihkan!**

        Sebanyak **\(completed.count) tugas selesai** berhasil dihapus dari daftar utama untuk menjaga antarmuka tetap rapi dan bersih. ✨
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Cleaned \(completed.count) items")
    }

    // MARK: - 🌐 Komunikasi ke Cloud AI Engine (Gemini / Ninerouter / Headless Web)
    private func sendToAIEngine(
        prompt: String,
        provider: AIProviderType,
        apiKey: String,
        ninerouterBaseUrl: String,
        ninerouterModel: String,
        modelContext: ModelContext
    ) async {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        let pending = items.filter { !$0.isCompleted }.prefix(5).map { "- \($0.title) (\($0.category))" }.joined(separator: "\n")

        // Cek Natural Time Parsing untuk pembuatan tugas langsung
        let parsed = NaturalTimeParser.parse(from: prompt)
        let isTaskCreation = prompt.localizedCaseInsensitiveContains("tambah") ||
                             prompt.localizedCaseInsensitiveContains("buat tugas") ||
                             prompt.localizedCaseInsensitiveContains("ingatkan") ||
                             prompt.localizedCaseInsensitiveContains("jadwalkan") ||
                             parsed.hasExplicitTime

        if isTaskCreation && !parsed.cleanText.isEmpty {
            await executeDirectCreateTaskTool(parsed: parsed, modelContext: modelContext, existingItems: items)
            return
        }

        let systemInstruction = """
        Kamu adalah Asisten AI Produktivitas untuk aplikasi to-do list Neo-Brutalist cartoon iOS.
        Tugasmu:
        1. Menjawab pertanyaan pengguna secara ramah, ringkas, dan memotivasi.
        2. Format teks dengan markdown rapi (*bold*, bullet point, header).
        3. Daftar tugas aktif pengguna saat ini:
        \(pending.isEmpty ? "Tidak ada tugas tertunda." : pending)
        """

        do {
            let replyText: String
            switch provider {
            case .googleAccount:
                replyText = try await GeminiHeadlessEngine.shared.queryGemini(prompt: "\(systemInstruction)\n\nPertanyaan: \(prompt)")

            case .geminiApiKey:
                replyText = try await sendGeminiAPIRequest(prompt: prompt, systemInstruction: systemInstruction, apiKey: apiKey)

            case .ninerouter:
                replyText = try await sendNinerouterRequest(
                    prompt: prompt,
                    systemInstruction: systemInstruction,
                    apiKey: apiKey,
                    baseUrl: ninerouterBaseUrl,
                    model: ninerouterModel
                )
            }

            await streamAssistantMessage(fullContent: replyText)
        } catch {
            let errorReply = "⚠️ Maaf, terjadi kendala koneksi AI: \(error.localizedDescription)\n\nSilakan cek koneksi internet atau pengaturan API key di menu Pengaturan Asisten."
            await streamAssistantMessage(fullContent: errorReply)
        }
    }

    // MARK: - ⚡ Direct Task Creation Tool
    private func executeDirectCreateTaskTool(
        parsed: ParsedNaturalSchedule,
        modelContext: ModelContext,
        existingItems: [Item]
    ) async {
        let taskTitle = parsed.cleanText.isEmpty ? "Tugas Baru" : parsed.cleanText
        let taskDate = parsed.targetDate

        let tagSuggestion = AITaskBreakdownService.shared.suggestTags(for: taskTitle)
        let suggestedCategory = tagSuggestion.category.rawValue
        let suggestedPriority = tagSuggestion.priority.rawValue

        let conflicts = ScheduleConflictDetector.shared.detectConflicts(
            for: taskDate,
            toleranceMinutes: 30,
            in: existingItems
        )

        let newItem = Item(
            title: taskTitle,
            notes: "Dibuat otomatis oleh AI Asisten",
            timestamp: taskDate,
            isCompleted: false,
            completedAt: nil,
            priority: suggestedPriority,
            category: suggestedCategory,
            isRecurring: false,
            recurrenceRule: "Sekali Saja",
            customSoundName: "cartoon_bell.caf",
            subtasks: [],
            imageAttachmentData: nil
        )

        modelContext.insert(newItem)
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        HapticManager.shared.success()

        let toolCall = MCPToolInvocation(
            name: "create_activity",
            argumentsSummary: "title: \(taskTitle), date: \(taskDate.formatted(date: .abbreviated, time: .shortened))",
            icon: "plus.circle.fill",
            badgeColorHex: "#6EE7B7"
        )

        var reply = """
        ⚡ **Tugas Berhasil Ditambahkan!**

        • **Judul:** \(taskTitle)
        • **Kategori:** \(suggestedCategory)
        • **Prioritas:** \(suggestedPriority)
        • **Waktu:** \(taskDate.formatted(date: .complete, time: .shortened))
        """

        if let conflict = conflicts.first {
            let nextAvailableSlot = ScheduleConflictDetector.shared.suggestNextAvailableSlot(startingFrom: taskDate, in: existingItems)
            let nextSlotStr = nextAvailableSlot.formatted(date: .omitted, time: .shortened)
            reply += "\n\n⚠️ **Catatan Jadwal:** Waktu ini berdekatan dengan *\"\(conflict.existingTaskTitle)\"*. Rekomendasi jam luang berikutnya: **\(nextSlotStr)**."
        }

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Created \(taskTitle)")
    }

    // MARK: - 🌊 Typing Effect Streaming Assistant Message
    private func streamAssistantMessage(
        fullContent: String,
        toolCall: MCPToolInvocation? = nil,
        toolResult: String? = nil,
        proposal: AIActionProposal? = nil
    ) async {
        var msg = AIMessage(
            isUser: false,
            content: "",
            toolCall: toolCall,
            toolResult: toolResult,
            proposal: proposal,
            isStreaming: true
        )
        messages.append(msg)
        let lastIdx = messages.count - 1

        let chunkSize = 4
        let chars = Array(fullContent)
        var currentIndex = 0

        while currentIndex < chars.count {
            let nextIndex = min(currentIndex + chunkSize, chars.count)
            let piece = String(chars[currentIndex..<nextIndex])
            messages[lastIdx].content += piece
            currentIndex = nextIndex
            try? await Task.sleep(nanoseconds: 12_000_000)
        }

        messages[lastIdx].isStreaming = false
    }

    // MARK: - 🌐 HTTP AI Helpers
    private func sendGeminiAPIRequest(prompt: String, systemInstruction: String, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "MCPAIAssistant", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key Gemini belum diisi."])
        }

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": systemInstruction]]],
            "contents": [["parts": [["text": prompt]]]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "GeminiAPI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Gemini API Error"])
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let candidates = json?["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let text = parts.first?["text"] as? String {
            return text
        }

        return "Tidak dapat memproses respons dari Gemini."
    }

    private func sendNinerouterRequest(prompt: String, systemInstruction: String, apiKey: String, baseUrl: String, model: String) async throws -> String {
        let cleanBase = baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        let endpoint = cleanBase.hasSuffix("/") ? "\(cleanBase)chat/completions" : "\(cleanBase)/chat/completions"
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let modelName = model.isEmpty ? "gpt-4o-mini" : model
        let body: [String: Any] = [
            "model": modelName,
            "messages": [
                ["role": "system", "content": systemInstruction],
                ["role": "user", "content": prompt]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "NinerouterAPI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Ninerouter API Error"])
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let choices = json?["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let text = message["content"] as? String {
            return text
        }

        return "Tidak dapat memproses respons dari OpenRouter/Ninerouter."
    }
}
