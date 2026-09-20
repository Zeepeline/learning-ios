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

// MARK: - 🤖 AI Provider Type
enum AIProviderType: String, CaseIterable, Identifiable, Codable {
    case googleAccount = "Google Account (Auto Session)"
    case gemini = "Gemini API (API Key)"
    case ninerouter = "Ninerouter Gateway (DeepSeek/Claude)"

    var id: String { rawValue }
}

// MARK: - 💬 Chat Message Model
struct AIMessage: Identifiable, Equatable {
    let id = UUID()
    let isUser: Bool
    var content: String
    let timestamp = Date()
    let toolCall: MCPToolInvocation?
    let toolResult: String?
    let proposal: AIActionProposal?
    var isStreaming: Bool = false

    static func == (lhs: AIMessage, rhs: AIMessage) -> Bool {
        lhs.id == rhs.id && lhs.content == rhs.content && lhs.isStreaming == rhs.isStreaming
    }
}

// MARK: - 🛠️ MCP Tool Call Invocation Metadata
struct MCPToolInvocation: Equatable {
    let name: String
    let argumentsSummary: String
    let icon: String
    let badgeColorHex: String
}

// MARK: - 💡 AI Action Proposal (Interactive Confirmation Card in Chat)
struct AIActionProposal: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let category: String
    let priority: String
    let actionType: ActionType
    var subtasks: [String] = []
    var targetDate: Date = Date()

    enum ActionType: Equatable {
        case createActivity
        case createHabit
        case startPomodoro(Int)
        case enableFocusLock
        case clearCompleted
    }
}

// MARK: - 🧠 Core MCP AI Assistant Service
@MainActor
final class MCPAIAssistantService: ObservableObject {
    static let shared = MCPAIAssistantService()

    @Published var messages: [AIMessage] = []
    @Published var isProcessing: Bool = false
    @Published var lastCreatedItem: Item? = nil

    private init() {
        setupWelcomeMessage()
    }

    private func setupWelcomeMessage() {
        if messages.isEmpty {
            messages.append(AIMessage(
                isUser: false,
                content: """
                Halo! 👋 Saya adalah **AI Assistant** pribadimu.

                Saya terhubung langsung dengan to-do list, habit tracker, pomodoro focus, screen time, kalender, dan health tracking aplikasimu via **Model Context Protocol (MCP)**.

                Ketik apa saja seperti:
                • *"🌅 Susun rencana hari ini (Morning Briefing)"*
                • *"🌙 Evaluasi hari ini (Evening Review)"*
                • *"Tambah tugas Coding SwiftUI besok jam 8 malam"*
                • *"Mulai fokus pomodoro 25 menit"*
                • *"Rangkum status aktivitas dan langkah kaki hari ini"*
                """,
                toolCall: nil,
                toolResult: nil,
                proposal: nil
            ))
        }
    }

    func clearMessages() {
        messages.removeAll()
        setupWelcomeMessage()
    }

    // MARK: - 🌊 Stream Token / Typewriter Effect
    private func streamAssistantMessage(
        fullContent: String,
        toolCall: MCPToolInvocation? = nil,
        toolResult: String? = nil,
        proposal: AIActionProposal? = nil
    ) async {
        let messageId = UUID()
        let initialMsg = AIMessage(
            isUser: false,
            content: "",
            toolCall: toolCall,
            toolResult: toolResult,
            proposal: proposal,
            isStreaming: true
        )
        self.messages.append(initialMsg)

        let words = fullContent.split(separator: " ", omittingEmptySubsequences: false)
        var currentText = ""

        for (index, word) in words.enumerated() {
            currentText += (index == 0 ? "" : " ") + String(word)

            if let idx = self.messages.firstIndex(where: { $0.id == initialMsg.id }) {
                self.messages[idx].content = currentText
            }

            // Micro delay per 1-2 words for smooth 60fps typewriter sensation
            if index % 2 == 0 {
                try? await Task.sleep(nanoseconds: 18_000_000)
            }
        }

        if let idx = self.messages.firstIndex(where: { $0.id == initialMsg.id }) {
            self.messages[idx].content = fullContent
            self.messages[idx].isStreaming = false
        }
    }

