//
//  MCPAIAssistantService.swift
//  learning
//
//  Created by macbook on 9/19/26.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

// MARK: - 🌐 AI Provider Selection
enum AIProviderType: String, CaseIterable, Identifiable {
    case googleAccount = "Cloud AI Engine (Akun Aktif)"
    case local = "Smart Local Co-Planner (Offline)"
    case gemini = "Developer API Key (AI Studio)"
    case ninerouter = "Multi-LLM Gateway (DeepSeek)"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .googleAccount: return "Cloud Engine"
        case .local: return "Local Engine"
        case .gemini: return "API Key"
        case .ninerouter: return "DeepSeek"
        }
    }
}

// MARK: - 🤖 MCP Chat Message Models
struct MCPAIChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: MessageRole
    var content: String
    let timestamp: Date
    var toolCall: MCPToolInvocation?
    var toolResult: String?
    var isExecutingTool: Bool
    var proposal: TaskProposal?

    enum MessageRole: String, Codable {
        case user
        case assistant
        case system
    }

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        toolCall: MCPToolInvocation? = nil,
        toolResult: String? = nil,
        isExecutingTool: Bool = false,
        proposal: TaskProposal? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.toolCall = toolCall
        self.toolResult = toolResult
        self.isExecutingTool = isExecutingTool
        self.proposal = proposal
    }
}

// MARK: - 🛠️ MCP Tool Invocation Data
struct MCPToolInvocation: Equatable {
    let name: String
    let argumentsSummary: String
    let icon: String
    let badgeColorHex: String
}

// MARK: - 📋 Pending Task Proposal (Interactive Discussion State)
struct TaskProposal: Equatable {
    let title: String
    let category: String
    let priority: String
    let subtasks: [String]
    let estimatedMinutes: Int
    var scheduledDate: Date?
    var scheduledDescription: String?
}

// MARK: - 🧠 MCP AI Assistant Service (Model Context Protocol Engine)
@MainActor
final class MCPAIAssistantService: ObservableObject {
    static let shared = MCPAIAssistantService()

    @Published var messages: [MCPAIChatMessage] = []
    @Published var isProcessing: Bool = false
    @Published var lastCreatedItem: Item? = nil
    @Published var lastCreatedHabit: Habit? = nil
    @Published var pendingProposal: TaskProposal? = nil

    private init() {
        messages.append(
            MCPAIChatMessage(
                role: .assistant,
                content: """
                Hai! Aku **AI Productivity Partner** yang terhubung langsung ke aplikasimu via **MCP (Model Context Protocol)**! 🚀✨

                Aku bisa membaca data aplikasimu dan mengeksekusi aksi nyata secara lokal:
                • 📋 Tambah tugas & deteksi jadwal otomatis (*"besok jam 8 malam"*)
                • 🌅 Susun **Morning Briefing** & Evaluasi **Evening Review**
                • ⏱️ Nyalakan / atur timer Pomodoro & Live Activity
                • 🏃‍♂️ Cek data langkah & kalori dari Apple Health
                • 🔥 Ceklis dan buat target Habit harian
                • 🛡️ Kunci aplikasi distraksi dengan Screen Time Shield

                Apa tugas atau target yang ingin kita capai hari ini?
                """
            )
        )
    }

    /// Efek mengetik mengalir kata demi kata yang mulus (Typewriter Token Streaming Effect)
    private func streamAssistantMessage(
        fullContent: String,
        toolCall: MCPToolInvocation? = nil,
        toolResult: String? = nil,
        proposal: TaskProposal? = nil
    ) async {
        let msgId = UUID()
        let initialMsg = MCPAIChatMessage(
            id: msgId,
            role: .assistant,
            content: "",
            timestamp: Date(),
            toolCall: toolCall,
            toolResult: toolResult,
            isExecutingTool: false,
            proposal: proposal
        )
        messages.append(initialMsg)

        // Stream kata per kata dengan jeda halus
        let words = fullContent.components(separatedBy: " ")
        var accumulated = ""

        for (index, word) in words.enumerated() {
            accumulated += (index == 0 ? "" : " ") + word
            if let idx = self.messages.firstIndex(where: { $0.id == msgId }) {
                self.messages[idx].content = accumulated
            }
            if words.count > 12 {
                try? await Task.sleep(nanoseconds: 12_000_000)
            }
        }

        if let idx = self.messages.firstIndex(where: { $0.id == msgId }) {
            self.messages[idx].content = fullContent
        }
    }

    /// Kirim pesan pengguna dan proses percakapan multi-turn / MCP Tool Dispatcher
    func sendMessage(
        _ userText: String,
        modelContext: ModelContext,
        provider: AIProviderType = .googleAccount,
        apiKey: String = "",
        ninerouterBaseUrl: String = "https://api.ninerouter.com/v1",
        ninerouterModel: String = "deepseek/deepseek-chat"
    ) async {
        let normalized = VoiceInputManager.normalizeSpokenText(userText)
        let trimmed = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMsg = MCPAIChatMessage(role: .user, content: trimmed)
        messages.append(userMsg)
        isProcessing = true
        HapticManager.shared.impact(style: .light)

        // 1. MCP Action Interceptor (Prioritas Utama: Tambah Tugas & Aksi Lokal SwiftData)
        if await handleMCPAppActionIntents(prompt: trimmed, modelContext: modelContext) {
            isProcessing = false
            return
        }

        // 2. Jika Bukan Action App Sederhana, Jalankan Provider AI dengan Live Context Injection
        let cleanApiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        switch provider {
        case .googleAccount:
            await processWithGoogleUserAccount(prompt: trimmed, modelContext: modelContext)

        case .gemini:
            if !cleanApiKey.isEmpty {
                await processWithGeminiLLM(prompt: trimmed, apiKey: cleanApiKey, modelContext: modelContext)
            } else {
                await processWithLocalDiscussion(prompt: trimmed, modelContext: modelContext, missingKeyPrompt: "API Key belum dimasukkan di pengaturan.")
            }

        case .ninerouter:
            if !cleanApiKey.isEmpty {
                await processWithNinerouter(
                    prompt: trimmed,
                    apiKey: cleanApiKey,
                    baseUrl: ninerouterBaseUrl,
                    modelName: ninerouterModel,
                    modelContext: modelContext
                )
            } else {
                await processWithLocalDiscussion(prompt: trimmed, modelContext: modelContext, missingKeyPrompt: "Ninerouter API Key belum dimasukkan.")
            }

        case .local:
            await processWithLocalDiscussion(prompt: trimmed, modelContext: modelContext)
        }

        isProcessing = false
    }

