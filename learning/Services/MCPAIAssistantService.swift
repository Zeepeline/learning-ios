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
    case gemini = "Google AI Studio (Gemini 1.5 Flash)"
    case ninerouter = "Ninerouter / DeepSeek (Multi-LLM)"
    case local = "Smart Local Engine (Gratis & Offline)"
    case googleAccount = "Akun Google Login (Gemini OAuth)"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .gemini: return "Gemini 1.5"
        case .ninerouter: return "DeepSeek / LLM"
        case .local: return "Local Engine"
        case .googleAccount: return "Gemini (OAuth)"
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
        isExecutingTool: Bool = false
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.toolCall = toolCall
        self.toolResult = toolResult
        self.isExecutingTool = isExecutingTool
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
struct TaskProposal {
    let title: String
    let category: String
    let priority: String
    let subtasks: [String]
    let estimatedMinutes: Int
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
                Hai! Aku **AI Productivity Buddy (Co-Planner & MCP Engine)** 🤖✨

                Kita bisa **berdiskusi layaknya asisten pribadi**:
                • 💬 Ceritakan rencana/tujuanmu, aku akan bantu analisis & rekomendasikan subtasks sebelum dibuat.
                • 📝 Eksekusi tugas to-do list, habit tracker, dan rencana proyek multi-fase.
                • ⏱️ Jalankan sesi Pomodoro (25m/50m) & Live Activity.
                • 🏃‍♂️ Cek data kesehatan Apple Health & kontrol Screen Time App Shield.

