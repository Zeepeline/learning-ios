//
//  MCPAIAssistantService.swift
//  learning
//
//  Created by macbook on 9/19/26.
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - 🤖 AI Provider Type
enum AIProviderType: String, CaseIterable, Identifiable {
    case googleAccount = "googleAccount"
    case geminiApiKey = "geminiApiKey"
    case ninerouter = "ninerouter"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .googleAccount:
            return "Akun Google (Gemini Web)"
        case .geminiApiKey:
            return "Google Gemini API (API Key)"
        case .ninerouter:
            return "OpenRouter / Ninerouter"
        }
    }
}

// MARK: - 💬 AI Chat Message Model
struct AIMessage: Identifiable, Equatable {
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
        Halo! Saya **AI Asisten Produktivitas** pribadimu 🤖✨

        Saya siap membantu kamu mengelola hari dengan efisien:
        • 🌅 Susun rencana hari ini (**"Susun rencana hari ini"**)
        • 📊 Laporan mingguan & skor produktivitas (**"Laporan mingguan"**)
        • 🌙 Evaluasi malam & kesehatan (**"Evaluasi hari ini"**)
        • 🪄 Pecah tugas jadi subtask (**"Pecah tugas presentasi"**)
        • 💡 Rekomendasi kebiasaan baru (**"Rekomendasikan habit"**)
        • 🛡️ Cek radar risiko streak habit (**"Cek risiko streak"**)
        • ⚡ Tambah tugas cerdas (**"Coding besok jam 8 malam"**)
        • ⏱️ Mulai timer Pomodoro (**"Mulai fokus 25 menit"**)
        • 🛡️ Batasi distraksi (**"Kunci aplikasi pengganggu"**)
        • 🔥 Check-in habit harian (**"Ceklis habit membaca"**)

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
        if lower.contains("mingguan") || lower.contains("weekly") || lower.contains("skor produktivitas") || lower.contains("evaluasi minggu") {
            let tool = MCPToolInvocation(name: "generate_weekly_review", description: "Menghitung skor produktivitas 7 hari", icon: "chart.bar.xaxis", badgeColorHex: "#A0E7E5")
            await executeWeeklyReviewTool(tool: tool, modelContext: modelContext)
            return
        }

        // Habit Recommendation Generator
        if lower.contains("rekomendasi habit") || lower.contains("rekomendasikan kebiasaan") || lower.contains("saran habit") {
            let tool = MCPToolInvocation(name: "recommend_habits", description: "Menganalisis pola & merekomendasikan habit baru", icon: "lightbulb.fill", badgeColorHex: "#FFAEBC")
            await executeHabitRecommendationTool(tool: tool, modelContext: modelContext)
            return
        }

        // Habit Streak Risk Radar
        if lower.contains("risiko streak") || lower.contains("cek habit") || lower.contains("radar streak") || lower.contains("habit terancam") {
            let tool = MCPToolInvocation(name: "check_habit_streak_risk", description: "Memindai habit yang belum selesai hari ini", icon: "flame.fill", badgeColorHex: "#FFB347")
            await executeHabitRiskRadarTool(tool: tool, modelContext: modelContext)
            return
        }

        // Subtask Breakdown Tool
        if lower.hasPrefix("pecah ") || lower.hasPrefix("bagi ") || lower.contains("subtask") || lower.contains("langkah pengerjaan") {
            let taskTitle = trimmed
                .replacingOccurrences(of: "(?i)^pecah\\s+tugas\\s+", with: "", options: .regularExpression)
                .replacingOccurrences(of: "(?i)^pecah\\s+", with: "", options: .regularExpression)
                .replacingOccurrences(of: "(?i)^bagi\\s+", with: "", options: .regularExpression)

            let tool = MCPToolInvocation(name: "breakdown_task_subtasks", description: "Memecah tugas menjadi langkah terukur", icon: "wand.and.stars", badgeColorHex: "#D8B4F8")
            await executeTaskBreakdownTool(taskTitle: taskTitle, tool: tool)
            return
        }

        // HealthKit & Step Summary Tool
        if lower.contains("kesehatan") || lower.contains("langkah") || lower.contains("health") || lower.contains("jalan kaki") {
            let tool = MCPToolInvocation(name: "get_health_activity_summary", description: "Mengambil data langkah hari ini", icon: "heart.fill", badgeColorHex: "#FFAEBC")
            await executeHealthSummaryTool(tool: tool)
            return
        }

