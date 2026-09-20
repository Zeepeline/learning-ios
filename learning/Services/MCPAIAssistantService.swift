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

// MARK: - 💬 AI Chat Message
struct AIMessage: Identifiable {
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
        • 🌙 Evaluasi malam & kesehatan (*"Evaluasi hari ini"*)
        • ⚡ Tambah tugas cerdas & jadwal (*"Coding besok jam 8 malam"*)
        • 🤖 Menata ulang jadwal yang terlewat (*"Tata ulang jadwalku"*)
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

        // 2. Jika Bukan Perintah Tool Langsung -> Kirim ke AI Cloud Engine
        await sendToAIEngine(
            prompt: trimmed,
            provider: provider,
            apiKey: apiKey,
            ninerouterBaseUrl: ninerouterBaseUrl,
            ninerouterModel: ninerouterModel,
            modelContext: modelContext
        )
    }

    // MARK: - 🌅 Daily AI Coach: Morning Briefing Tool
    private func executeMorningBriefingTool(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        let pending = items.filter { !$0.isCompleted }

        let habitDesc = FetchDescriptor<Habit>()
        let habits = (try? modelContext.fetch(habitDesc)) ?? []
        let uncompletedHabits = habits.filter { !$0.isCompletedToday }

        let health = HealthKitManager.shared.todaySummary

        let toolCall = MCPToolInvocation(
            name: "morning_briefing",
            argumentsSummary: "tasks: \(pending.count), habits: \(uncompletedHabits.count)",
            icon: "sun.max.fill",
            badgeColorHex: "#FDE047"
        )

        var taskSection = "Semua tugas telah selesai! Kamu bisa menambahkan target baru 🌟"
        if !pending.isEmpty {
            taskSection = ""
            for (i, t) in pending.prefix(4).enumerated() {
                let pIcon = t.priority == "Tinggi" ? "🔥" : "⚡"
                taskSection += "\n\(i + 1). \(pIcon) **\(t.title)** [\(t.category)]"
            }
        }

        var habitSection = "Semua kebiasaan telah diceklis! 🏆"
        if !uncompletedHabits.isEmpty {
            habitSection = uncompletedHabits.prefix(3).map { "• 🔥 **\($0.title)**" }.joined(separator: "\n")
        }

        let reply = """
        🌅 **Morning Briefing Harianmu Siap!**

        Selamat pagi! Berikut ringkasan fokus utama hari ini:

        🎯 **Prioritas Tugas (\(pending.count) Tugas Menanti):**
        \(taskSection)

        🔥 **Target Habit Hari Ini:**
        \(habitSection)

        🌙 **Kebugaran Pagi:**
        • 🛌 Tidur semalam: **\(health.sleepFormatted)**
        • 👣 Langkah awal: **\(health.steps)** langkah

        Mari mulai hari dengan fokus penuh! Mau saya jadwalkan sesi Pomodoro pertama? 🚀
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Summary generated")
    }

    // MARK: - 🌙 Daily AI Coach: Evening Review Tool
    private func executeEveningReviewTool(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        let completedToday = items.filter { $0.isCompleted && Calendar.current.isDateInToday($0.completedAt ?? $0.timestamp) }
        let remaining = items.filter { !$0.isCompleted }

        let habitDesc = FetchDescriptor<Habit>()
        let habits = (try? modelContext.fetch(habitDesc)) ?? []
        let completedHabits = habits.filter { $0.isCompletedToday }

        let health = HealthKitManager.shared.todaySummary

        let toolCall = MCPToolInvocation(
            name: "evening_review",
            argumentsSummary: "completed: \(completedToday.count), habits: \(completedHabits.count)",
            icon: "moon.stars.fill",
            badgeColorHex: "#C4B5FD"
        )

        let reply = """
        🌙 **Evening Review & Evaluasi Harian!**

        Kerja keras yang luar biasa hari ini! Berikut rekap pencapaianmu:

        ✅ **Aktivitas Terselesaikan:**
        • Berhasil menuntaskan **\(completedToday.count) tugas** hari ini.
        • Sisa tugas pending: **\(remaining.count) tugas**.

        🔥 **Konsistensi Habit:**
        • **\(completedHabits.count)/\(habits.count) kebiasaan** berhasil dijaga streak-nya.

        🏃‍♂️ **Performa Fisik:**
        • 👣 **\(health.steps)** Langkah kaki (\(String(format: "%.1f", health.distanceKm)) km)
        • 🔥 **\(Int(health.activeCalories))** kkal energi terbakar

        Waktunya beristirahat dan memulihkan energi untuk esok hari yang lebih produktif! 🛌✨
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Review generated")
    }

    // MARK: - 🤖 Eksekusi MCP Tool: AI Schedule Rebalancer
    private func executeRebalanceScheduleTool(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []

        let proposals = AIScheduleRebalancerService.shared.analyzeAndGenerateProposals(for: items)

        let toolCall = MCPToolInvocation(
            name: "ai_schedule_rebalancer",
            argumentsSummary: "proposals: \(proposals.count)",
            icon: "wand.and.stars",
            badgeColorHex: "#FDE047"
        )

        if proposals.isEmpty {
            let reply = """
            🎉 **Jadwalmu Sudah Sangat Rapi & Bebas Bentrok!**

            AI telah memeriksa seluruh daftar tugasmu hari ini. Tidak ditemukan tugas terlewat ataupun jam yang bertabrakan. Semua tugas terjadwal dengan baik! 🌟
            """
            await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "0 conflicts")
            return
        }

        // Terapkan penataan ulang secara otomatis
        await AIScheduleRebalancerService.shared.applyRebalance(proposals: proposals, in: modelContext)

        var proposalListText = ""
        for (idx, p) in proposals.enumerated() {
            let oldTime = p.originalDate.formatted(date: .omitted, time: .shortened)
            let newTime = p.proposedDate.formatted(date: .omitted, time: .shortened)
            let icon = p.reasonType == .overdue ? "⚠️" : "🔄"
            proposalListText += "\n\(idx + 1). \(icon) **\(p.item.title)**: ~~\(oldTime)~~ ➔ **\(newTime)** (\(p.reasonType.badgeTitle))"
        }

        let reply = """
        🪄 **Jadwal Berhasil Ditata Ulang Otomatis!**

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

        🏃‍♂️ **HealthKit Kebugaran:**
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
                replyText = try await GeminiHeadlessEngine.shared.queryGemini(
                    prompt: "\(systemInstruction)\n\nPertanyaan: \(prompt)"
                )
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
    private func executeDirectCreateTaskTool(parsed: ParsedNaturalSchedule, modelContext: ModelContext, existingItems: [Item]) async {
        let taskTitle = parsed.cleanText.isEmpty ? "Tugas Baru" : parsed.cleanText
        let taskDate = parsed.targetDate

        let suggestedCategory = determineCategory(from: taskTitle)

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
            priority: "Normal",
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
        • **Waktu:** \(taskDate.formatted(date: .complete, time: .shortened))
        """

        if let conflict = conflicts.first {
            let nextAvailableSlot = ScheduleConflictDetector.shared.suggestNextAvailableSlot(startingFrom: taskDate, in: existingItems)
            let nextSlotStr = nextAvailableSlot.formatted(date: .omitted, time: .shortened)
            reply += "\n\n⚠️ **Catatan Jadwal:** Waktu ini berdekatan dengan *\"\(conflict.existingTaskTitle)\"*. Rekomendasi jam luang berikutnya: **\(nextSlotStr)**."
        }

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Created \(taskTitle)")
    }

    private func determineCategory(from text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("coding") || lower.contains("code") || lower.contains("bug") || lower.contains("deploy") || lower.contains("program") {
            return "Coding"
        } else if lower.contains("belajar") || lower.contains("baca") || lower.contains("kuliah") || lower.contains("kursus") || lower.contains("ujian") {
            return "Belajar"
        } else if lower.contains("olahraga") || lower.contains("gym") || lower.contains("lari") || lower.contains("workout") || lower.contains("jalan") {
            return "Olahraga"
        } else if lower.contains("kerja") || lower.contains("meeting") || lower.contains("kantor") || lower.contains("proyek") {
            return "Kerja"
        } else {
            return "General"
        }
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