                Apa rencana atau tugas yang ingin kita diskusikan hari ini?
                """
            )
        )
    }

    /// Kirim pesan pengguna dan proses percakapan multi-turn / MCP Tool Dispatcher
    func sendMessage(
        _ userText: String,
        modelContext: ModelContext,
        provider: AIProviderType = .local,
        apiKey: String = "",
        ninerouterBaseUrl: String = "https://api.ninerouter.com/v1",
        ninerouterModel: String = "deepseek/deepseek-chat"
    ) async {
        let trimmed = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMsg = MCPAIChatMessage(role: .user, content: trimmed)
        messages.append(userMsg)
        isProcessing = true
        HapticManager.shared.impact(style: .light)

        let cleanApiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        switch provider {
        case .gemini:
            if !cleanApiKey.isEmpty {
                await processWithGeminiLLM(prompt: trimmed, apiKey: cleanApiKey, modelContext: modelContext)
            } else {
                await processWithLocalDiscussion(prompt: trimmed, modelContext: modelContext, missingKeyPrompt: "Google AI Studio API Key belum dimasukkan di pengaturan.")
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

        case .googleAccount:
            await processWithGoogleUserAccount(prompt: trimmed, modelContext: modelContext)

        case .local:
            await processWithLocalDiscussion(prompt: trimmed, modelContext: modelContext)
        }

        isProcessing = false
    }

    // MARK: - 💬 Interactive Discussion & Co-Planning Dialogue Engine
    private func processWithLocalDiscussion(
        prompt: String,
        modelContext: ModelContext,
        missingKeyPrompt: String? = nil
    ) async {
        try? await Task.sleep(nanoseconds: 350_000_000)
        let lower = prompt.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Konfirmasi Pembuatan Jadwal / Proposal Aktif
        if let proposal = pendingProposal {
            let confirmKeywords = ["oke", "ok", "ya", "yes", "setuju", "buat sekarang", "jadwalkan", "buatkan", "siap", "gas", "bikin", "masukkan", "save", "simpan"]
            let isConfirming = confirmKeywords.contains(where: { lower.contains($0) })

            if isConfirming {
                await executeSaveProposalTool(proposal: proposal, modelContext: modelContext)
                pendingProposal = nil
                return
            } else if lower.contains("batal") || lower.contains("jangan") || lower.contains("cancel") {
                pendingProposal = nil
                messages.append(MCPAIChatMessage(role: .assistant, content: "Rencana dibatalkan 👍. Mau kita bahas ide atau tugas lain?"))
                return
            }
        }

        // 2. Sapaan Ramah
        if lower == "halo" || lower == "hai" || lower == "hi" || lower == "hey" || lower.hasPrefix("halo") || lower.hasPrefix("hai ") {
            let reply = "Halo! Senang bisa ngobrol denganmu! Ada rencana, tugas, atau target yang ingin kita diskusikan dan jadwalkan hari ini? 😊"
            messages.append(MCPAIChatMessage(role: .assistant, content: reply))
            return
        }

        // 3. Permintaan Diskusi / Pembuatan Jadwal & Perencanaan
        if lower.contains("jadwal") || lower.contains("rencana") || lower.contains("buatkan tugas") || lower.contains("buat tugas") || lower.contains("bantu bikin") || lower.contains("mau ngerjain") || lower.contains("mau belajar") {
            await handlePlanningDiscussion(prompt: prompt)
            return
        }

        // 4. Pomodoro / Timer Fokus
        if lower.contains("mulai pomodoro") || lower.contains("mulai fokus") || lower.contains("fokus 25") || lower.contains("fokus 50") || lower.contains("start timer") {
            await executeStartPomodoroTool(prompt: prompt)
            return
        }
        if lower.contains("stop pomodoro") || lower.contains("hentikan pomodoro") || lower.contains("stop timer") {
            await executeStopPomodoroTool()
            return
        }
        if lower.contains("status pomodoro") || lower.contains("sisa waktu fokus") {
            await executeGetFocusStatusTool()
            return
        }

        // 5. HealthKit & Screen Time
        if lower.contains("langkah") || lower.contains("kalori") || lower.contains("tidur") || lower.contains("kesehatan") {
            await executeGetHealthStatsTool()
            return
        }
        if lower.contains("kunci aplikasi") || lower.contains("aktifkan shield") || lower.contains("blokir aplikasi") || lower.contains("matikan shield") {
            await executeToggleAppShieldTool(prompt: prompt)
            return
        }

        // 6. Habit Tracker
        if lower.contains("ceklis habit") || lower.contains("log habit") || lower.contains("sudah baca") || lower.contains("sudah olahraga") {
            await executeLogHabitCheckInTool(prompt: prompt, modelContext: modelContext)
            return
        }
        if lower.contains("buat habit") || lower.contains("kebiasaan baru") {
            await executeCreateHabitTool(prompt: prompt, modelContext: modelContext)
            return
        }
        if lower.contains("daftar habit") || lower.contains("lihat habit") {
            await executeListHabitsTool(modelContext: modelContext)
            return
        }

        // 7. Tasks Management
        if lower.contains("selesaikan tugas") || lower.contains("tandai selesai") {
            await executeCompleteActivityTool(prompt: prompt, modelContext: modelContext)
            return
        }
        if lower.contains("daftar tugas") || lower.contains("lihat tugas") {
            await executeListActivitiesTool(prompt: prompt, modelContext: modelContext)
            return
        }
        if lower.contains("bersihkan selesai") {
            await executeClearCompletedActivitiesTool(modelContext: modelContext)
            return
        }

        // 8. General AI Conversation Response
        var extraNote = ""
        if let missing = missingKeyPrompt {
            extraNote = "\n\n*(Catatan: \(missing) Masukkan API Key di pengaturan ⚙️ untuk percakapan bebas LLM tanpa batas)*"
        }

        let reply = """
        Menarik! Terkait *"\(prompt)"*, aku siap bantu merencanakan atau mengeksekusinya.