        // Screen Time & Distraction Blocker Tool
        if lower.contains("kunci aplikasi") || lower.contains("blokir sosmed") || lower.contains("distraksi") || lower.contains("shield") {
            let tool = MCPToolInvocation(name: "toggle_app_shield", description: "Mengaktifkan pembatasan fokus aplikasi", icon: "shield.fill", badgeColorHex: "#B4F8C8")
            await executeDistractionShieldTool(tool: tool)
            return
        }

        // Pomodoro Focus Timer Tool
        if lower.contains("pomodoro") || lower.contains("mulai fokus") || lower.contains("timer fokus") || lower.contains("25 menit") {
            let tool = MCPToolInvocation(name: "start_pomodoro_session", description: "Memulai timer Pomodoro 25 Menit", icon: "timer", badgeColorHex: "#FFB3BA")
            await executePomodoroTool(tool: tool)
            return
        }

        // Clean Completed Tasks Tool
        if lower.contains("bersihkan tugas") || lower.contains("hapus tugas selesai") || lower.contains("clear completed") {
            let tool = MCPToolInvocation(name: "clear_completed_activities", description: "Menghapus tugas selesai hari ini", icon: "trash.fill", badgeColorHex: "#FBE7C6")
            await executeClearCompletedTool(tool: tool, modelContext: modelContext)
            return
        }

        // Direct Task Creation via Natural Time Parser
        let parsed = NaturalTimeParser.shared.parseSchedule(from: trimmed)
        let isCreationIntent = lower.hasPrefix("tambah") || lower.hasPrefix("buat") || lower.hasPrefix("ingatkan") || parsed.hasExplicitTime

        if isCreationIntent && !parsed.cleanText.isEmpty {
            let tool = MCPToolInvocation(name: "create_activity", description: "Menjadwalkan aktivitas baru ke daftar tugas", icon: "plus.circle.fill", badgeColorHex: "#B4F8C8")
            await executeCreateTaskTool(parsed: parsed, tool: tool, modelContext: modelContext)
            return
        }