    /// Bersihkan riwayat percakapan chat
    func clearMessages() {
        messages.removeAll()
        pendingProposal = nil
        messages.append(
            MCPAIChatMessage(
                role: .assistant,
                content: "Percakapan baru telah dimulai! Apa tugas atau target yang ingin kita kelola di aplikasi? 🚀"
            )
        )
    }

    /// Konfirmasi langsung dari tombol kartu di chat UI
    func confirmProposalDirectly(modelContext: ModelContext) async {
        guard let proposal = pendingProposal else { return }
        await executeSaveProposalTool(proposal: proposal, modelContext: modelContext)
        pendingProposal = nil
    }

    // MARK: - 📊 MCP Live Context Generator
    private func buildMCPLiveContext(modelContext: ModelContext) -> String {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        let pendingItems = items.filter { !$0.isCompleted }
        let completedItems = items.filter { $0.isCompleted }

        let habitDesc = FetchDescriptor<Habit>()
        let habits = (try? modelContext.fetch(habitDesc)) ?? []

        let pomodoro = PomodoroManager.shared
        let health = HealthKitManager.shared.todaySummary
        let isShieldActive = ScreenTimeManager.shared.isShieldActive

        let context = """
        [MCP_APP_LOCAL_DATABASE_CONTEXT]
        - Status Tugas Aplikasi: \(pendingItems.count) tugas aktif, \(completedItems.count) tugas selesai.
        - Daftar Tugas Aktif: \(pendingItems.prefix(5).map { $0.title }.joined(separator: ", "))
        - Total Habit Aktif: \(habits.count) habit (\(habits.prefix(3).map { "\($0.title) (streak: \($0.currentStreak)d)" }.joined(separator: ", ")))
        - Pomodoro Timer: \(pomodoro.isRunning ? "Sedang aktif (\(pomodoro.remainingSeconds / 60)m tersisa)" : "Standby")
        - Apple Health: \(health.steps) langkah, \(Int(health.activeCalories)) kkal
        - Screen Time Shield: \(isShieldActive ? "Aktif (Aplikasi Terkunci)" : "Nonaktif")
        """
        return context
    }

    // MARK: - 🛠️ MCP Intent Interceptor
    private func handleMCPAppActionIntents(prompt: String, modelContext: ModelContext) async -> Bool {
        let lower = prompt.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // A. Konfirmasi Proposal Aktif
        if let proposal = pendingProposal {
            let confirmKeywords = ["oke", "ok", "ya", "yes", "setuju", "buat sekarang", "jadwalkan", "buatkan", "siap", "gas", "bikin", "masukkan", "save", "simpan"]
            if confirmKeywords.contains(where: { lower.contains($0) }) {
                await executeSaveProposalTool(proposal: proposal, modelContext: modelContext)
                pendingProposal = nil
                return true
            } else if lower.contains("batal") || lower.contains("jangan") || lower.contains("cancel") {
                pendingProposal = nil
                await streamAssistantMessage(fullContent: "Rencana dibatalkan 👍. Mau kita bahas tugas lain?")
                return true
            }
        }

        // B. Daily AI Coach: Morning Briefing & Evening Review
        if lower.contains("briefing") || lower.contains("rencana hari ini") || lower.contains("susun jadwal") || lower.contains("morning briefing") || lower.contains("rencana pagi") {
            await executeMorningBriefingTool(modelContext: modelContext)
            return true
        }
        if lower.contains("evaluasi") || lower.contains("review hari ini") || lower.contains("evening review") || lower.contains("review malam") || lower.contains("laporan hari ini") {
            await executeEveningReviewTool(modelContext: modelContext)
            return true
        }

        // C. Intent Tambah / Buat Tugas Langsung (Dengan Natural Time Parser)
        let isTaskCreationIntent =
            lower.contains("tambah tugas") || lower.contains("tambahkan tugas") ||
            lower.contains("tambah task") || lower.contains("tambahkan task") ||
            lower.contains("buat tugas") || lower.contains("buatkan tugas") ||
            lower.contains("bikin tugas") || lower.contains("bikinkan tugas") ||
            lower.contains("masukkan tugas") || lower.contains("input tugas") ||
            lower.contains("jadwalkan tugas") || lower.contains("catat tugas") ||
            lower.contains("add task") || lower.contains("create task") ||
            lower.contains("new task") || lower.contains("to-do") || lower.contains("todo") ||
            lower.hasPrefix("tambah ") || lower.hasPrefix("tambahkan ") ||
            lower.hasPrefix("buat ") || lower.hasPrefix("buatkan ") ||
            lower.hasPrefix("bikin ") || lower.hasPrefix("bikinkan ") ||
            lower.hasPrefix("masukkan ") || lower.hasPrefix("jadwalkan ") ||
            lower.hasPrefix("catat ") || lower.hasPrefix("ingatkan ") ||
            lower.hasPrefix("add ") || lower.hasPrefix("create ")

        let isHabitIntent = lower.contains("habit") || lower.contains("kebiasaan")
        let isPomodoroIntent = lower.contains("pomodoro") || lower.contains("fokus")

        if isTaskCreationIntent && !isHabitIntent && !isPomodoroIntent {
            await executeDirectCreateTaskTool(prompt: prompt, modelContext: modelContext)
            return true
        }

        // D. Pomodoro / Timer Fokus
        if lower.contains("mulai pomodoro") || lower.contains("mulai fokus") || lower.contains("fokus 25") || lower.contains("fokus 50") || lower.contains("start timer") {
            await executeStartPomodoroTool(prompt: prompt)
            return true
        }
        if lower.contains("stop pomodoro") || lower.contains("hentikan pomodoro") || lower.contains("stop timer") {
            await executeStopPomodoroTool()
            return true
        }
        if lower.contains("status pomodoro") || lower.contains("sisa waktu fokus") {
            await executeGetFocusStatusTool()
            return true
        }

        // E. HealthKit & Screen Time
        if lower.contains("langkah") || lower.contains("kalori") || lower.contains("tidur") || lower.contains("kesehatan") {
            await executeGetHealthStatsTool()
            return true
        }
        if lower.contains("kunci aplikasi") || lower.contains("aktifkan shield") || lower.contains("blokir aplikasi") || lower.contains("matikan shield") {
            await executeToggleAppShieldTool(prompt: prompt)
            return true
        }

        // F. Habit Tracker
        if lower.contains("ceklis habit") || lower.contains("log habit") || lower.contains("sudah baca") || lower.contains("sudah olahraga") {
            await executeLogHabitCheckInTool(prompt: prompt, modelContext: modelContext)
            return true
        }
        if lower.contains("buat habit") || lower.contains("kebiasaan baru") {
            await executeCreateHabitTool(prompt: prompt, modelContext: modelContext)
            return true
        }
        if lower.contains("daftar habit") || lower.contains("lihat habit") {
            await executeListHabitsTool(modelContext: modelContext)
            return true
        }

        // G. Task Management List & Complete
        if lower.contains("selesaikan tugas") || lower.contains("tandai selesai") {
            await executeCompleteActivityTool(prompt: prompt, modelContext: modelContext)
            return true
        }
        if lower.contains("daftar tugas") || lower.contains("lihat tugas") || lower.contains("tugas penting") {
            await executeListActivitiesTool(prompt: prompt, modelContext: modelContext)
            return true
        }
        if lower.contains("bersihkan selesai") {
            await executeClearCompletedActivitiesTool(modelContext: modelContext)
            return true
        }

        // H. Rangkuman Lengkap
        if lower.contains("rangkum") || lower.contains("status hari ini") || lower.contains("ringkasan produktivitas") || lower.contains("progress hari ini") {
            await executeGetAppSummaryTool(modelContext: modelContext)
            return true
        }

        return false
    }