        💡 Mau aku buatkan rencana langkah-langkah terstruktur (*subtasks*) untuk ini? Cukup balas *"Ya, tolong buatkan rekomendasinya"* atau ceritakan detail target waktumu!\(extraNote)
        """
        messages.append(MCPAIChatMessage(role: .assistant, content: reply))
    }

    // MARK: - 🧠 Co-Planning Discussion Handler
    private func handlePlanningDiscussion(prompt: String) async {
        var cleanTitle = prompt
        let removeKeywords = ["buatkan aku jadwal", "buatkan jadwal", "jadwalkan", "bantu rencanakan", "buat tugas", "mau belajar", "mau ngerjain", "bantu bikin"]
        for kw in removeKeywords {
            cleanTitle = cleanTitle.replacingOccurrences(of: kw, with: "", options: .caseInsensitive)
        }
        cleanTitle = cleanTitle.trimmingCharacters(in: .whitespacesAndNewlines)
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
            estimatedMinutes: 60
        )
        self.pendingProposal = proposal

        var subtasksListStr = ""
        for (i, step) in proposal.subtasks.enumerated() {
            subtasksListStr += "\n\(i + 1). 🔹 **\(step)**"
        }

        let reply = """
        Bagus sekali! Untuk **\(proposal.title)**, mari kita bedah menjadi subtasks yang jelas agar tidak terasa berat saat dikerjakan:

        📋 **Rekomendasi Langkah / Subtasks:**\(subtasksListStr)

        🏷️ **Kategori:** *\(proposal.category)*  
        ⚡ **Prioritas Disarankan:** *\(proposal.priority)*  
        ⏱️ **Estimasi Fokus:** ~\(proposal.estimatedMinutes) menit

        Bagaimana menurutmu? Kalau sudah cocok, balas **"Oke, jadwalkan"** atau **"Buat sekarang"** agar langsung aku masukkan ke to-do list kamu! 👍
        """

        messages.append(MCPAIChatMessage(role: .assistant, content: reply))
    }

    private func executeSaveProposalTool(proposal: TaskProposal, modelContext: ModelContext) async {
        let subtasks = proposal.subtasks.map { SubtaskItem(title: $0, isCompleted: false) }
        let newItem = Item(
            title: proposal.title,
            notes: "Direncanakan & didiskusikan bersama AI Productivity Buddy",
            timestamp: Date(),
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

        HapticManager.shared.success()
        SoundManager.shared.playSuccessChime()

        let toolCall = MCPToolInvocation(
            name: "create_activity",
            argumentsSummary: "title: \"\(newItem.title)\", subtasks: \(subtasks.count)",
            icon: "checkmark.seal.fill",
            badgeColorHex: "#6EE7B7"
        )

        let reply = """
        🎉 **Sip, Jadwal Berhasil Dibuat!**

        🎯 **\(newItem.title)**
        📁 Kategori: *\(newItem.category)* | ⚡ Prioritas: *\(newItem.priority)*
        📋 **\(subtasks.count) Subtasks** telah tersimpan di daftar tugasmu.

