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
        messages.append(
            MCPAIChatMessage(
                role: .assistant,
                content: """
                Hai! Aku **AI Productivity Buddy (MCP Universal)** ⚡

                Aku bisa mengontrol & mengakses **seluruh fitur aplikasi ini** lewat protokol MCP:
                • 📝 **Tugas**: Tambah, selesaikan, hapus, daftar tugas & bersihkan riwayat.
                • 🔄 **Habit Tracker**: Buat target kebiasaan baru, ceklis harian, & lihat streak.
                • ⏱️ **Fokus & Pomodoro**: Mulai/hentikan timer fokus (25m/50m) & Live Activity.
                • 🏃‍♂️ **Apple Health**: Cek langkah kaki, kalori, & durasi tidur hari ini.
                • 🛡️ **Screen Time**: Kunci aplikasi pengganggu (*App Shield*) saat mode fokus.
                • 🧩 **AI Planning**: Pecah ide besar jadi subtasks atau buat rencana proyek utuh!

                Mau kita atur atau kerjakan apa sekarang?
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

    // MARK: - ⚡ Smart Local Engine & Full MCP Dispatcher
    private func processWithLocalMCP(prompt: String, modelContext: ModelContext) async {
        try? await Task.sleep(nanoseconds: 300_000_000)
        let lower = prompt.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // 0. Sapaan & Obrolan Santai (Greetings & Small Talk)
        if lower == "halo" || lower == "hai" || lower == "hi" || lower == "hey" || lower == "hei" || lower.hasPrefix("halo") || lower.hasPrefix("hai ") || lower.hasPrefix("hi ") {
            let greetings = [
                "Halo juga! Senang bisa menyapamu! Ada tugas atau fokus yang ingin kita kerjakan hari ini? 😊",
                "Hai! Siap menjalani hari produktif? Mau aku bantu buat jadwal, mulai pomodoro, atau cek data kesehatanmu? ✨",
                "Halo! Aku AI Productivity Buddy-mu. Katakan saja apa yang perlu diatur di aplikasi ini! 🚀"
            ]
            let reply = greetings.randomElement() ?? greetings[0]
            messages.append(MCPAIChatMessage(role: .assistant, content: reply))
            return
        }

        if lower.contains("selamat pagi") || lower.contains("pagi") && lower.count < 10 {
            messages.append(MCPAIChatMessage(role: .assistant, content: "Selamat pagi! ☀️ Mari mulai hari dengan menetapkan 1 tugas paling penting hari ini. Mau aku bantu jadwalkan?"))
            return
        }
        if lower.contains("selamat siang") || lower.contains("siang") && lower.count < 10 {
            messages.append(MCPAIChatMessage(role: .assistant, content: "Selamat siang! 🌤️ Jangan lupa istirahat sejenak dan minum air ya. Mau mulai sesi fokus 25 menit setelah makan siang?"))
            return
        }
        if lower.contains("selamat malam") || lower.contains("malam") && lower.count < 10 {
            messages.append(MCPAIChatMessage(role: .assistant, content: "Selamat malam! 🌙 Waktunya evaluasi aktivitas hari ini. Mau aku rangkumkan semua tugas yang sudah selesai?"))
            return
        }
        if lower.contains("apa kabar") || lower.contains("gimana kabarmu") {
            messages.append(MCPAIChatMessage(role: .assistant, content: "Aku selalu siap dan berenergi penuh untuk membantumu tetap produktif! Bagaimana denganmu hari ini? Ada yang bisa kubantu? ⚡"))
            return
        }
        if lower.contains("siapa kamu") || lower.contains("kamu siapa") || lower.contains("tentang kamu") {
            let reply = """
            Aku adalah **AI Productivity Buddy** yang terintegrasi dengan protokol **MCP (Model Context Protocol)** di aplikasi ini 🤖

            Aku dirancang untuk membantumu mengelola waktu, tugas, kebiasaan, hingga menjaga fokus dengan langsung berinteraksi dengan fitur-fitur iOS di aplikasi ini.
            """
            messages.append(MCPAIChatMessage(role: .assistant, content: reply))
            return
        }
        if lower.contains("bisa apa") || lower.contains("fitur apa") || lower.contains("bantu apa") {
            let reply = """
            Aku bisa melakukan banyak hal langsung di aplikasi ini:
            • 📝 **Tugas**: *"Buat tugas coding Swift prioritas tinggi"* atau *"Selesaikan tugas riset"*
            • ⏱️ **Fokus & Pomodoro**: *"Mulai fokus 25 menit"* atau *"Stop pomodoro"*
            • 🏃‍♂️ **Kesehatan**: *"Cek data langkah & kalori hari ini"*
            • 🔄 **Habit Tracker**: *"Ceklis habit membaca buku"* atau *"Buat habit olahraga"*
            • 🛡️ **Screen Time**: *"Kunci aplikasi pengganggu"* saat mode fokus
            • 🚀 **Proyek**: *"Buat rencana proyek website baru"*
            • 📊 **Rangkuman**: *"Rangkum aktivitas hari ini"*
            """
            messages.append(MCPAIChatMessage(role: .assistant, content: reply))
            return
        }
        if lower.contains("terima kasih") || lower.contains("makasih") || lower.contains("thanks") || lower.contains("thank you") {
            messages.append(MCPAIChatMessage(role: .assistant, content: "Sama-sama! Senang bisa membantu. Sukses selalu untuk aktivitasmu! 🔥"))
            return
        }

        // 1. Pomodoro / Fokus Timer Tools
        if lower.contains("mulai pomodoro") || lower.contains("mulai fokus") || lower.contains("fokus 25") || lower.contains("fokus 50") || lower.contains("start timer") || lower.contains("mulai timer") {
            await executeStartPomodoroTool(prompt: prompt)
            return
        }
        if lower.contains("stop pomodoro") || lower.contains("hentikan pomodoro") || lower.contains("stop fokus") || lower.contains("hentikan fokus") || lower.contains("stop timer") || lower.contains("reset timer") {
            await executeStopPomodoroTool()
            return
        }
        if lower.contains("status pomodoro") || lower.contains("sisa waktu fokus") || lower.contains("status fokus") {
            await executeGetFocusStatusTool()
            return
        }

        // 2. HealthKit & Kebugaran Tools
        if lower.contains("langkah") || lower.contains("kalori") || lower.contains("tidur") || lower.contains("kesehatan") || lower.contains("health") || lower.contains("workout") {
            await executeGetHealthStatsTool()
            return
        }

        // 3. Screen Time & App Shield Tools
        if lower.contains("kunci aplikasi") || lower.contains("aktifkan shield") || lower.contains("mode perisai") || lower.contains("blokir aplikasi") || lower.contains("buka kunci aplikasi") || lower.contains("matikan shield") {
            await executeToggleAppShieldTool(prompt: prompt)
            return
        }
        if lower.contains("screen time") || lower.contains("batas layar") || lower.contains("status shield") {
            await executeGetScreenTimeStatusTool()
            return
        }

        // 4. Habit Tracker Tools
        if lower.contains("ceklis habit") || lower.contains("centang habit") || lower.contains("sudah habit") || lower.contains("log habit") || lower.contains("selesai habit") || (lower.contains("sudah") && (lower.contains("baca") || lower.contains("minum") || lower.contains("olahraga"))) {
            await executeLogHabitCheckInTool(prompt: prompt, modelContext: modelContext)
            return
        }
        if lower.contains("buat habit") || lower.contains("tambah habit") || lower.contains("kebiasaan baru") || lower.contains("rutinitas baru") {
            await executeCreateHabitTool(prompt: prompt, modelContext: modelContext)
            return
        }
        if lower.contains("daftar habit") || lower.contains("lihat habit") || lower.contains("semua habit") || lower.contains("kebiasaan saya") {
            await executeListHabitsTool(modelContext: modelContext)
            return
        }
        if lower.contains("hapus habit") || lower.contains("delete habit") {
            await executeDeleteHabitTool(prompt: prompt, modelContext: modelContext)
            return
        }

        // 5. Activity / To-Do Tasks Tools
        if lower.contains("selesaikan tugas") || lower.contains("tandai selesai") || lower.contains("ceklis tugas") || lower.contains("tugas selesai") {
            await executeCompleteActivityTool(prompt: prompt, modelContext: modelContext)
            return
        }
        if lower.contains("hapus tugas") || lower.contains("delete tugas") || lower.contains("buang tugas") {
            await executeDeleteActivityTool(prompt: prompt, modelContext: modelContext)
            return
        }
        if lower.contains("bersihkan selesai") || lower.contains("hapus tugas selesai") || lower.contains("clear completed") {
            await executeClearCompletedActivitiesTool(modelContext: modelContext)
            return
        }
        if lower.contains("daftar tugas") || lower.contains("lihat tugas") || lower.contains("semua tugas") || lower.contains("tugas penting") || lower.contains("tugas tertunda") {
            await executeListActivitiesTool(prompt: prompt, modelContext: modelContext)
            return
        }
        if lower.contains("buat rencana proyek") || lower.contains("proyek baru") || lower.contains("jadwalkan proyek") {
            await executeCreateProjectPlanTool(prompt: prompt, modelContext: modelContext)
            return
        }
        if lower.contains("buat tugas") || lower.contains("tambah tugas") || lower.contains("jadwalkan") || lower.contains("ingatkan") || lower.contains("catat tugas") || (lower.contains("buatkan") && lower.contains("todo")) {
            await executeCreateActivityTool(prompt: prompt, modelContext: modelContext)
            return
        }

        // 6. Summary & Breakdown Tools
        if lower.contains("rangkum") || lower.contains("ringkas") || lower.contains("jadwal hari ini") || lower.contains("status tugas") || lower.contains("progres hari ini") {
            await executeGetTodaySummaryTool(modelContext: modelContext)
            return
        }
        if lower.contains("pecah tugas") || lower.contains("breakdown") || lower.contains("bagi tugas") || lower.contains("subtask") {
            await executeBreakdownTaskTool(prompt: prompt)
            return
        }

        // 7. Coaching & Tips
        if lower.contains("bingung") || lower.contains("pusing") || lower.contains("overwhelmed") || lower.contains("malas") || lower.contains("menunda") {
            let reply = """
            Tenang, wajar banget kalau merasa bingung atau kewalahan saat banyak hal yang harus dikerjakan! 🌿

            Mari kita urai bersama dengan **3 langkah mudah**:
            1. **Brain Dump**: Ceritakan apa yang ada di pikiranmu.
            2. **Pecah Jadi Subtasks**: Minta aku *"Pecah tugas [nama tugas]"*.
            3. **Mulai Pomodoro 25 Menit**: Cukup ketik *"Mulai fokus 25 menit"*.

            Tugas apa yang ingin kita mulai bedah sekarang?
            """
            messages.append(MCPAIChatMessage(role: .assistant, content: reply))
            return
        }

        if lower.contains("saran") || lower.contains("tips") || lower.contains("motivasi") {
            await executeProductivityAdviceTool(prompt: prompt, modelContext: modelContext)
            return
        }

        // Default Respon yang Ramah & Interaktif
        let reply = """
        Aku mendengarkanmu! 💡

        Kamu bisa mengajakku berdiskusi seputar produktivitas atau meminta aksi langsung:
        • *"Buat tugas Riset UI/UX prioritas tinggi"*
        • *"Mulai fokus 25 menit tugas Swift"*
        • *"Cek data kesehatan & langkah hari ini"*
        • *"Ceklis habit membaca buku"*
        • *"Kunci aplikasi pengganggu"*
        • *"Rangkum seluruh jadwal hari ini"*
        """
        messages.append(MCPAIChatMessage(role: .assistant, content: reply))
    }

    // MARK: - 🌐 Gemini LLM via Akun Google Login (OAuth Multi-Turn)
    private func processWithGoogleUserAccount(prompt: String, modelContext: ModelContext) async {
        guard GoogleAuthManager.shared.isUserLoggedIn else {
            let reply = """
            🔒 **Akun Google Belum Terhubung**

            Untuk menggunakan Gemini langsung dari akun Google Anda:
            1. Buka tab **Profil** atau klik ikon ⚙️ Pengaturan di atas.
            2. Tekan tombol **"Sign in with Google"**.
            3. Setelah login, Gemini AI akan otomatis aktif!
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
                        Kamu adalah AI Productivity Buddy & Universal MCP Engine di aplikasi to-do list iOS.
                        Karaktermu: Sangat bersahabat, terstruktur, energik, dan solutif.
                        Jika pengguna menyapa (seperti 'Halo', 'Hai'), balaslah dengan ramah dan tanyakan apa yang bisa kamu bantu.
                        Aplikasi ini memiliki fitur lengkap: Tasks (CRUD), Habits (Tracking & Check-in), Pomodoro Timer, HealthKit (Langkah & Tidur), dan Screen Time App Shield.
                        Jika pengguna meminta aksi aplikasi, jawab dengan jelas dan informasikan bahwa aksi tersebut diproses lewat MCP Tool.
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
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = json["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first,
                   let content = firstCandidate["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let text = parts.first?["text"] as? String {

                    await dispatchLocalActionIfDetected(prompt: prompt, modelContext: modelContext, fallbackText: text)
                    return
                }
            }

            // Jika API Google mengembalikan pembatasan OAuth, gunakan respons smart local conversational
            await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
        } catch {
            await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
        }
    }

    // MARK: - 🌐 Gemini LLM (API Key)
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
                    "text": "Kamu adalah AI Productivity Buddy & Universal MCP Engine di aplikasi to-do list iOS. Format respon Markdown rapi."
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

                await dispatchLocalActionIfDetected(prompt: prompt, modelContext: modelContext, fallbackText: text)
            } else {
                await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
            }
        } catch {
            await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
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
            await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
            return
        }

        var messagesPayload: [[String: String]] = [
            ["role": "system", "content": "Kamu adalah AI Productivity Buddy & Universal MCP Engine di aplikasi iOS. Format Markdown rapi."]
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

                await dispatchLocalActionIfDetected(prompt: prompt, modelContext: modelContext, fallbackText: text)
            } else {
                await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
            }
        } catch {
            await processWithLocalMCP(prompt: prompt, modelContext: modelContext)
        }
    }

    private func dispatchLocalActionIfDetected(prompt: String, modelContext: ModelContext, fallbackText: String) async {
        let lower = prompt.lowercased()
        if lower.contains("buat tugas") || lower.contains("jadwalkan tugas") || lower.contains("tambah tugas") {
            await executeCreateActivityTool(prompt: prompt, modelContext: modelContext)
        } else if lower.contains("buat habit") || lower.contains("tambah habit") {
            await executeCreateHabitTool(prompt: prompt, modelContext: modelContext)
        } else if lower.contains("mulai pomodoro") || lower.contains("mulai fokus") {
            await executeStartPomodoroTool(prompt: prompt)
        } else if lower.contains("langkah") || lower.contains("kesehatan") || lower.contains("tidur") {
            await executeGetHealthStatsTool()
        } else {
            messages.append(MCPAIChatMessage(role: .assistant, content: fallbackText))
        }
    }

    // MARK: - 🛠️ TOOL 1: create_activity
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
            argumentsSummary: "title: \"\(newItem.title)\", category: \"\(category)\", priority: \"\(priority)\"",
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

    // MARK: - 🛠️ TOOL 2: complete_activity
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

    // MARK: - 🛠️ TOOL 3: delete_activity
    private func executeDeleteActivityTool(prompt: String, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []

        var targetItem: Item? = nil
        let cleanedPrompt = prompt.lowercased()
        for item in items {
            if cleanedPrompt.contains(item.title.lowercased()) {
                targetItem = item
                break
            }
        }

        guard let itemToDelete = targetItem else {
            messages.append(MCPAIChatMessage(role: .assistant, content: "ℹ️ Tidak menemukan tugas yang cocok dengan kata kunci tersebut."))
            return
        }

        let deletedTitle = itemToDelete.title
        modelContext.delete(itemToDelete)
        try? modelContext.save()

        HapticManager.shared.impact(style: .medium)

        let toolCall = MCPToolInvocation(
            name: "delete_activity",
            argumentsSummary: "title: \"\(deletedTitle)\"",
            icon: "trash.fill",
            badgeColorHex: "#FF99C8"
        )

        messages.append(MCPAIChatMessage(role: .assistant, content: "🗑️ Tugas **\"\(deletedTitle)\"** telah dihapus dari daftar.", toolCall: toolCall, toolResult: "Deleted"))
    }

    // MARK: - 🛠️ TOOL 4: list_activities
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

    // MARK: - 🛠️ TOOL 5: clear_completed_activities
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

    // MARK: - 🛠️ TOOL 6: start_pomodoro
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

    // MARK: - 🛠️ TOOL 7: stop_pomodoro
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

    // MARK: - 🛠️ TOOL 8: get_focus_status
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

    // MARK: - 🛠️ TOOL 9: get_health_stats
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

    // MARK: - 🛠️ TOOL 10: toggle_app_shield
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

    // MARK: - 🛠️ TOOL 11: get_screentime_status
    private func executeGetScreenTimeStatusTool() async {
        let manager = ScreenTimeManager.shared
        let toolCall = MCPToolInvocation(
            name: "get_screentime_status",
            argumentsSummary: "authorized: \(manager.isAuthorized), shieldActive: \(manager.isShieldActive)",
            icon: "hourglass",
            badgeColorHex: "#BDB2FF"
        )

        let reply = """
        📱 **Status Screen Time & Batas Layar:**
        • Izin Screen Time: **\(manager.isAuthorized ? "Disetujui ✅" : "Belum Aktif ⚠️")**
        • Mode Perisai (*Shield*): **\(manager.isShieldActive ? "Terkunci 🔒" : "Terbuka 🔓")**
        • Batas Durasi Harian: **\(manager.isDailyLimitEnabled ? "Aktif (\(manager.dailyLimitMinutes) mnt)" : "Nonaktif")**
        """
        messages.append(MCPAIChatMessage(role: .assistant, content: reply, toolCall: toolCall, toolResult: "Retrieved"))
    }

    // MARK: - 🛠️ TOOL 12: create_habit
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
        messages.append(MCPAIChatMessage(role: .assistant, content: reply, toolCall: toolCall, toolResult: "Habit saved"))
    }

    // MARK: - 🛠️ TOOL 13: log_habit_checkin
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

    // MARK: - 🛠️ TOOL 14: list_habits
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

    // MARK: - 🛠️ TOOL 15: delete_habit
    private func executeDeleteHabitTool(prompt: String, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Habit>()
        let habits = (try? modelContext.fetch(descriptor)) ?? []

        var target: Habit? = nil
        let cleanedPrompt = prompt.lowercased()
        for h in habits {
            if cleanedPrompt.contains(h.title.lowercased()) {
                target = h
                break
            }
        }

        guard let habitToDelete = target else {
            messages.append(MCPAIChatMessage(role: .assistant, content: "ℹ️ Tidak menemukan habit yang cocok untuk dihapus."))
            return
        }

        let title = habitToDelete.title
        modelContext.delete(habitToDelete)
        try? modelContext.save()

        let toolCall = MCPToolInvocation(
            name: "delete_habit",
            argumentsSummary: "title: \"\(title)\"",
            icon: "trash.fill",
            badgeColorHex: "#FF99C8"
        )

        messages.append(MCPAIChatMessage(role: .assistant, content: "🗑️ Kebiasaan **\"\(title)\"** telah dihapus.", toolCall: toolCall, toolResult: "Deleted"))
    }

    // MARK: - 🛠️ TOOL 16: create_project_plan
    private func executeCreateProjectPlanTool(prompt: String, modelContext: ModelContext) async {
        var projectTitle = prompt.replacingOccurrences(of: "buat rencana proyek", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "proyek baru", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if projectTitle.isEmpty { projectTitle = "Proyek Aplikasi Baru" }

        let task1 = Item(title: "Fase 1: Riset & Brainstorming \(projectTitle)", notes: "Perencanaan awal proyek", timestamp: Date(), priority: "Tinggi", category: "Pekerjaan")
        let task2 = Item(title: "Fase 2: Desain UI & Wireframing \(projectTitle)", notes: "Pembuatan mock up & prototype", timestamp: Date().addingTimeInterval(86400), priority: "Sedang", category: "Pekerjaan")
        let task3 = Item(title: "Fase 3: Implementasi & Coding \(projectTitle)", notes: "Eksekusi kode inti", timestamp: Date().addingTimeInterval(86400 * 2), priority: "Tinggi", category: "Coding")
        let task4 = Item(title: "Fase 4: Testing & Review \(projectTitle)", notes: "Uji coba dan evaluasi akhir", timestamp: Date().addingTimeInterval(86400 * 3), priority: "Sedang", category: "Pekerjaan")

        modelContext.insert(task1)
        modelContext.insert(task2)
        modelContext.insert(task3)
        modelContext.insert(task4)
        try? modelContext.save()

        HapticManager.shared.success()

        let toolCall = MCPToolInvocation(
            name: "create_project_plan",
            argumentsSummary: "project: \"\(projectTitle)\", tasksCreated: 4",
            icon: "folder.badge.plus",
            badgeColorHex: "#6EE7B7"
        )

        let reply = """
        🚀 **Rencana Proyek Berhasil Dibuat (4 Jadwal Otomatis)!**

        📁 **\(projectTitle)**
        1. 🔴 **Fase 1: Riset & Brainstorming** (Hari Ini)
        2. 🟡 **Fase 2: Desain UI & Wireframing** (Besok)
        3. 🔴 **Fase 3: Implementasi & Coding** (+2 Hari)
        4. 🟡 **Fase 4: Testing & Review** (+3 Hari)

        Semua tugas telah masuk ke jadwalmu dan siap dieksekusi!
        """
        messages.append(MCPAIChatMessage(role: .assistant, content: reply, toolCall: toolCall, toolResult: "4 tasks inserted"))
    }

    // MARK: - 🛠️ TOOL 17: get_today_summary
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

    // MARK: - 🛠️ TOOL 18: breakdown_complex_task
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

    // MARK: - 🛠️ TOOL 19: get_productivity_advice
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

    /// Bersihkan riwayat percakapan chat
    func clearMessages() {
        messages.removeAll()
        messages.append(
            MCPAIChatMessage(
                role: .assistant,
                content: "Hai! Percakapan telah direset. Mau kita diskusikan atau jalankan aksi MCP apa sekarang? ⚡"
            )
        )
    }
}