    // MARK: - 🌅 Daily AI Coach: Morning Briefing Tool
    private func executeMorningBriefingTool(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        let pending = items.filter { !$0.isCompleted }
        let highPriority = pending.filter { $0.priority == "Tinggi" }

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
        🌅 **Selamat Pagi! Berikut Rencana Fokus Hari Ini:**

        🎯 **Tugas Prioritas (\(pending.count) Tertunda):**\(taskSection)

        🔥 **Target Habit Hari Ini:**
        \(habitSection)

        🏃‍♂️ **Kondisi Fisik:** \(health.steps) langkah | Tidur: \(health.sleepFormatted)

        💡 **Rekomendasi AI Coach:**
        Mulai pagi ini dengan 1 sesi Pomodoro 25 menit untuk tugas **"\(highPriority.first?.title ?? pending.first?.title ?? "Fokus Pertama")"**! Siap mulai? 🚀
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Morning briefing ready")
    }

    // MARK: - 🌙 Daily AI Coach: Evening Review Tool
    private func executeEveningReviewTool(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        let completedToday = items.filter { $0.isCompleted }
        let remaining = items.filter { !$0.isCompleted }

        let habitDesc = FetchDescriptor<Habit>()
        let habits = (try? modelContext.fetch(habitDesc)) ?? []
        let completedHabits = habits.filter { $0.isCompletedToday }

        let health = HealthKitManager.shared.todaySummary

        let toolCall = MCPToolInvocation(
            name: "evening_review",
            argumentsSummary: "completed: \(completedToday.count), habits: \(completedHabits.count)/\(habits.count)",
            icon: "moon.stars.fill",
            badgeColorHex: "#C084FC"
        )

        let reply = """
        🌙 **Evaluasi & Rangkuman Hari Ini:**

        🎉 **Pencapaian Hebat:**
        • ✅ **\(completedToday.count) Tugas Selesai** hari ini
        • 🔥 **\(completedHabits.count) dari \(habits.count) Target Habit** berhasil kamu jaga streak-nya
        • 🏃‍♂️ **\(health.steps) Langkah** (\(Int(health.activeCalories)) kkal) tercatat

        \(remaining.isEmpty ? "🌟 Luar biasa! Seluruh daftar tugasmu hari ini bersih tuntas!" : "⏳ Masih ada **\(remaining.count) tugas tersisa** yang siap kita lanjutkan esok hari.")

        Kerja kerasmu hari ini sangat membanggakan! Selamat beristirahat agar besok bangun dengan energi maksimal! 💤✨
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Evening review completed")
    }

    // MARK: - 📝 Eksekusi Tambah Tugas Langsung ke Database SwiftData (Dengan Natural Time Parser)
    private func executeDirectCreateTaskTool(prompt: String, modelContext: ModelContext) async {
        var cleanTitle = prompt
        let removeKeywords = [
            "tambahkan tugas", "tambah tugas", "tambahkan task", "tambah task",
            "buatkan tugas", "buat tugas", "bikin tugas", "bikinkan tugas",
            "masukkan tugas", "input tugas", "jadwalkan tugas", "catat tugas",
            "tambahkan to-do", "tambah to-do", "buat to-do", "bikin to-do",
            "tambahkan todo", "tambah todo", "buat todo", "bikin todo",
            "tolong", "bisa", "dong", "ya", "add task", "create task",
            "tambahkan", "tambah", "buatkan", "buat", "bikin", "bikinkan",
            "masukkan", "jadwalkan", "catatkan", "catat", "ingatkan",
            "ke to-do list", "ke daftar tugas", "ke app", "ke aplikasi", "di app", "di aplikasi"
        ]
        for kw in removeKeywords {
            cleanTitle = cleanTitle.replacingOccurrences(of: kw, with: "", options: .caseInsensitive)
        }

        // ⏰ 1. Jalankan Smart Natural Date & Time Parser
        let parsedSchedule = NaturalTimeParser.parse(from: cleanTitle)
        cleanTitle = parsedSchedule.cleanText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ":,.- ")))
        if cleanTitle.isEmpty { cleanTitle = "Tugas Produktivitas Baru" }

        var category = "Pekerjaan"
        if prompt.localizedCaseInsensitiveContains("coding") || prompt.localizedCaseInsensitiveContains("swift") || prompt.localizedCaseInsensitiveContains("app") || prompt.localizedCaseInsensitiveContains("bug") || prompt.localizedCaseInsensitiveContains("kode") {
            category = "Coding"
        } else if prompt.localizedCaseInsensitiveContains("belajar") || prompt.localizedCaseInsensitiveContains("kuliah") || prompt.localizedCaseInsensitiveContains("buku") || prompt.localizedCaseInsensitiveContains("ujian") || prompt.localizedCaseInsensitiveContains("materi") {
            category = "Belajar"
        } else if prompt.localizedCaseInsensitiveContains("olahraga") || prompt.localizedCaseInsensitiveContains("gym") || prompt.localizedCaseInsensitiveContains("lari") || prompt.localizedCaseInsensitiveContains("workout") {
            category = "Kesehatan"
        } else if prompt.localizedCaseInsensitiveContains("belanja") || prompt.localizedCaseInsensitiveContains("beli") || prompt.localizedCaseInsensitiveContains("shopping") {
            category = "Belanja"
        } else if prompt.localizedCaseInsensitiveContains("meeting") || prompt.localizedCaseInsensitiveContains("rapat") || prompt.localizedCaseInsensitiveContains("diskusi") {
            category = "Meeting"
        } else if prompt.localizedCaseInsensitiveContains("ibadah") || prompt.localizedCaseInsensitiveContains("doa") || prompt.localizedCaseInsensitiveContains("sholat") {
            category = "Ibadah"
        } else if prompt.localizedCaseInsensitiveContains("keuangan") || prompt.localizedCaseInsensitiveContains("uang") || prompt.localizedCaseInsensitiveContains("bayar") || prompt.localizedCaseInsensitiveContains("tagihan") {
            category = "Keuangan"
        }

        var priority = "Sedang"
        if prompt.localizedCaseInsensitiveContains("penting") || prompt.localizedCaseInsensitiveContains("tinggi") || prompt.localizedCaseInsensitiveContains("darurat") || prompt.localizedCaseInsensitiveContains("urgent") || prompt.localizedCaseInsensitiveContains("segera") {
            priority = "Tinggi"
        } else if prompt.localizedCaseInsensitiveContains("santai") || prompt.localizedCaseInsensitiveContains("rendah") || prompt.localizedCaseInsensitiveContains("kapan-kapan") {
            priority = "Rendah"
        }

        let suggestions = SmartTaskBreakdownService.shared.generateSuggestions(for: cleanTitle, category: category)
        let subtasks = Array(suggestions.prefix(4)).map { SubtaskItem(title: $0, isCompleted: false) }

        let newItem = Item(
            title: cleanTitle.capitalized,
            notes: "Ditambahkan otomatis oleh AI Assistant ke dalam aplikasi",
            timestamp: parsedSchedule.targetDate,
            isCompleted: false,
            completedAt: nil,
            priority: priority,
            category: category,
            isRecurring: false,
            recurrenceRule: "Sekali Saja",
            customSoundName: nil,
            subtasks: subtasks,
            imageAttachmentData: nil
        )

        modelContext.insert(newItem)
        try? modelContext.save()
        lastCreatedItem = newItem

        // Otomatis jadwalkan notifikasi lokal jika memiliki waktu eksplisit
        if parsedSchedule.hasExplicitTime {
            await NotificationManager.shared.scheduleNotification(for: newItem)
        }

        HapticManager.shared.success()
        SoundManager.shared.playSuccessChime()

        let toolCall = MCPToolInvocation(
            name: "create_activity",
            argumentsSummary: "title: \"\(newItem.title)\", time: \"\(parsedSchedule.formattedScheduleDescription)\"",
            icon: "checkmark.seal.fill",
            badgeColorHex: "#6EE7B7"
        )

        var subtasksListStr = ""
        for (i, step) in subtasks.enumerated() {
            subtasksListStr += "\n\(i + 1). 🔹 **\(step.title)**"
        }

        let scheduleInfo = parsedSchedule.hasExplicitTime ? "\n⏰ **Jadwal Pengingat:** \(parsedSchedule.formattedScheduleDescription)" : ""

        let reply = """
        🎉 **Tugas Berhasil Ditambahkan ke Aplikasi!**

        🎯 **\(newItem.title)**\(scheduleInfo)
        📁 Kategori: *\(newItem.category)* | ⚡ Prioritas: *\(newItem.priority)*

        📋 **Subtasks Otomatis Disiapkan:**\(subtasksListStr)

        Tugas ini sudah tersimpan langsung di Beranda to-do list aplikasimu! Mau langsung mulai fokus dengan Pomodoro timer? ⏱️
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Saved")
    }