        Mau kita langsung mulai sesi **Pomodoro 25 Menit** untuk langkah pertamanya? ⏱️
        """

        messages.append(MCPAIChatMessage(role: .assistant, content: reply, toolCall: toolCall, toolResult: "Saved"))
    }

    // MARK: - 🌐 Gemini LLM (Google AI Studio API Key) - True Conversational LLM
    private func processWithGeminiLLM(prompt: String, apiKey: String, modelContext: ModelContext) async {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)") else {
            await processWithLocalDiscussion(prompt: prompt, modelContext: modelContext)
            return
        }

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
                    "text": """
                    Kamu adalah AI Productivity Buddy cerdas, kolaboratif, dan ramah di aplikasi to-do list iOS.
                    Prinsip interaksi:
                    1. Selalu berdiskusi secara interaktif. Jika pengguna menyapa, sapa balik dengan hangat.
                    2. Jika pengguna meminta dibuatkan jadwal, rencana, atau tugas baru, bedah terlebih dahulu menjadi subtasks terstruktur, berikan rekomendasi prioritas & estimasi waktu, lalu tanyakan konfirmasi pengguna.
                    3. Berikan jawaban dalam format Markdown yang rapi dengan bullet points dan emoji yang tepat.
                    """
                ]
            ]
        ]

        let requestBody: [String: Any] = [
            "contents": contentsPayload,
            "system_instruction": systemInstruction,
            "generationConfig": [
                "temperature": 0.7,
                "topP": 0.95
            ]
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

                await dispatchActionOrDisplayLLMResponse(llmText: text, prompt: prompt, modelContext: modelContext)
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

        var messagesPayload: [[String: String]] = [
            [
                "role": "system",
                "content": "Kamu adalah AI Productivity Buddy cerdas dan kolaboratif. Diskusikan rencana dan rekomendasikan subtasks sebelum membuat tugas. Format Markdown rapi."
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

                await dispatchActionOrDisplayLLMResponse(llmText: text, prompt: prompt, modelContext: modelContext)
                return
            }

            await processWithLocalDiscussion(prompt: prompt, modelContext: modelContext)
        } catch {
            await processWithLocalDiscussion(prompt: prompt, modelContext: modelContext)
        }
    }

    private func processWithGoogleUserAccount(prompt: String, modelContext: ModelContext) async {
        guard GoogleAuthManager.shared.isUserLoggedIn else {
            let reply = """
            🔒 **Akun Google Belum Terhubung**

