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
    case local = "Smart Local (Gratis & Offline)"
    case googleAccount = "Akun Google Login (Gemini AI)"
    case gemini = "Google AI Studio (API Key)"
    case ninerouter = "Ninerouter (Multi-LLM)"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .local: return "Local MCP"
        case .googleAccount: return "Gemini (Google)"
        case .gemini: return "Gemini (Key)"
        case .ninerouter: return "Ninerouter"
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

// MARK: - 🧠 MCP AI Assistant Service (Model Context Protocol Engine)
@MainActor
final class MCPAIAssistantService: ObservableObject {
    static let shared = MCPAIAssistantService()

    @Published var messages: [MCPAIChatMessage] = []
    @Published var isProcessing: Bool = false
    @Published var lastCreatedItem: Item? = nil
    @Published var lastCreatedHabit: Habit? = nil

    private init() {
        // Pesan sambutan awal ramah & interaktif untuk diskusi
        messages.append(
            MCPAIChatMessage(
                role: .assistant,
                content: "Hai! Aku **AI Productivity Buddy** ⚡\n\nKita bisa **berdiskusi apa saja** tentang caramu mengatur waktu, brainstorming rencana proyek, mengatasi prokrastinasi, hingga memecah ide besar.\n\nJika kamu siap mengeksekusinya, cukup minta aku membuat to-do list atau habit baru secara otomatis lewat protokol **MCP**! Mau kita diskusikan apa hari ini?"
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

        // 1. Tambahkan pesan User ke histori
        let userMsg = MCPAIChatMessage(role: .user, content: trimmed)
        messages.append(userMsg)
        isProcessing = true
        HapticManager.shared.impact(style: .light)

        let cleanApiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        // 2. Routing berdasarkan Provider yang dipilih
        switch provider {
        case .googleAccount:
            await processWithGoogleUserAccount(prompt: trimmed, modelContext: modelContext)

        case .gemini:
            if !cleanApiKey.isEmpty {
                await processWithGeminiLLM(prompt: trimmed, apiKey: cleanApiKey, modelContext: modelContext)
            } else {
                await processWithLocalMCP(prompt: trimmed, modelContext: modelContext)
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
                await processWithLocalMCP(prompt: trimmed, modelContext: modelContext)
            }

        case .local:
            await processWithLocalMCP(prompt: trimmed, modelContext: modelContext)
        }

        isProcessing = false
    }

    // MARK: - ⚡ Smart Local Engine & Conversational Fallback
    private func processWithLocalMCP(prompt: String, modelContext: ModelContext) async {
        try? await Task.sleep(nanoseconds: 500_000_000)

        let lower = prompt.lowercased()

        // Skenario Aksi MCP: Buat Tugas
        if lower.contains("buat tugas") || lower.contains("tambah tugas") || lower.contains("jadwalkan") || lower.contains("ingatkan") || lower.contains("catat tugas") || (lower.contains("buatkan") && lower.contains("todo")) {
            await executeCreateActivityTool(prompt: prompt, modelContext: modelContext)
            return
        }

        // Skenario Aksi MCP: Rangkuman Jadwal
        if lower.contains("rangkum") || lower.contains("ringkas") || lower.contains("jadwal hari ini") || lower.contains("status tugas") || lower.contains("progres hari ini") {
            await executeGetTodaySummaryTool(modelContext: modelContext)
            return
        }

        // Skenario Aksi MCP: Buat Habit
        if lower.contains("buat habit") || lower.contains("kebiasaan baru") || lower.contains("rutinitas baru") || lower.contains("tambah habit") {
            await executeCreateHabitTool(prompt: prompt, modelContext: modelContext)
            return
        }

        // Skenario Aksi MCP: Pecah Tugas Besar
        if lower.contains("pecah tugas") || lower.contains("breakdown") || lower.contains("bagi tugas") || lower.contains("subtask") {
            await executeBreakdownTaskTool(prompt: prompt)
            return
        }

        // Skenario Diskusi: Bingung Mulai dari Mana / Overwhelmed
        if lower.contains("bingung") || lower.contains("pusing") || lower.contains("banyak banget") || lower.contains("overwhelmed") || lower.contains("capek") || lower.contains("malas") || lower.contains("menunda") {
            let reply = """
            Tenang, wajar banget kalau merasa bingung atau kewalahan saat banyak hal yang harus dikerjakan! 🌿

            Mari kita urai bersama dengan **3 langkah mudah**:
            1. **Brain Dump**: Ceritakan apa saja hal yang saat ini paling membebani pikiranmu.
            2. **Pilih 1 Hal Terpenting (The One Thing)**: Kita tentukan tugas mana yang jika selesai hari ini akan memberi dampak terbesar.
            3. **Jalankan 5 Menit Saja**: Cukup mulai kerjakan langkah pertamanya tanpa target harus langsung sempurna.

            Coba ceritakan, tugas atau proyek apa yang lagi kamu hadapi sekarang? Kita bedah bareng!
            """
            messages.append(MCPAIChatMessage(role: .assistant, content: reply))
            return
        }

        // Skenario Diskusi: Metode Belajar / Bekerja (Pomodoro, Time Blocking, dll)
        if lower.contains("metode") || lower.contains("teknik") || lower.contains("cara belajar") || lower.contains("cara fokus") || lower.contains("fokus") {
            let reply = """
            Ada 3 metode produktivitas terbaik yang bisa kamu terapkan langsung di aplikasi ini:

            🎯 **1. Teknik Pomodoro (Menu Fokus)**
            Kerja intens 25 menit ➔ Istirahat 5 menit. Sangat cocok saat sulit memulai tugas atau butuh konsentrasi mendalam.

            🐸 **2. Eat That Frog (Prioritas Tinggi)**
            Selesaikan tugas paling berat/menantang di pagi hari saat energi mental masih penuh.

            ⏱️ **3. Aturan 2 Menit (2-Minute Rule)**
            Jika suatu aktivitas bisa diselesaikan dalam < 2 menit (misal: balas email singkat, rapikan meja), kerjakan seketika!

            Mau kita coba terapkan salah satu metode ini untuk targetmu hari ini?
            """
            messages.append(MCPAIChatMessage(role: .assistant, content: reply))
            return
        }

        // Skenario Diskusi: Saran & Motivasi Umum
        if lower.contains("saran") || lower.contains("tips") || lower.contains("motivasi") || lower.contains("ide") {
            await executeProductivityAdviceTool(prompt: prompt, modelContext: modelContext)
            return
        }

        // Default Diskusi
        let reply = """
        Diskusi yang menarik! 💡

        Untuk produktivitas optimal, kamu bisa:
        • Diskusikan ide proyek atau tugas kuliah yang sedang kamu rancang.
        • Minta saran bagaimana membagi waktu antara kerja, belajar, dan istirahat.
        • Minta aku membuatkan to-do list terstruktur (contoh: *"Buat tugas Riset UI/UX prioritas tinggi"*).

        💡 *Tips: Kamu bisa menyambungkan Akun Google atau Gemini API Key di ikon gear ⚙️ pojok kanan atas untuk diskusi tak terbatas!*
        """
        messages.append(MCPAIChatMessage(role: .assistant, content: reply))
    }

    // MARK: - 🌐 Gemini LLM via Akun Google Login (User-Level OAuth)
    private func processWithGoogleUserAccount(prompt: String, modelContext: ModelContext) async {
        guard GoogleAuthManager.shared.isUserLoggedIn else {
            let reply = """
            🔒 **Akun Google Belum Terhubung**

            Untuk menggunakan Gemini langsung dari akun Google Anda:
            1. Buka tab **Profil** atau klik ikon ⚙️ Pengaturan di atas.
            2. Tekan tombol **"Sign in with Google"**.
            3. Setelah login, Gemini AI akan otomatis aktif menggunakan token akun Google Anda secara gratis!
            """
            messages.append(MCPAIChatMessage(role: .assistant, content: reply))
            return
        }

        do {
            let token = try await GoogleAuthManager.shared.getValidAccessToken()
            guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent") else {
                await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
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
                        Kamu adalah AI Productivity Buddy & Coach di aplikasi to-do list iOS.
                        Karaktermu: Ramah, bijak, solutif, menyemangati, dan bergaya ceria/modern.
                        Bantu pengguna berdiskusi waktu, fokus, dan pemecahan masalah produktivitas.
                        Jawab dalam format Markdown yang rapi dengan bullet points.
                        """
                    ]
                ]
            ]

            let requestBody: [String: Any] = [
                "contents": contentsPayload,
                "system_instruction": systemInstruction
            ]

            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
                await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            request.timeoutInterval = 25

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
                return
            }

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {

                let lowerPrompt = prompt.lowercased()
                if lowerPrompt.contains("buatkan tugas") || lowerPrompt.contains("jadwalkan tugas") || lowerPrompt.contains("tambahkan ke to-do") {
                    await executeCreateActivityTool(prompt: prompt, modelContext: modelContext)
                } else {
                    messages.append(MCPAIChatMessage(role: .assistant, content: text))
                }
            } else {
                await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
            }
        } catch {
            await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
        }
    }

    // MARK: - 🛠️ MCP Tool 1: create_activity
    private func executeCreateActivityTool(prompt: String, modelContext: ModelContext) async {
        var taskTitle = prompt
        let removeKeywords = ["buat tugas", "tambah tugas", "jadwalkan", "ingatkan untuk", "catat tugas", "tolong", "buat to do", "buat todo", "buatkan todo", "buatkan tugas", "tugas"]
        for kw in removeKeywords {
            taskTitle = taskTitle.replacingOccurrences(of: kw, with: "", options: .caseInsensitive)
        }
        taskTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if taskTitle.isEmpty { taskTitle = "Tugas Produktivitas Baru" }

        var priority = "Sedang"
        if prompt.localizedCaseInsensitiveContains("tinggi") || prompt.localizedCaseInsensitiveContains("penting") || prompt.localizedCaseInsensitiveContains("urgent") {
            priority = "Tinggi"
        } else if prompt.localizedCaseInsensitiveContains("rendah") || prompt.localizedCaseInsensitiveContains("santai") {
            priority = "Rendah"
        }

        var category = "Umum"
        if prompt.localizedCaseInsensitiveContains("coding") || prompt.localizedCaseInsensitiveContains("swift") || prompt.localizedCaseInsensitiveContains("bug") || prompt.localizedCaseInsensitiveContains("app") {
            category = "Coding"
        } else if prompt.localizedCaseInsensitiveContains("belajar") || prompt.localizedCaseInsensitiveContains("kuliah") || prompt.localizedCaseInsensitiveContains("buku") {
            category = "Belajar"
        } else if prompt.localizedCaseInsensitiveContains("kerja") || prompt.localizedCaseInsensitiveContains("meeting") || prompt.localizedCaseInsensitiveContains("proyek") {
            category = "Pekerjaan"
        } else if prompt.localizedCaseInsensitiveContains("olahraga") || prompt.localizedCaseInsensitiveContains("gym") || prompt.localizedCaseInsensitiveContains("lari") {
            category = "Kesehatan"
        } else if prompt.localizedCaseInsensitiveContains("beli") || prompt.localizedCaseInsensitiveContains("belanja") {
            category = "Belanja"
        }

        let subtasks = SmartTaskBreakdownService.shared.generateSuggestions(for: taskTitle, category: category)
        let subtasksList = subtasks.prefix(3).map { SubtaskItem(title: $0, isCompleted: false) }

        let newItem = Item(
            title: taskTitle.capitalized,
            notes: "Dibuat otomatis oleh AI Productivity Buddy (MCP)",
            timestamp: Date(),
            isCompleted: false,
            completedAt: nil,
            priority: priority,
            category: category,
            isRecurring: false,
            recurrenceRule: "Sekali Saja",
            customSoundName: nil,
            subtasks: Array(subtasksList),
            imageAttachmentData: nil
        )

        modelContext.insert(newItem)
        try? modelContext.save()
        lastCreatedItem = newItem

        HapticManager.shared.success()
        SoundManager.shared.playSuccessChime()

        let toolCall = MCPToolInvocation(
            name: "create_activity",
            argumentsSummary: "title: \"\(newItem.title)\", category: \"\(category)\", priority: \"\(priority)\", subtasks: \(subtasksList.count)",
            icon: "checkmark.seal.fill",
            badgeColorHex: "#6EE7B7"
        )

        let reply = "✅ **Tugas Baru Berhasil Dijadwalkan!**\n\n🎯 **\(newItem.title)**\n📁 Kategori: *\(category)* | ⚡ Prioritas: *\(priority)*\n📋 Termasuk **\(subtasksList.count) Subtask** otomatis yang siap dieksekusi!"

        messages.append(
            MCPAIChatMessage(
                role: .assistant,
                content: reply,
                toolCall: toolCall,
                toolResult: "Sukses tersimpan di SwiftData"
            )
        )
    }

    // MARK: - 🛠️ MCP Tool 2: get_today_summary
    private func executeGetTodaySummaryTool(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>()
        let allItems = (try? modelContext.fetch(descriptor)) ?? []

        let calendar = Calendar.current
        let todayItems = allItems.filter { calendar.isDateInToday($0.timestamp) }
        let completedToday = todayItems.filter { $0.isCompleted }.count
        let pendingToday = todayItems.filter { !$0.isCompleted }.count

        let habitDescriptor = FetchDescriptor<Habit>()
        let allHabits = (try? modelContext.fetch(habitDescriptor)) ?? []
        let activeHabits = allHabits.count

        let toolCall = MCPToolInvocation(
            name: "get_today_summary",
            argumentsSummary: "items: \(todayItems.count), habits: \(activeHabits)",
            icon: "chart.bar.xaxis",
            badgeColorHex: "#FFD166"
        )

        let reply = """
        📊 **Rangkuman Aktivitas Hari Ini**

        • ⏳ **Tugas Menunggu:** \(pendingToday) tugas
        • ✅ **Tugas Selesai:** \(completedToday) tugas
        • 🔄 **Kebiasaan Aktif:** \(activeHabits) kebiasaan

        \(pendingToday > 0 ? "🔥 *Fokus selesaikan tugas tertunda sebelum sore ya! Semangat!*" : "🎉 *Luar biasa! Semua tugas hari ini sudah terselesaikan dengan sempurna!*")
        """

        messages.append(
            MCPAIChatMessage(
                role: .assistant,
                content: reply,
                toolCall: toolCall,
                toolResult: "Total item: \(allItems.count)"
            )
        )
    }

    // MARK: - 🛠️ MCP Tool 3: create_habit
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

        let reply = "🌟 **Target Kebiasaan Baru Didaftarkan!**\n\n📌 **\(newHabit.title)**\n📅 Target: Harian\n🎨 Warna: Sky Blue\n\n*Konsistensi kecil setiap hari akan membawa hasil besar!*"

        messages.append(
            MCPAIChatMessage(
                role: .assistant,
                content: reply,
                toolCall: toolCall,
                toolResult: "Habit tersimpan di database"
            )
        )
    }

    // MARK: - 🛠️ MCP Tool 4: breakdown_complex_task
    private func executeBreakdownTaskTool(prompt: String) async {
        let taskTitle = prompt
            .replacingOccurrences(of: "pecah tugas", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "breakdown", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "tugas", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let suggestions = SmartTaskBreakdownService.shared.generateSuggestions(for: taskTitle)

        let toolCall = MCPToolInvocation(
            name: "breakdown_complex_task",
            argumentsSummary: "target: \"\(taskTitle.isEmpty ? "Tugas Utama" : taskTitle)\"",
            icon: "square.split.2x2.fill",
            badgeColorHex: "#FF99C8"
        )

        var listText = ""
        for (index, step) in suggestions.enumerated() {
            listText += "\n\(index + 1). 🔹 \(step)"
        }

        let reply = "🧩 **Rekomendasi Pemecahan Subtask:**\n\(listText)\n\n*Tips: Mulai dari langkah pertama dengan sesi Pomodoro 25 menit!*"

        messages.append(
            MCPAIChatMessage(
                role: .assistant,
                content: reply,
                toolCall: toolCall,
                toolResult: "\(suggestions.count) subtasks generated"
            )
        )
    }

    // MARK: - 🛠️ MCP Tool 5: get_productivity_advice
    private func executeProductivityAdviceTool(prompt: String, modelContext: ModelContext) async {
        let quotes = [
            "Gunakan **Teknik 2 Menit**: Jika suatu tugas butuh waktu kurang dari 2 menit, selesaikan sekarang juga tanpa menunda!",
            "Fokus pada **1 Tugas Prioritas Tinggi (Eat The Frog)** di pagi hari saat energimu berada di titik puncak.",
            "Gunakan **Pomodoro Timer (25 menit kerja, 5 menit istirahat)** untuk mempertahankan fokus tajam tanpa burnout.",
            "Kelompokkan tugas-tugas sejenis (*Batch Processing*) seperti membalas email atau merapikan to-do list di jam tertentu."
        ]
        let advice = quotes.randomElement() ?? quotes[0]

        let toolCall = MCPToolInvocation(
            name: "get_productivity_advice",
            argumentsSummary: "strategy: TimeManagement",
            icon: "lightbulb.fill",
            badgeColorHex: "#FFAA00"
        )

        let reply = "💡 **Tips Produktivitas Khusus untukmu:**\n\n\(advice)"

        messages.append(
            MCPAIChatMessage(
                role: .assistant,
                content: reply,
                toolCall: toolCall,
                toolResult: "Advice delivered"
            )
        )
    }

    // MARK: - ⚡ Ninerouter Multi-LLM Gateway (OpenAI Compatible)
    private func processWithNinerouter(
        prompt: String,
        apiKey: String,
        baseUrl: String,
        modelName: String,
        modelContext: ModelContext
    ) async {
        let endpoint = baseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/chat/completions"
        guard let url = URL(string: endpoint) else {
            await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
            return
        }

        var messagesPayload: [[String: String]] = [
            [
                "role": "system",
                "content": """
                Kamu adalah AI Productivity Buddy & Coach di aplikasi iOS dengan protokol MCP.
                Karaktermu: Sangat bersahabat, terstruktur, solutif, dan ceria.
                Bantu pengguna berdiskusi, brainstorming, memecah rencana tugas, dan mengatur jadwal.
                Jawab dalam format Markdown yang rapi.
                """
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
            await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
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
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
                return
            }

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let messageObj = firstChoice["message"] as? [String: Any],
               let text = messageObj["content"] as? String {

                let lowerPrompt = prompt.lowercased()
                if lowerPrompt.contains("buatkan tugas") || lowerPrompt.contains("jadwalkan tugas") || lowerPrompt.contains("tambahkan ke to-do") {
                    await executeCreateActivityTool(prompt: prompt, modelContext: modelContext)
                } else {
                    messages.append(MCPAIChatMessage(role: .assistant, content: text))
                }
            } else {
                await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
            }
        } catch {
            await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
        }
    }

    // MARK: - 🌐 Gemini LLM Integration with Full Multi-Turn Conversation History (API Key)
    private func processWithGeminiLLM(prompt: String, apiKey: String, modelContext: ModelContext) async {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)") else {
            await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
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
                    Kamu adalah AI Productivity Buddy & Coach di aplikasi to-do list iOS.
                    Karaktermu: Ramah, bijak, solutif, menyemangati, dan bergaya ceria/modern.
                    Bantu pengguna berdiskusi waktu, fokus, dan pemecahan masalah produktivitas.
                    Jawab dalam format Markdown yang rapi dengan bullet points.
                    """
                ]
            ]
        ]

        let requestBody: [String: Any] = [
            "contents": contentsPayload,
            "system_instruction": systemInstruction
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 20

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
                return
            }

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {

                let lowerPrompt = prompt.lowercased()
                if lowerPrompt.contains("buatkan tugas") || lowerPrompt.contains("jadwalkan tugas") || lowerPrompt.contains("tambahkan ke to-do") {
                    await executeCreateActivityTool(prompt: prompt, modelContext: modelContext)
                } else {
                    messages.append(MCPAIChatMessage(role: .assistant, content: text))
                }
            } else {
                await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
            }
        } catch {
            await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
        }
    }

    /// Bersihkan riwayat percakapan chat
    func clearMessages() {
        messages.removeAll()
        messages.append(
            MCPAIChatMessage(
                role: .assistant,
                content: "Hai! Percakapan telah direset. Mau kita diskusikan atau jadwalkan apa sekarang? ⚡"
            )
        )
    }
}