    // MARK: - 🌐 Cloud AI Background Bridge Execution
    private func processWithGoogleUserAccount(prompt: String, modelContext: ModelContext) async {
        let liveContext = buildMCPLiveContext(modelContext: modelContext)
        let systemGuard = """
        [INSTRUKSI SISTEM APLIKASI IOS]:
        Kamu adalah asisten AI internal untuk aplikasi to-do list lokal ini.
        PENTING & WAJIB:
        1. JANGAN PERNAH menyarankan atau menyebut Google Tasks, Google Calendar, Google Keep, atau layanan pihak ketiga.
        2. Semua tugas dan jadwal langsung disimpan di database lokal aplikasi ini (SwiftData).
        3. Konteks aplikasi saat ini: \(liveContext)
        """
        let enrichedPrompt = "\(systemGuard)\n\nPesan Pengguna:\n\(prompt)"

        do {
            let rawReply = try await GeminiBackgroundBridgeManager.shared.sendPromptToGeminiWeb(enrichedPrompt)
            let sanitizedReply = sanitizeLLMResponse(rawReply)
            await dispatchActionOrDisplayLLMResponse(llmText: sanitizedReply, prompt: prompt, modelContext: modelContext)
        } catch {
            await processWithLocalDiscussion(
                prompt: prompt,
                modelContext: modelContext
            )
        }
    }