            Silakan login dengan Google di tab Profil atau Pengaturan ⚙️ untuk sinkronisasi akun.
            """
            messages.append(MCPAIChatMessage(role: .assistant, content: reply))
            return
        }

        // Google Cloud API memerlukan API Key resmi dari Google AI Studio untuk pemanggilan Gemini 1.5 Flash langsung
        await processWithLocalDiscussion(
            prompt: prompt,
            modelContext: modelContext,
            missingKeyPrompt: "Akun Google terhubung (\(GoogleAuthManager.shared.currentUserEmail ?? "")). Untuk otak Gemini LLM penuh, masukkan Google AI Studio API Key gratis di ⚙️ Pengaturan"
        )
    }

    private func dispatchActionOrDisplayLLMResponse(llmText: String, prompt: String, modelContext: ModelContext) async {
        let lower = prompt.lowercased()
        if lower.contains("mulai pomodoro") || lower.contains("mulai fokus") {
            await executeStartPomodoroTool(prompt: prompt)
        } else if lower.contains("langkah") || lower.contains("kesehatan") || lower.contains("kalori") {
            await executeGetHealthStatsTool()
        } else {
            messages.append(MCPAIChatMessage(role: .assistant, content: llmText))
        }
    }

    // MARK: - 🛠️ MCP Tools Implementations
    private func executeCreateActivityTool(prompt: String, modelContext: ModelContext) async {
        await handlePlanningDiscussion(prompt: prompt)
    }

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
            messages.append(MCPAIChatMessage(role: .assistant, content: "ℹ️ Tidak ditemukan tugas tertunda yang cocok untuk diselesaikan."))
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

        let reply = "🎉 **Tugas Ditandai Selesai!**\n\n✅ **\(itemToComplete.title)** telah berhasil diselesaikan dan masuk ke riwayat tugas!"
        messages.append(MCPAIChatMessage(role: .assistant, content: reply, toolCall: toolCall, toolResult: "Task completed"))
    }

    private func executeListActivitiesTool(prompt: String, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        let lower = prompt.lowercased()

        let filteredItems: [Item]
        let titleHeader: String

        if lower.contains("penting") || lower.contains("tinggi") {
            filteredItems = items.filter { !$0.isCompleted && $0.priority == "Tinggi" }
            titleHeader = "🔥 **Daftar Tugas Prioritas Tinggi:**"
        } else if lower.contains("selesai") {
            filteredItems = items.filter { $0.isCompleted }
            titleHeader = "✅ **Daftar Tugas yang Telah Selesai:**"
        } else {
            filteredItems = items.filter { !$0.isCompleted }
            titleHeader = "📋 **Daftar Tugas Tertunda:**"
        }

        let toolCall = MCPToolInvocation(
            name: "list_activities",
            argumentsSummary: "count: \(filteredItems.count)",
            icon: "list.bullet.rectangle.portrait",
            badgeColorHex: "#A0C4FF"
        )

        if filteredItems.isEmpty {
            messages.append(MCPAIChatMessage(role: .assistant, content: "\(titleHeader)\n*Tidak ada tugas dalam kategori ini.*", toolCall: toolCall, toolResult: "0 items"))
            return
        }

        var text = "\(titleHeader)\n"
        for (i, item) in filteredItems.prefix(8).enumerated() {
            let prioIcon = item.priority == "Tinggi" ? "🔴" : (item.priority == "Sedang" ? "🟡" : "🟢")
            text += "\n\(i+1). \(prioIcon) **\(item.title)** [\(item.category)]"
        }

        messages.append(MCPAIChatMessage(role: .assistant, content: text, toolCall: toolCall, toolResult: "\(filteredItems.count) items retrieved"))
    }

    private func executeClearCompletedActivitiesTool(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        let completed = items.filter { $0.isCompleted }

        for item in completed {
            modelContext.delete(item)
        }
        try? modelContext.save()

        let toolCall = MCPToolInvocation(
            name: "clear_completed_activities",
            argumentsSummary: "clearedCount: \(completed.count)",
            icon: "trash.slash.fill",
            badgeColorHex: "#FFD166"
        )

        messages.append(MCPAIChatMessage(role: .assistant, content: "🧹 **Bersih-bersih Selesai!** Berhasil menghapus **\(completed.count) tugas selesai** dari riwayat.", toolCall: toolCall, toolResult: "Cleared \(completed.count)"))
    }

    private func executeStartPomodoroTool(prompt: String) async {
        var preset: PomodoroPreset = .quickFocus
        if prompt.contains("50") {
            preset = .deepFocus
        } else if prompt.contains("istirahat") || prompt.contains("break") {
            preset = .shortBreak
        }

        PomodoroManager.shared.selectPreset(preset)
        PomodoroManager.shared.taskTitle = "Fokus Belajar & Bekerja"
        PomodoroManager.shared.startTimer()

        HapticManager.shared.success()

        let toolCall = MCPToolInvocation(
            name: "start_pomodoro",
            argumentsSummary: "preset: \"\(preset.rawValue)\", durationMinutes: \(preset.minutes)",
            icon: "timer",
            badgeColorHex: "#FFD166"
        )

        let reply = "⏱️ **Sesi Pomodoro Dimulai!**\n\n🎯 Durasi: **\(preset.rawValue)** (\(preset.minutes) menit)\n🔔 Live Activity & Dynamic Island telah aktif untuk memantau fokusmu. Selamat bekerja!"
        messages.append(MCPAIChatMessage(role: .assistant, content: reply, toolCall: toolCall, toolResult: "Timer started"))
    }

    private func executeStopPomodoroTool() async {
        PomodoroManager.shared.resetTimer()
        HapticManager.shared.impact(style: .medium)

        let toolCall = MCPToolInvocation(
            name: "stop_pomodoro",
            argumentsSummary: "status: stopped",
            icon: "stop.circle.fill",
            badgeColorHex: "#FF99C8"
        )

        messages.append(MCPAIChatMessage(role: .assistant, content: "⏹️ **Sesi Pomodoro Dihentikan.** Timer dan Live Activity telah di-reset.", toolCall: toolCall, toolResult: "Stopped"))
    }

    private func executeGetFocusStatusTool() async {
        let manager = PomodoroManager.shared
        let remMin = manager.remainingSeconds / 60
        let remSec = manager.remainingSeconds % 60

        let toolCall = MCPToolInvocation(
            name: "get_focus_status",
            argumentsSummary: "isRunning: \(manager.isRunning), remSeconds: \(manager.remainingSeconds)",
            icon: "gauge.with.needle.fill",
            badgeColorHex: "#A0C4FF"
        )

        let reply = """
        ⏱️ **Status Sesi Fokus Saat Ini:**
        • Status: **\(manager.isRunning ? "Sedang Berjalan 🔥" : (manager.isPaused ? "Dijeda ⏸️" : "Standby 💤"))**
        • Sisa Waktu: **\(String(format: "%02d:%02d", remMin, remSec))**
        • Total Sesi Selesai: **\(manager.completedSessionsCount) sesi**
        """
        messages.append(MCPAIChatMessage(role: .assistant, content: reply, toolCall: toolCall, toolResult: "Status retrieved"))
    }

    private func executeGetHealthStatsTool() async {
        await HealthKitManager.shared.fetchAllTodayHealthData(force: true)
        let summary = HealthKitManager.shared.todaySummary

        let toolCall = MCPToolInvocation(
            name: "get_health_stats",
            argumentsSummary: "steps: \(summary.steps), cal: \(Int(summary.activeCalories)), sleep: \"\(summary.sleepFormatted)\"",
            icon: "heart.fill",
            badgeColorHex: "#FF99C8"
        )

        let reply = """
        🏃‍♂️ **Ringkasan Kesehatan Hari Ini (Apple Health):**
        • 👟 **Langkah Kaki:** \(summary.steps.formatted()) / 6.000 langkah
        • 🔥 **Kalori Aktif:** \(Int(summary.activeCalories)) kkal
        • ⏱️ **Menit Olahraga:** \(Int(summary.exerciseMinutes)) menit
        • 😴 **Durasi Tidur:** \(summary.sleepFormatted)