        // 2. Default: Kirim ke AI Engine (Akun Google / Gemini API / OpenRouter)
        await sendToAIEngine(
            prompt: trimmed,
            provider: provider,
            apiKey: apiKey,
            ninerouterBaseUrl: ninerouterBaseUrl,
            ninerouterModel: ninerouterModel,
            modelContext: modelContext
        )
    }

    // MARK: - 📊 Tool: Weekly Review & Infographic
    private func executeWeeklyReviewTool(tool: MCPToolInvocation, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>()
        let allItems = (try? modelContext.fetch(descriptor)) ?? []

        let report = AIWeeklyReviewService.shared.generateWeeklyReview(from: allItems)

        let messageContent = """
        ### 📊 Rapor Mingguan Produktivitas Kamu
        Skor Efisiensi: **\(report.scoreGrade)** (\(report.productivityScore)/100)

        • **Ringkasan Aktivitas**:
          - Total Tugas Selesai: **\(report.completedCount) tugas**
          - Tugas Belum Selesai: **\(report.pendingCount) tugas**
          - Rasio Keberhasilan: **\(Int(report.completionRate * 100))%**
          - Kategori Teraktif: **\(report.topCategory)**

        • **Komentar Asisten**:
        \(report.summaryText)

        • **Tips Strategis Minggu Depan**:
        \(report.motivationalTip)
        """

        var msg = AIMessage(isUser: false, content: messageContent)
        msg.toolCall = tool
        msg.toolResult = "SUCCESS: Rapor Mingguan Dibuat"
        messages.append(msg)
    }

    // MARK: - 💡 Tool: Habit Recommendation
    private func executeHabitRecommendationTool(tool: MCPToolInvocation, modelContext: ModelContext) async {
        let habitDesc = FetchDescriptor<Habit>()
        let existingHabits = (try? modelContext.fetch(habitDesc)) ?? []

        let itemDesc = FetchDescriptor<Item>()
        let existingItems = (try? modelContext.fetch(itemDesc)) ?? []

        let recommendations = AIHabitRecommenderService.shared.generateRecommendations(
            existingHabits: existingHabits,
            items: existingItems
        )

        var listText = ""
        for (idx, rec) in recommendations.prefix(3).enumerated() {
            listText += "\n\(idx + 1). **\(rec.title)** (\(rec.category.rawValue))\n   • *Alasan*: \(rec.reason)\n   • *Waktu*: \(rec.timeOfDay) • Target: \(rec.targetDaysPerWeek)x seminggu"
        }

        let messageContent = """
        ### 💡 Rekomendasi Kebiasaan Positif Untukmu
        Berikut adalah ide habit baru yang disesuaikan dengan aktivitas harianmu:
        \(listText)

        *Ketik "Buka Habit Tracker" atau buka menu Kebiasaan untuk menyimpannya.*
        """

        var msg = AIMessage(isUser: false, content: messageContent)
        msg.toolCall = tool
        msg.toolResult = "SUCCESS: Rekomendasi Habit Dihasilkan"
        messages.append(msg)
    }

    // MARK: - 🔥 Tool: Habit Streak Risk Radar
    private func executeHabitRiskRadarTool(tool: MCPToolInvocation, modelContext: ModelContext) async {
        let habitDesc = FetchDescriptor<Habit>()
        let existingHabits = (try? modelContext.fetch(habitDesc)) ?? []

        let atRiskHabits = existingHabits.filter { !$0.isCompletedToday }

        let messageContent: String
        if atRiskHabits.isEmpty {
            messageContent = """
            ### 🛡️ Radar Streak Habit Aman!
            Semua kebiasaan aktif kamu untuk hari ini **sudah tuntas dikerjakan**. Kerja luar biasa mempertahankan konsistensi! 🔥✨
            """
        } else {
            var lines = ""
            for habit in atRiskHabits.prefix(5) {
                lines += "\n• **\(habit.title)** — Streak saat ini: **\(habit.streak) Hari** 🔥"
            }

            messageContent = """
            ### ⚠️ Perhatian: Radar Risiko Streak Habit
            Ditemukan **\(atRiskHabits.count) kebiasaan** yang belum dicentang hari ini:
            \(lines)

            *Luangkan 5–10 menit untuk menyelesaikan habit di atas agar streak tidak terputus!*
            """
        }

        var msg = AIMessage(isUser: false, content: messageContent)
        msg.toolCall = tool
        msg.toolResult = "SUCCESS: Habit Risk Checked"
        messages.append(msg)
    }

    // MARK: - 🪄 Tool: Task Subtask Breakdown
    private func executeTaskBreakdownTool(taskTitle: String, tool: MCPToolInvocation) async {
        let breakdown = AITaskBreakdownService.shared.generateBreakdown(for: taskTitle)

        let proposal = AIActionProposal(
            title: breakdown.refinedTitle,
            subtitle: "Estimasi total: ~\(breakdown.totalEstimatedMinutes) menit",
            targetDate: Date().addingTimeInterval(3600),
            priority: breakdown.suggestedPriority,
            category: breakdown.suggestedCategory,
            subtasks: breakdown.subtasks.map { $0.title }
        )

        let messageContent = """
        ### 🪄 Rencana Pengerjaan: \(breakdown.refinedTitle)
        Estimasi Waktu: **~\(breakdown.totalEstimatedMinutes) Menit** • Kategori: **\(breakdown.suggestedCategory)** • Prioritas: **\(breakdown.suggestedPriority)**

        Langkah-langkah terstruktur:
        \(breakdown.subtasks.enumerated().map { "\($0 + 1). **\($1.title)** (~\($1.estimatedMinutes)m)" }.joined(separator: "\n"))

        *Kamu dapat mencentang dan langsung menyimpan tugas ini melalui kartu interaktif di bawah:*
        """

        var msg = AIMessage(isUser: false, content: messageContent)
        msg.toolCall = tool
        msg.toolResult = "SUCCESS: Task Breakdown Prepared"
        msg.proposal = proposal
        messages.append(msg)
    }

    // MARK: - ❤️ Tool: HealthKit Step Summary
    private func executeHealthSummaryTool(tool: MCPToolInvocation) async {
        let isAuthorized = await HealthKitManager.shared.requestAuthorization()
        var stepText = "Akses HealthKit belum diizinkan."

        if isAuthorized {
            let steps = await HealthKitManager.shared.fetchTodayStepCount()
            let percentage = min(100, Int((steps / 10000.0) * 100))
            stepText = """
            Total Langkah Hari Ini: **\(Int(steps).formatted()) langkah**
            Target Harian (10.000 langkah): **\(percentage)% tercapai** 👟
            """
        }

        let messageContent = """
        ### ❤️ Data Aktivitas & Kesehatan Hari Ini
        \(stepText)

        *Tips: Berjalan kaki ringan selama 10 menit di sela kerja dapat menyegarkan kembali fokus otakmu!*
        """

        var msg = AIMessage(isUser: false, content: messageContent)
        msg.toolCall = tool
        msg.toolResult = "SUCCESS: Health Summary Fetched"
        messages.append(msg)
    }

    // MARK: - 🛡️ Tool: Screen Time Distraction Shield
    private func executeDistractionShieldTool(tool: MCPToolInvocation) async {
        let isCurrentlyActive = ScreenTimeManager.shared.isShieldActive
        if isCurrentlyActive {
            ScreenTimeManager.shared.disableAppShield()
        } else {
            ScreenTimeManager.shared.enableAppShield()
        }

        let newStatus = ScreenTimeManager.shared.isShieldActive
        let messageContent = """
        ### 🛡️ Screen Time Shield: \(newStatus ? "AKTIF" : "NONAKTIF")
        \(newStatus ? "Aplikasi media sosial dan game pengganggu telah dibatasi untuk sementara waktu. Selamat menikmati fokus maksimal!" : "Pembatasan aplikasi pengganggu telah dinonaktifkan.")
        """

        var msg = AIMessage(isUser: false, content: messageContent)
        msg.toolCall = tool
        msg.toolResult = "SUCCESS: Shield Toggled"
        messages.append(msg)
    }

    // MARK: - ⏱️ Tool: Pomodoro Session
    private func executePomodoroTool(tool: MCPToolInvocation) async {
        PomodoroManager.shared.selectPreset(.quickFocus)
        PomodoroManager.shared.startTimer()

        let messageContent = """
        ### ⏱️ Timer Pomodoro 25 Menit Dimulai!
        Sesi fokus telah berjalan. Jauhkan distraksi, fokus pada 1 tugas prioritas, dan nikmati alur kerjamu! 🎯💪
        """

        var msg = AIMessage(isUser: false, content: messageContent)
        msg.toolCall = tool
        msg.toolResult = "SUCCESS: Pomodoro Started"
        messages.append(msg)
    }

    // MARK: - 🧹 Tool: Clear Completed Activities
    private func executeClearCompletedTool(tool: MCPToolInvocation, modelContext: ModelContext) async {
        let desc = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(desc)) ?? []
        let completedToday = items.filter { item in
            item.isCompleted && Calendar.current.isDateInToday(item.completedAt ?? item.timestamp)
        }

        for item in completedToday {
            modelContext.delete(item)
        }
        try? modelContext.save()

        let messageContent = """
        ### 🧹 Bersihkan Tugas Selesai
        Berhasil membersihkan **\(completedToday.count) tugas** yang telah diselesaikan hari ini dari daftar aktif beranda. Halamanmu kini rapi kembali! ✨
        """

        var msg = AIMessage(isUser: false, content: messageContent)
        msg.toolCall = tool
        msg.toolResult = "SUCCESS: Cleared \(completedToday.count) items"
        messages.append(msg)
    }

    // MARK: - ➕ Tool: Create Task
    private func executeCreateTaskTool(parsed: ParsedNaturalSchedule, tool: MCPToolInvocation, modelContext: ModelContext) async {
        let title = parsed.cleanText.isEmpty ? "Aktivitas Baru" : parsed.cleanText
        let tagSuggestion = AITaskBreakdownService.shared.suggestTags(for: title)

        let newItem = Item(
            title: title,
            notes: "Dibuat otomatis oleh AI Asisten",
            timestamp: parsed.targetDate,
            isCompleted: false,
            completedAt: nil,
            priority: tagSuggestion.priority.rawValue,
            category: tagSuggestion.category.rawValue
        )

        modelContext.insert(newItem)
        try? modelContext.save()

        let dateFormatted = parsed.targetDate.formatted(date: .abbreviated, time: .shortened)
        let messageContent = """
        ### ⚡ Tugas Berhasil Ditambahkan!
        • **Judul**: \(title)
        • **Waktu**: \(dateFormatted)
        • **Kategori**: \(tagSuggestion.category.rawValue)
        • **Prioritas**: \(tagSuggestion.priority.rawValue)

        Tugas sudah langsung tampil di Beranda dan Timeline Harianmu! 🎯
        """

        var msg = AIMessage(isUser: false, content: messageContent)
        msg.toolCall = tool
        msg.toolResult = "SUCCESS: Created Item '\(title)'"
        messages.append(msg)
    }

    // MARK: - 🌐 External AI Request Dispatcher
    private func sendToAIEngine(
        prompt: String,
        provider: AIProviderType,
        apiKey: String,
        ninerouterBaseUrl: String,
        ninerouterModel: String,
        modelContext: ModelContext
    ) async {
        let desc = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(desc)) ?? []
        let pending = items.filter { !$0.isCompleted }.prefix(5).map { "• \($0.title) (\($0.timestamp.formatted(date: .omitted, time: .shortened)))" }.joined(separator: "\n")

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
            let errorReply: String
            if provider == .googleAccount {
                errorReply = """
                ⚠️ **Sesi Akun Google Gemini Belum Aktif**

                Untuk menggunakan mode web gratis:
                1. Ketuk tombol **Login 🔑** pada banner di atas chat, atau buka **Pengaturan (⚙️)**.
                2. Masuk ke akun Google Anda satu kali.

                💡 *Tips: Anda juga bisa beralih ke **Gemini API Key** (gratis & cepat dari Google AI Studio) di menu Pengaturan.*
                """
            } else if provider == .geminiApiKey && apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorReply = """
                ⚠️ **Gemini API Key Belum Diisi**

                Silakan buka **Pengaturan (⚙️)** di pojok kanan atas dan masukkan API Key Anda dari Google AI Studio.
                """
            } else {
                errorReply = "⚠️ Maaf, terjadi kendala koneksi AI: \(error.localizedDescription)\n\nSilakan periksa koneksi internet atau pengaturan AI di menu Pengaturan Asisten (⚙️)."
            }
            await streamAssistantMessage(fullContent: errorReply)
        }
    }

    // MARK: - 🌊 Stream Assistant Message Word by Word (Smooth & Sharp)
    private func streamAssistantMessage(fullContent: String) async {
        var placeholder = AIMessage(isUser: false, content: "")
        placeholder.isStreaming = true
        messages.append(placeholder)

        let words = fullContent.components(separatedBy: " ")
        var accumulated = ""
        let chunkSize = 3

        for i in stride(from: 0, to: words.count, by: chunkSize) {
            let chunk = words[i..<min(i + chunkSize, words.count)].joined(separator: " ")
            accumulated += (accumulated.isEmpty ? "" : " ") + chunk
            if let idx = messages.firstIndex(where: { $0.id == placeholder.id }) {
                messages[idx].content = accumulated
            }
            try? await Task.sleep(nanoseconds: 25_000_000)
        }

        if let idx = messages.firstIndex(where: { $0.id == placeholder.id }) {
            messages[idx].content = fullContent
            messages[idx].isStreaming = false
        }
    }

    // MARK: - 🌐 Gemini REST API Request
    private func sendGeminiAPIRequest(prompt: String, systemInstruction: String, apiKey: String) async throws -> String {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else {
            throw NSError(domain: "GeminiAPI", code: 400, userInfo: [NSLocalizedDescriptionKey: "API Key kosong"])
        }

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(cleanKey)"
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
            throw NSError(domain: "GeminiAPI", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "Gagal memanggil Gemini API"])
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

    // MARK: - 🌐 Ninerouter / OpenRouter Request
    private func sendNinerouterRequest(
        prompt: String,
        systemInstruction: String,
        apiKey: String,
        baseUrl: String,
        model: String
    ) async throws -> String {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBase = baseUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "https://openrouter.ai/api/v1" : baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanModel = model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "google/gemini-flash-1.5" : model.trimmingCharacters(in: .whitespacesAndNewlines)

        let urlString = "\(cleanBase)/chat/completions"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(cleanKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": cleanModel,
            "messages": [
                ["role": "system", "content": systemInstruction],
                ["role": "user", "content": prompt]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "Ninerouter", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "Gagal memanggil OpenRouter/Ninerouter"])
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let choices = json?["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }

        return "Tidak dapat memproses respons dari router AI."
    }
}