    // MARK: - 💬 Interactive Discussion & Co-Planning Dialogue Engine
    private func processWithLocalDiscussion(
        prompt: String,
        modelContext: ModelContext,
        missingKeyPrompt: String? = nil
    ) async {
        try? await Task.sleep(nanoseconds: 200_000_000)
        let lower = prompt.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Sapaan Ramah
        if lower == "halo" || lower == "hai" || lower == "hi" || lower == "hey" || lower.hasPrefix("halo") || lower.hasPrefix("hai ") {
            let reply = "Halo! Senang bisa mendampingimu! Ada rencana, tugas, atau target baru yang ingin kita susun di aplikasi hari ini? 😊"
            await streamAssistantMessage(fullContent: reply)
            return
        }

        // Permintaan Rencana / Jadwal
        if lower.contains("jadwal") || lower.contains("rencana") || lower.contains("bantu bikin") || lower.contains("mau ngerjain") || lower.contains("mau belajar") {
            await handlePlanningDiscussion(prompt: prompt)
            return
        }

        var extraNote = ""
        if let missing = missingKeyPrompt {
            extraNote = "\n\n*(Catatan: \(missing))*"
        }

        let reply = """
        Menarik! Terkait *"\(prompt)"*, apa ada tugas spesifik yang ingin kamu tambahkan langsung ke daftar tugas aplikasi? 

        💡 Kamu bisa ketik *"Tambahkan tugas \(prompt)"* agar langsung tersimpan di aplikasimu!\(extraNote)
        """
        await streamAssistantMessage(fullContent: reply)
    }

    // MARK: - 🧠 Co-Planning Discussion Handler
    private func handlePlanningDiscussion(prompt: String) async {
        var cleanTitle = prompt
        let removeKeywords = ["buatkan aku jadwal", "buatkan jadwal", "jadwalkan", "bantu rencanakan", "buat tugas", "mau belajar", "mau ngerjain", "bantu bikin"]
        for kw in removeKeywords {
            cleanTitle = cleanTitle.replacingOccurrences(of: kw, with: "", options: .caseInsensitive)
        }

        let parsedSchedule = NaturalTimeParser.parse(from: cleanTitle)
        cleanTitle = parsedSchedule.cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanTitle.isEmpty { cleanTitle = "Pekerjaan Produktif" }

        var category = "Pekerjaan"
        if prompt.localizedCaseInsensitiveContains("coding") || prompt.localizedCaseInsensitiveContains("swift") || prompt.localizedCaseInsensitiveContains("app") || prompt.localizedCaseInsensitiveContains("bug") {
            category = "Coding"
        } else if prompt.localizedCaseInsensitiveContains("belajar") || prompt.localizedCaseInsensitiveContains("kuliah") || prompt.localizedCaseInsensitiveContains("buku") || prompt.localizedCaseInsensitiveContains("ujian") {
            category = "Belajar"
        } else if prompt.localizedCaseInsensitiveContains("olahraga") || prompt.localizedCaseInsensitiveContains("gym") || prompt.localizedCaseInsensitiveContains("lari") {
            category = "Kesehatan"
        } else if prompt.localizedCaseInsensitiveContains("belanja") || prompt.localizedCaseInsensitiveContains("beli") {
            category = "Belanja"
        }

        let suggestions = SmartTaskBreakdownService.shared.generateSuggestions(for: cleanTitle, category: category)
        let proposal = TaskProposal(
            title: cleanTitle.capitalized,
            category: category,
            priority: "Tinggi",
            subtasks: Array(suggestions.prefix(4)),
            estimatedMinutes: 60,
            scheduledDate: parsedSchedule.targetDate,
            scheduledDescription: parsedSchedule.hasExplicitTime ? parsedSchedule.formattedScheduleDescription : nil
        )
        self.pendingProposal = proposal

        var subtasksListStr = ""
        for (i, step) in proposal.subtasks.enumerated() {
            subtasksListStr += "\n\(i + 1). 🔹 **\(step)**"
        }

        let scheduleRow = proposal.scheduledDescription != nil ? "\n⏰ **Waktu:** \(proposal.scheduledDescription!)" : ""

        let reply = """
        Bagus sekali! Untuk **\(proposal.title)**, mari kita bedah menjadi subtasks yang jelas agar lebih mudah dikerjakan:

        📋 **Rekomendasi Langkah / Subtasks:**\(subtasksListStr)\(scheduleRow)

        🏷️ **Kategori:** *\(proposal.category)*  
        ⚡ **Prioritas:** *\(proposal.priority)*  
        ⏱️ **Estimasi:** ~\(proposal.estimatedMinutes) menit

        Balas **"Oke, jadwalkan"** untuk langsung menyimpannya ke to-do list aplikasi!
        """

        await streamAssistantMessage(fullContent: reply, proposal: proposal)
    }