    // MARK: - 📤 Kirim Pesan & Jalankan MCP Tools
    func sendMessage(
        _ prompt: String,
        modelContext: ModelContext,
        provider: AIProviderType = .googleAccount,
        apiKey: String = "",
        ninerouterBaseUrl: String = "",
        ninerouterModel: String = ""
    ) async {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Tambahkan chat pengguna
        messages.append(AIMessage(
            isUser: true,
            content: trimmed,
            toolCall: nil,
            toolResult: nil,
            proposal: nil
        ))

        isProcessing = true
        defer { isProcessing = false }

        // 1. Eksekusi Cepat MCP Tool Lokal
        let lower = trimmed.lowercased()

        // 🌅 Morning Briefing
        if lower.contains("briefing") || lower.contains("rencana hari ini") || lower.contains("susun rencana") || lower.contains("pagi") && lower.contains("fokus") {
            await executeMorningBriefingTool(modelContext: modelContext)
            return
        }

        // 🌙 Evening Review
        if lower.contains("evaluasi") || lower.contains("evening review") || lower.contains("review malam") || lower.contains("rangkuman malam") || lower.contains("penutup hari") {
            await executeEveningReviewTool(modelContext: modelContext)
            return
        }

        // Tambah Tugas Otomatis
        if lower.contains("tambah tugas") || lower.contains("buat tugas") || lower.contains("tambahkan tugas") || lower.contains("bikin tugas") || lower.contains("add task") || lower.contains("jadwalkan") || lower.contains("ingatkan") {
            await executeDirectCreateTaskTool(prompt: trimmed, modelContext: modelContext)
            return
        }

        // Mulai Pomodoro
        if lower.contains("pomodoro") || lower.contains("fokus") || lower.contains("mulai timer") || lower.contains("timer") {
            await executeStartPomodoroTool(prompt: trimmed)
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

    // MARK: - 📝 Eksekusi Tambah Tugas Langsung ke Database SwiftData (Dengan Natural Time Parser & Conflict Detector)
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

        var priority = "Normal"
        if prompt.localizedCaseInsensitiveContains("penting") || prompt.localizedCaseInsensitiveContains("tinggi") || prompt.localizedCaseInsensitiveContains("darurat") || prompt.localizedCaseInsensitiveContains("urgent") || prompt.localizedCaseInsensitiveContains("segera") {
            priority = "Tinggi"
        } else if prompt.localizedCaseInsensitiveContains("santai") || prompt.localizedCaseInsensitiveContains("rendah") || prompt.localizedCaseInsensitiveContains("kapan-kapan") {
            priority = "Rendah"
        }

        let suggestions = SmartTaskBreakdownService.shared.generateSuggestions(for: cleanTitle, category: category)
        let subtasks = Array(suggestions.prefix(4)).map { SubtaskItem(title: $0, isCompleted: false) }

        // ⚠️ Deteksi Konflik Jadwal dengan Tugas yang Ada
        let itemDesc = FetchDescriptor<Item>()
        let existingItems = (try? modelContext.fetch(itemDesc)) ?? []
        let conflicts = ScheduleConflictDetector.shared.detectConflicts(for: parsedSchedule.targetDate, in: existingItems)

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
        let conflictNotice = (parsedSchedule.hasExplicitTime && !conflicts.isEmpty)
            ? "\n\n⚠️ **Catatan Tabrakan Waktu:** \(conflicts.first?.localizedWarningMessage ?? "") *(Notifikasi tugas tetap diaktifkan)*"
            : ""

        let reply = """
        🎉 **Tugas Berhasil Ditambahkan ke Aplikasi!**

        🎯 **\(newItem.title)**\(scheduleInfo)
        📁 Kategori: *\(newItem.category)* | ⚡ Prioritas: *\(newItem.priority)*

        📋 **Subtasks Otomatis Disiapkan:**\(subtasksListStr)\(conflictNotice)

        Tugas ini sudah tersimpan langsung di Beranda to-do list aplikasimu! Mau langsung mulai fokus dengan Pomodoro timer? ⏱️
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Task created")
    }

    // MARK: - ⏱️ Eksekusi MCP Tool: Mulai Pomodoro
    private func executeStartPomodoroTool(prompt: String) async {
        var duration = 25
        let numbers = prompt.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
        if let firstNum = numbers.first, let val = Int(firstNum), val > 0 && val <= 180 {
            duration = val
        }

        if duration >= 45 {
            PomodoroManager.shared.selectPreset(.deepFocus)
        } else if duration <= 5 {
            PomodoroManager.shared.selectPreset(.shortBreak)
        } else if duration <= 15 {
            PomodoroManager.shared.selectPreset(.longBreak)
        } else {
            PomodoroManager.shared.selectPreset(.quickFocus)
        }
        PomodoroManager.shared.startTimer()
        HapticManager.shared.success()

        let toolCall = MCPToolInvocation(
            name: "start_pomodoro_session",
            argumentsSummary: "duration: \(duration) minutes",
            icon: "timer",
            badgeColorHex: "#FCA5A5"
        )

        let reply = """
        ⏱️ **Sesi Pomodoro \(duration) Menit Telah Dimulai!**

        • Timer fokus sudah berjalan di latar belakang.
        • Suara ambient dan Live Activity Dynamic Island telah aktif.
        • Tetap fokus dan hindari distraksi! 💪
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Pomodoro started")
    }

    // MARK: - 📊 Eksekusi MCP Tool: Rangkum Status Aktivitas & HealthKit
    private func executeActivitySummaryTool(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []

        let total = items.count
        let completed = items.filter { $0.isCompleted }.count
        let pending = total - completed
        let highPriority = items.filter { !$0.isCompleted && $0.priority == "Tinggi" }.count

        let health = HealthKitManager.shared.todaySummary

        let toolCall = MCPToolInvocation(
            name: "get_productivity_and_health_summary",
            argumentsSummary: "pending: \(pending), completed: \(completed), steps: \(health.steps)",
            icon: "chart.bar.xaxis",
            badgeColorHex: "#6EE7B7"
        )

        let reply = """
        📊 **Rangkuman Aktivitas & Kesehatan Hari Ini:**

        📋 **To-Do List:**
        • ⏳ Belum Selesai: **\(pending) Tugas** (\(highPriority) Prioritas Tinggi)
        • ✅ Selesai: **\(completed) Tugas**
        • 📈 Total Terdaftar: **\(total) Tugas**

        🏃‍♂️ **Apple Health:**
        • 🚶 Langkah Kaki: **\(health.steps)** langkah
        • 🔥 Kalori Aktif: **\(Int(health.activeCalories))** kkal
        • ⏱️ Olahraga: **\(Int(health.exerciseMinutes))** menit
        • 💤 Waktu Tidur: **\(health.sleepFormatted)**

        Tetap semangat menyelesaikan tugas-tugas berikutnya! 🚀
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Summary extracted")
    }

    // MARK: - 🛡️ Eksekusi MCP Tool: Kunci Aplikasi Screen Time
    private func executeScreenTimeTool() async {
        ScreenTimeManager.shared.enableAppShield()
        HapticManager.shared.warning()

        let toolCall = MCPToolInvocation(
            name: "enable_screentime_distraction_shield",
            argumentsSummary: "status: locked",
            icon: "shield.lefthalf.filled",
            badgeColorHex: "#93C5FD"
        )

        let reply = """
        🛡️ **Perlindungan Distraksi Screen Time Telah Aktif!**

        Aplikasi pengganggu (sosial media & hiburan) yang dipilih telah diblokir selama sesi fokus ini. Kamu bisa fokus penuh sekarang! 🎯
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Shield activated")
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

        let systemInstruction = """
        Anda adalah asisten AI produktivitas cerdas dalam aplikasi to-do list, habit tracker, dan pomodoro iOS berdesain kartun neo-brutalist.
        Jawablah dengan bahasa Indonesia yang ramah, ringkas, penuh motivasi, dan gunakan format Markdown.
        Daftar tugas tertunda pengguna saat ini:
        \(pending.isEmpty ? "(Tidak ada tugas tertunda)" : pending)
        """

        do {
            var answer = ""
            if provider == .googleAccount {
                let bridge = GeminiBackgroundBridgeManager.shared
                let fullPrompt = "\(systemInstruction)\n\nPengguna: \(prompt)"
                answer = try await bridge.sendPromptToGeminiWeb(fullPrompt)
            } else if provider == .gemini {
                answer = try await callGeminiAPI(prompt: prompt, systemInstruction: systemInstruction, apiKey: apiKey)
            } else {
                answer = try await callNinerouterAPI(prompt: prompt, systemInstruction: systemInstruction, apiKey: apiKey, baseUrl: ninerouterBaseUrl, model: ninerouterModel)
            }

            await streamAssistantMessage(fullContent: answer)
        } catch {
            await streamAssistantMessage(
                fullContent: "Maaf, terjadi kendala saat menghubungi AI Cloud: \(error.localizedDescription).\n\nNamun, Anda tetap bisa menggunakan perintah cepat seperti *'buat tugas'*, *'mulai pomodoro'*, atau *'rangkum status'* secara instan!"
            )
        }
    }

    // MARK: - API Callers
    private func callGeminiAPI(prompt: String, systemInstruction: String, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "AI", code: 400, userInfo: [NSLocalizedDescriptionKey: "Gemini API Key belum dimasukkan di Pengaturan."])
        }
        let urlStr = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlStr) else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                ["role": "user", "parts": [["text": "\(systemInstruction)\n\nPertanyaan: \(prompt)"]]]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "AI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Gagal memproses permintaan AI Gemini."])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            return "Respons AI tidak dapat dibaca."
        }
        return text
    }

    private func callNinerouterAPI(prompt: String, systemInstruction: String, apiKey: String, baseUrl: String, model: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "AI", code: 400, userInfo: [NSLocalizedDescriptionKey: "Ninerouter API Key belum dimasukkan."])
        }
        let finalUrl = baseUrl.isEmpty ? "https://api.ninerouter.com/v1/chat/completions" : "\(baseUrl)/chat/completions"
        guard let url = URL(string: finalUrl) else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model.isEmpty ? "deepseek/deepseek-chat" : model,
            "messages": [
                ["role": "system", "content": systemInstruction],
                ["role": "user", "content": prompt]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "AI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Gagal memproses permintaan Ninerouter."])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let msg = first["message"] as? [String: Any],
              let text = msg["content"] as? String else {
            return "Respons AI tidak dapat dibaca."
        }
        return text
    }
}