        \(summary.steps >= 6000 ? "🎉 *Hebat! Target langkah harianmu sudah tercapai!*" : "💡 *Ayo sempatkan jalan santai 10 menit untuk menyegarkan pikiran!*")
        """
        messages.append(MCPAIChatMessage(role: .assistant, content: reply, toolCall: toolCall, toolResult: "HealthKit synced"))
    }

    private func executeToggleAppShieldTool(prompt: String) async {
        let lower = prompt.lowercased()
        let shouldDisable = lower.contains("matikan") || lower.contains("buka") || lower.contains("off")

        if shouldDisable {
            ScreenTimeManager.shared.disableAppShield()
        } else {
            ScreenTimeManager.shared.enableAppShield()
        }

        let isShield = ScreenTimeManager.shared.isShieldActive

        let toolCall = MCPToolInvocation(
            name: "toggle_app_shield",
            argumentsSummary: "isActive: \(isShield)",
            icon: "shield.lefthalf.filled",
            badgeColorHex: "#BDB2FF"
        )

        let reply = isShield
            ? "🛡️ **Mode Perisai Fokus Aktif!** Aplikasi-aplikasi yang Anda pilih telah dikunci agar konsentrasi terjaga."
            : "🔓 **Perisai Fokus Dimatikan.** Semua aplikasi kini dapat diakses kembali secara normal."

        messages.append(MCPAIChatMessage(role: .assistant, content: reply, toolCall: toolCall, toolResult: "Shield: \(isShield)"))
    }

    private func executeCreateHabitTool(prompt: String, modelContext: ModelContext) async {
        var habitTitle = prompt
        let removeKeywords = ["buat habit", "tambah habit", "kebiasaan baru", "buat kebiasaan", "tolong buat", "rutinitas"]
        for kw in removeKeywords {
            habitTitle = habitTitle.replacingOccurrences(of: kw, with: "", options: .caseInsensitive)
        }
        habitTitle = habitTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if habitTitle.isEmpty { habitTitle = "Membaca Buku 15 Menit" }

        let newHabit = Habit(
            title: habitTitle.capitalized,
            icon: "star.fill",
            colorHex: "#A0C4FF",
            category: "Produktivitas",
            targetFrequency: "Harian"
        )

        modelContext.insert(newHabit)
        try? modelContext.save()
        lastCreatedHabit = newHabit

        HapticManager.shared.success()

        let toolCall = MCPToolInvocation(
            name: "create_habit",
            argumentsSummary: "title: \"\(newHabit.title)\", frequency: Harian",
            icon: "repeat.circle.fill",
            badgeColorHex: "#A0C4FF"
        )

        let reply = "🌟 **Target Kebiasaan Baru Didaftarkan!**\n\n📌 **\(newHabit.title)**\n📅 Target: Harian\n\n*Konsistensi kecil setiap hari akan membawa hasil besar!*"
        messages.append(MCPAIChatMessage(role: .assistant, content: reply, toolCall: toolCall, toolResult: "Habit saved"))
    }

    private func executeLogHabitCheckInTool(prompt: String, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Habit>()
        let habits = (try? modelContext.fetch(descriptor)) ?? []

        var targetHabit: Habit? = nil
        let cleanedPrompt = prompt.lowercased()
        for h in habits {
            if cleanedPrompt.contains(h.title.lowercased()) {
                targetHabit = h
                break
            }
        }
        if targetHabit == nil { targetHabit = habits.first }

        guard let habit = targetHabit else {
            messages.append(MCPAIChatMessage(role: .assistant, content: "ℹ️ Belum ada habit yang terdaftar untuk diceklis."))
            return
        }

        habit.toggleCompletion(on: Date())
        try? modelContext.save()

        HapticManager.shared.success()
        SoundManager.shared.playSuccessChime()

        let toolCall = MCPToolInvocation(
            name: "log_habit_checkin",
            argumentsSummary: "habitTitle: \"\(habit.title)\", currentStreak: \(habit.currentStreak)",
            icon: "flame.fill",
            badgeColorHex: "#FFD166"
        )

        let reply = "🔥 **Habit Berhasil Diceklis Hari Ini!**\n\n⭐ **\(habit.title)**\n🔥 Streak saat ini: **\(habit.currentStreak) hari berturut-turut**!\nPertahankan ritme konsistensimu!"
        messages.append(MCPAIChatMessage(role: .assistant, content: reply, toolCall: toolCall, toolResult: "Streak: \(habit.currentStreak)"))
    }

    private func executeListHabitsTool(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Habit>()
        let habits = (try? modelContext.fetch(descriptor)) ?? []

        let toolCall = MCPToolInvocation(
            name: "list_habits",
            argumentsSummary: "count: \(habits.count)",
            icon: "repeat",
            badgeColorHex: "#A0C4FF"
        )

        if habits.isEmpty {
            messages.append(MCPAIChatMessage(role: .assistant, content: "🔄 **Daftar Kebiasaan:**\n*Belum ada habit yang didaftarkan. Minta aku 'Buat habit baca buku' untuk memulai!*", toolCall: toolCall, toolResult: "0 habits"))
            return
        }

        var text = "🔄 **Daftar Kebiasaan & Streak:**\n"
        for (i, h) in habits.enumerated() {
            let isDoneToday = h.isCompleted(on: Date())
            let status = isDoneToday ? "✅ Selesai" : "⏳ Belum"
            text += "\n\(i+1). **\(h.title)** (\(h.targetFrequency)) — 🔥 \(h.currentStreak) hari [\(status)]"
        }

        messages.append(MCPAIChatMessage(role: .assistant, content: text, toolCall: toolCall, toolResult: "\(habits.count) habits"))
    }

    /// Bersihkan riwayat percakapan chat
    func clearMessages() {
        messages.removeAll()
        pendingProposal = nil
        messages.append(
            MCPAIChatMessage(
                role: .assistant,
                content: "Hai! Percakapan telah direset. Mau kita diskusikan rencana atau jalankan aksi MCP apa sekarang? ⚡"
            )
        )
    }
}