    private func executeSaveProposalTool(proposal: TaskProposal, modelContext: ModelContext) async {
        let subtasks = proposal.subtasks.map { SubtaskItem(title: $0, isCompleted: false) }
        let newItem = Item(
            title: proposal.title,
            notes: "Direncanakan & didiskusikan bersama AI Productivity Partner via MCP",
            timestamp: proposal.scheduledDate ?? Date(),
            isCompleted: false,
            completedAt: nil,
            priority: proposal.priority,
            category: proposal.category,
            isRecurring: false,
            recurrenceRule: "Sekali Saja",
            customSoundName: nil,
            subtasks: subtasks,
            imageAttachmentData: nil
        )

        modelContext.insert(newItem)
        try? modelContext.save()
        lastCreatedItem = newItem

        if proposal.scheduledDescription != nil {
            await NotificationManager.shared.scheduleNotification(for: newItem)
        }

        HapticManager.shared.success()
        SoundManager.shared.playSuccessChime()

        let toolCall = MCPToolInvocation(
            name: "create_activity",
            argumentsSummary: "title: \"\(newItem.title)\", subtasks: \(subtasks.count)",
            icon: "checkmark.seal.fill",
            badgeColorHex: "#6EE7B7"
        )

        let reply = """
        🎉 **Jadwal Berhasil Disimpan ke Daftar Tugas Aplikasi!**

        🎯 **\(newItem.title)**
        📁 Kategori: *\(newItem.category)* | ⚡ Prioritas: *\(newItem.priority)*
        📋 **\(subtasks.count) Subtasks** siap kamu eksekusi di Beranda.
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Saved")
    }

    // MARK: - 🌐 Developer API Key LLM
    private func processWithGeminiLLM(prompt: String, apiKey: String, modelContext: ModelContext) async {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)") else {
            await processWithLocalDiscussion(prompt: prompt, modelContext: modelContext)
            return
        }

        let liveContext = buildMCPLiveContext(modelContext: modelContext)

        var contentsPayload: [[String: Any]] = []
        let recentMessages = messages.suffix(10)
        for msg in recentMessages {
            let role = (msg.role == .user) ? "user" : "model"
            contentsPayload.append([
                "role": role,
                "parts": [["text": msg.content]]
            ])
        }

        let systemInstruction: [String: Any] = [
            "parts": [
                [
                    "text": "Kamu adalah AI Productivity Partner internal aplikasi iOS. DILARANG menyebut Google Tasks atau layanan eksternal. Semua tugas disimpan langsung ke database lokal aplikasi ini via MCP. Konteks aplikasi saat ini: \(liveContext). Format jawaban rapi dengan list kartu."
                ]
            ]
        ]

        let requestBody: [String: Any] = [
            "contents": contentsPayload,
            "system_instruction": systemInstruction
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            await processWithLocalDiscussion(prompt: prompt, modelContext: modelContext)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 25

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {

                let sanitized = sanitizeLLMResponse(text)
                await dispatchActionOrDisplayLLMResponse(llmText: sanitized, prompt: prompt, modelContext: modelContext)
                return
            }

            await processWithLocalDiscussion(prompt: prompt, modelContext: modelContext)
        } catch {
            await processWithLocalDiscussion(prompt: prompt, modelContext: modelContext)
        }
    }

    // MARK: - ⚡ Ninerouter Multi-LLM Gateway
    private func processWithNinerouter(
        prompt: String,
        apiKey: String,
        baseUrl: String,
        modelName: String,
        modelContext: ModelContext
    ) async {
        let endpoint = baseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/chat/completions"
        guard let url = URL(string: endpoint) else {
            await processWithLocalDiscussion(prompt: prompt, modelContext: modelContext)
            return
        }

        let liveContext = buildMCPLiveContext(modelContext: modelContext)

        var messagesPayload: [[String: String]] = [
            [
                "role": "system",
                "content": "Kamu adalah AI Productivity Partner internal aplikasi iOS. DILARANG menyebut Google Tasks atau layanan eksternal. Semua tugas disimpan langsung ke database lokal aplikasi ini via MCP. Konteks aplikasi saat ini: \(liveContext). Format jawaban rapi dengan list kartu."
            ]
        ]

        let recentMessages = messages.suffix(8)
        for msg in recentMessages {
            let roleStr = (msg.role == .user) ? "user" : "assistant"
            messagesPayload.append(["role": roleStr, "content": msg.content])
        }

        let requestBody: [String: Any] = [
            "model": modelName.isEmpty ? "deepseek/deepseek-chat" : modelName,
            "messages": messagesPayload,
            "temperature": 0.7
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            await processWithLocalDiscussion(prompt: prompt, modelContext: modelContext)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 25

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let messageObj = firstChoice["message"] as? [String: Any],
               let text = messageObj["content"] as? String {

                let sanitized = sanitizeLLMResponse(text)
                await dispatchActionOrDisplayLLMResponse(llmText: sanitized, prompt: prompt, modelContext: modelContext)
                return
            }

            await processWithLocalDiscussion(prompt: prompt, modelContext: modelContext)
        } catch {
            await processWithLocalDiscussion(prompt: prompt, modelContext: modelContext)
        }
    }

    private func sanitizeLLMResponse(_ text: String) -> String {
        var clean = text
        clean = clean.replacingOccurrences(of: "Google Tasks", with: "To-Do List aplikasi", options: .caseInsensitive)
        clean = clean.replacingOccurrences(of: "Google Calendar", with: "Jadwal aplikasi", options: .caseInsensitive)
        clean = clean.replacingOccurrences(of: "Google Keep", with: "Catatan aplikasi", options: .caseInsensitive)
        return clean
    }

    private func dispatchActionOrDisplayLLMResponse(llmText: String, prompt: String, modelContext: ModelContext) async {
        let lines = llmText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.hasPrefix("1.") || $0.hasPrefix("2.") || $0.hasPrefix("3.") || $0.hasPrefix("4.") || $0.hasPrefix("-") || $0.hasPrefix("•") }

        var detectedProposal: TaskProposal? = nil
        if lines.count >= 2 {
            let cleanSubtasks = lines.prefix(4).map { $0.replacingOccurrences(of: "^[0-9]+[.\\s-*•]+", with: "", options: .regularExpression) }
            detectedProposal = TaskProposal(
                title: "Rencana Produktivitas",
                category: "Pekerjaan",
                priority: "Tinggi",
                subtasks: Array(cleanSubtasks),
                estimatedMinutes: 45
            )
            self.pendingProposal = detectedProposal
        }

        await streamAssistantMessage(fullContent: llmText, proposal: detectedProposal)
    }

    // MARK: - 🛠️ MCP Tools Implementations
    private func executeCompleteActivityTool(prompt: String, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        let pendingItems = items.filter { !$0.isCompleted }

        var targetItem: Item? = nil
        let cleanedPrompt = prompt.lowercased()
        for item in pendingItems {
            if cleanedPrompt.contains(item.title.lowercased()) {
                targetItem = item
                break
            }
        }
        if targetItem == nil { targetItem = pendingItems.first }

        guard let itemToComplete = targetItem else {
            await streamAssistantMessage(fullContent: "ℹ️ Tidak ditemukan tugas tertunda yang cocok untuk diselesaikan.")
            return
        }

        itemToComplete.isCompleted = true
        itemToComplete.completedAt = Date()
        try? modelContext.save()

        HapticManager.shared.success()
        SoundManager.shared.playSuccessChime()

        let toolCall = MCPToolInvocation(
            name: "complete_activity",
            argumentsSummary: "title: \"\(itemToComplete.title)\"",
            icon: "checkmark.circle.fill",
            badgeColorHex: "#6EE7B7"
        )

        let reply = "🎉 **Tugas Selesai!**\n\n✅ **\(itemToComplete.title)** telah ditandai selesai dan dicatat ke riwayat."
        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Task completed")
    }

    private func executeListActivitiesTool(prompt: String, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        let lower = prompt.lowercased()

        let listToDisplay: [Item]
        let listTitle: String

        if lower.contains("selesai") {
            listToDisplay = items.filter { $0.isCompleted }
            listTitle = "Daftar Tugas Selesai"
        } else if lower.contains("penting") || lower.contains("tinggi") {
            listToDisplay = items.filter { !$0.isCompleted && $0.priority == "Tinggi" }
            listTitle = "Daftar Tugas Prioritas Tinggi"
        } else {
            listToDisplay = items.filter { !$0.isCompleted }
            listTitle = "Daftar Tugas Aktif"
        }

        let toolCall = MCPToolInvocation(
            name: "list_activities",
            argumentsSummary: "count: \(listToDisplay.count)",
            icon: "list.bullet.rectangle.portrait",
            badgeColorHex: "#FDE047"
        )

        if listToDisplay.isEmpty {
            await streamAssistantMessage(fullContent: "Tidak ada tugas yang ditemukan untuk kategori tersebut 👍", toolCall: toolCall, toolResult: "0 items")
            return
        }

        var listStr = "📋 **\(listTitle) (\(listToDisplay.count)):**\n"
        for (index, item) in listToDisplay.prefix(6).enumerated() {
            let priorityIcon = item.priority == "Tinggi" ? "🔥" : (item.priority == "Rendah" ? "🌱" : "⚡")
            listStr += "\n\(index + 1). \(priorityIcon) **\(item.title)** [\(item.category)]"
            if !item.subtasks.isEmpty {
                let completedSub = item.subtasks.filter { $0.isCompleted }.count
                listStr += " (\(completedSub)/\(item.subtasks.count) subtasks)"
            }
        }

        await streamAssistantMessage(fullContent: listStr, toolCall: toolCall, toolResult: "\(listToDisplay.count) items retrieved")
    }

    private func executeClearCompletedActivitiesTool(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        let completedItems = items.filter { $0.isCompleted }

        guard !completedItems.isEmpty else {
            await streamAssistantMessage(fullContent: "Tidak ada tugas selesai yang perlu dibersihkan 👍")
            return
        }

        for item in completedItems {
            modelContext.delete(item)
        }
        try? modelContext.save()

        HapticManager.shared.success()
        SoundManager.shared.playDeleteSound()

        let toolCall = MCPToolInvocation(
            name: "clear_completed_activities",
            argumentsSummary: "deleted: \(completedItems.count)",
            icon: "trash.fill",
            badgeColorHex: "#FCA5A5"
        )

        let reply = "🧹 **Pembersihan Berhasil!**\n\nSebanyak **\(completedItems.count) tugas selesai** telah dibersihkan dari penyimpanan aplikasi."
        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "\(completedItems.count) cleared")
    }

    private func executeStartPomodoroTool(prompt: String) async {
        let pomodoro = PomodoroManager.shared
        if prompt.contains("50") {
            pomodoro.selectPreset(.deepFocus)
        } else if prompt.contains("15") {
            pomodoro.selectPreset(.longBreak)
        } else if prompt.contains("5") && !prompt.contains("25") && !prompt.contains("50") {
            pomodoro.selectPreset(.shortBreak)
        } else {
            pomodoro.selectPreset(.quickFocus)
        }

        pomodoro.startTimer()

        let toolCall = MCPToolInvocation(
            name: "start_pomodoro",
            argumentsSummary: "preset: \(pomodoro.selectedPreset.rawValue)",
            icon: "timer",
            badgeColorHex: "#F87171"
        )

        let reply = """
        ⏱️ **Timer Fokus Dimulai!**

        Mode: **\(pomodoro.selectedPreset.rawValue)**  
        Live Activity Dynamic Island telah aktif di layar kunci & status bar! 🎯
        """
        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Started")
    }

    private func executeStopPomodoroTool() async {
        PomodoroManager.shared.resetTimer()
        HapticManager.shared.impact(style: .medium)

        let toolCall = MCPToolInvocation(
            name: "stop_pomodoro",
            argumentsSummary: "status: reset",
            icon: "stop.circle.fill",
            badgeColorHex: "#F87171"
        )

        await streamAssistantMessage(fullContent: "⏹️ Sesi Pomodoro telah dihentikan. Selamat beristirahat sejenak! ☕", toolCall: toolCall, toolResult: "Reset")
    }

    private func executeGetFocusStatusTool() async {
        let pomodoro = PomodoroManager.shared
        let toolCall = MCPToolInvocation(
            name: "get_focus_status",
            argumentsSummary: "running: \(pomodoro.isRunning)",
            icon: "timer",
            badgeColorHex: "#60A5FA"
        )

        if pomodoro.isRunning {
            let minutes = pomodoro.remainingSeconds / 60
            let seconds = pomodoro.remainingSeconds % 60
            let reply = "⏳ **Status Pomodoro Aktif!**\n\nSisa waktu fokus: **\(minutes) menit \(seconds) detik** (\(pomodoro.selectedPreset.rawValue)). Tetap semangat!"
            await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "\(pomodoro.remainingSeconds)s remaining")
        } else {
            await streamAssistantMessage(fullContent: "Timer fokus sedang standby 💤. Mau mulai sesi 25 menit sekarang?", toolCall: toolCall, toolResult: "Standby")
        }
    }

    private func executeGetHealthStatsTool() async {
        let health = HealthKitManager.shared.todaySummary
        let toolCall = MCPToolInvocation(
            name: "get_health_stats",
            argumentsSummary: "steps: \(health.steps), calories: \(Int(health.activeCalories))",
            icon: "heart.fill",
            badgeColorHex: "#F472B6"
        )

        let reply = """
        🏃‍♂️ **Ringkasan Apple Health Hari Ini:**

        • 👣 Langkah: **\(health.steps)** / 10.000 langkah
        • 🔥 Kalori Aktif: **\(Int(health.activeCalories))** kkal
        • 📏 Jarak Tempuh: **\(String(format: "%.2f", health.distanceKm))** km
        • 🌙 Tidur Semalam: **\(health.sleepFormatted)**

        Kesehatan fisik yang baik mendukung fokus dan produktivitas harianmu! 🍎
        """
        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "\(health.steps) steps")
    }

    private func executeToggleAppShieldTool(prompt: String) async {
        let lower = prompt.lowercased()
        let shouldActivate = !lower.contains("matikan") && !lower.contains("nonaktifkan") && !lower.contains("buka")

        ScreenTimeManager.shared.isShieldActive = shouldActivate
        HapticManager.shared.warning()

        let toolCall = MCPToolInvocation(
            name: "toggle_app_shield",
            argumentsSummary: "active: \(shouldActivate)",
            icon: "shield.fill",
            badgeColorHex: "#C084FC"
        )

        let reply = shouldActivate ?
            "🛡️ **Screen Time Shield Diaktifkan!**\nAplikasi distraksi (Instagram, TikTok, YouTube, Games) kini dibatasi agar kamu bisa fokus penuh." :
            "🔓 **Screen Time Shield Dinonaktifkan.**\nAkses ke aplikasi distraksi telah dibuka kembali."

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Shield set to \(shouldActivate)")
    }

    private func executeLogHabitCheckInTool(prompt: String, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Habit>()
        let habits = (try? modelContext.fetch(descriptor)) ?? []

        guard let targetHabit = habits.first(where: { prompt.localizedCaseInsensitiveContains($0.title) }) ?? habits.first else {
            await streamAssistantMessage(fullContent: "Belum ada kebiasaan/habit yang terdaftar di aplikasi untuk diceklis.")
            return
        }

        targetHabit.toggleCompletion(on: Date())
        try? modelContext.save()

        HapticManager.shared.success()
        SoundManager.shared.playSuccessChime()

        let toolCall = MCPToolInvocation(
            name: "log_habit_checkin",
            argumentsSummary: "habit: \"\(targetHabit.title)\", streak: \(targetHabit.currentStreak)d",
            icon: "flame.fill",
            badgeColorHex: "#FB923C"
        )

        let reply = "🔥 **Check-in Habit Berhasil!**\n\nKebiasaan **\(targetHabit.title)** telah diceklis hari ini. Streak kamu saat ini: **\(targetHabit.currentStreak) hari berturut-turut!** 🚀"
        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Streak \(targetHabit.currentStreak)")
    }

    private func executeCreateHabitTool(prompt: String, modelContext: ModelContext) async {
        var cleanTitle = prompt
        let removeKeywords = ["buat habit", "buatkan habit", "kebiasaan baru", "bikin habit", "tambah habit", "tolong", "bisa"]
        for kw in removeKeywords {
            cleanTitle = cleanTitle.replacingOccurrences(of: kw, with: "", options: .caseInsensitive)
        }
        cleanTitle = cleanTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanTitle.isEmpty { cleanTitle = "Kebiasaan Positif Baru" }

        let newHabit = Habit(
            title: cleanTitle.capitalized,
            icon: "flame.fill",
            colorHex: "#FFD166",
            category: .productivity,
            frequency: .daily
        )

        modelContext.insert(newHabit)
        try? modelContext.save()
        lastCreatedHabit = newHabit

        HapticManager.shared.success()
        SoundManager.shared.playSuccessChime()

        let toolCall = MCPToolInvocation(
            name: "create_habit",
            argumentsSummary: "title: \"\(newHabit.title)\"",
            icon: "plus.circle.fill",
            badgeColorHex: "#FB923C"
        )

        let reply = "🌟 **Habit Baru Terdaftar!**\n\nTarget **\(newHabit.title)** telah ditambahkan ke Habit Tracker aplikasi. Mulai bangun konsistensimu hari ini! 🏆"
        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Created")
    }

    private func executeListHabitsTool(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Habit>()
        let habits = (try? modelContext.fetch(descriptor)) ?? []

        let toolCall = MCPToolInvocation(
            name: "list_habits",
            argumentsSummary: "count: \(habits.count)",
            icon: "flame.fill",
            badgeColorHex: "#FB923C"
        )

        if habits.isEmpty {
            await streamAssistantMessage(fullContent: "Belum ada habit yang dibuat. Ketik *\"Buat habit membaca buku\"* untuk membuat target baru!", toolCall: toolCall, toolResult: "0 habits")
            return
        }

        var reply = "🔥 **Daftar Target Habit (\(habits.count)):**\n"
        for (i, h) in habits.enumerated() {
            let status = h.isCompletedToday ? "✅ Selesai hari ini" : "⏳ Belum diceklis"
            reply += "\n\(i + 1). **\(h.title)** (\(h.currentStreak) hari streak) - \(status)"
        }
        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "\(habits.count) habits")
    }

    private func executeGetAppSummaryTool(modelContext: ModelContext) async {
        let itemDesc = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(itemDesc)) ?? []
        let pending = items.filter { !$0.isCompleted }
        let completed = items.filter { $0.isCompleted }

        let habitDesc = FetchDescriptor<Habit>()
        let habits = (try? modelContext.fetch(habitDesc)) ?? []
        let completedHabits = habits.filter { $0.isCompletedToday }

        let health = HealthKitManager.shared.todaySummary

        let toolCall = MCPToolInvocation(
            name: "get_app_summary",
            argumentsSummary: "tasks: \(pending.count), habits: \(completedHabits.count)/\(habits.count)",
            icon: "chart.bar.fill",
            badgeColorHex: "#6EE7B7"
        )

        let reply = """
        📊 **Ringkasan Produktivitas & Kesehatan Hari Ini:**

        • 📋 **To-Do List:** \(pending.count) tugas aktif, \(completed.count) telah selesai
        • 🔥 **Habits:** \(completedHabits.count) dari \(habits.count) kebiasaan sudah diceklis
        • 👣 **Kesehatan:** \(health.steps) langkah kaki (\(Int(health.activeCalories)) kkal)
        • ⏱️ **Timer Fokus:** \(PomodoroManager.shared.isRunning ? "Sedang berjalan" : "Standby")

        Performa harianmu sangat solid! Mau menyelesaikan tugas prioritas berikutnya? 🚀
        """
        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Summary generated")
    }
}
