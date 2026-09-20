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

// MARK: - Model Provider AI
enum AIProviderType: String, CaseIterable, Identifiable {
    case googleAccount = "google_account"
    case geminiApiKey = "gemini_api_key"
    case ninerouter = "ninerouter"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .googleAccount: return "Akun Google Pribadi (Gemini Web MCP)"
        case .geminiApiKey: return "Gemini 1.5 Flash (API Key)"
        case .ninerouter: return "OpenRouter / Ninerouter"
        }
    }
}

// MARK: - Model Proposal Tindakan Interaktif
struct AIActionProposal: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let targetDate: Date
    let priority: String
    let category: String
    let subtasks: [String]
}

// MARK: - Model Tombol Aksi Cepat Pesan Awal (Welcome Quick Actions)
struct WelcomeActionButton: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let prompt: String
    let icon: String
    let colorHex: String
}

// MARK: - Model Pesan AI (Rich Message dengan MCP Tool Calls & Interactivity)
struct AIMessage: Identifiable, Equatable {
    let id = UUID()
    let isUser: Bool
    var content: String
    var toolCall: MCPToolInvocation? = nil
    var toolResult: String? = nil
    var proposal: AIActionProposal? = nil
    var quickActionButtons: [WelcomeActionButton]? = nil
    var isStreaming: Bool = false
    let timestamp: Date = Date()
}

// MARK: - Model Invokasi MCP Tool
struct MCPToolInvocation: Equatable {
    let name: String
    let argumentsSummary: String
    let icon: String
    let badgeColorHex: String
}

// MARK: - Layanan Pusat AI & MCP Hub
@MainActor
final class MCPAIAssistantService: ObservableObject {
    static let shared = MCPAIAssistantService()

    @Published var messages: [AIMessage] = []
    @Published var isProcessing: Bool = false
    @Published var activeToolName: String? = nil

    private init() {
        setupWelcomeMessage()
    }

    // MARK: - Welcome Greeting Bersih Tanpa Emoticon
    func setupWelcomeMessage() {
        if messages.isEmpty {
            let welcomeButtons: [WelcomeActionButton] = [
                WelcomeActionButton(
                    title: "Daftar Tugas Hari Ini",
                    prompt: "Cari tugas hari ini yang belum selesai",
                    icon: "magnifyingglass",
                    colorHex: "#93C5FD"
                ),
                WelcomeActionButton(
                    title: "Jadwal Belajar Bertahap",
                    prompt: "Tolong buatkan task belajar bahasa inggris secara bertahap dan terjadwal, materinya kamu yang tentukan",
                    icon: "book.fill",
                    colorHex: "#6EE7B7"
                ),
                WelcomeActionButton(
                    title: "AI Schedule Rebalance",
                    prompt: "Tata ulang jadwal yang terlewat atau bertabrakan",
                    icon: "wand.and.stars",
                    colorHex: "#FDBA74"
                ),
                WelcomeActionButton(
                    title: "Mulai Pomodoro (25m)",
                    prompt: "Mulai sesi fokus pomodoro 25 menit",
                    icon: "timer",
                    colorHex: "#FCA5A5"
                ),
                WelcomeActionButton(
                    title: "Ceklis Habit Hari Ini",
                    prompt: "Ceklis kebiasaan aktif saya hari ini",
                    icon: "flame.fill",
                    colorHex: "#FDBA74"
                ),
                WelcomeActionButton(
                    title: "Cek Data Kebugaran",
                    prompt: "Tampilkan ringkasan aktivitas dan langkah HealthKit",
                    icon: "heart.fill",
                    colorHex: "#F9A8D4"
                ),
                WelcomeActionButton(
                    title: "Kunci Aplikasi Distraksi",
                    prompt: "Kunci aplikasi pengganggu sekarang",
                    icon: "shield.lefthalf.filled",
                    colorHex: "#93C5FD"
                ),
                WelcomeActionButton(
                    title: "Bersihkan Tugas Selesai",
                    prompt: "Bersihkan semua tugas yang sudah selesai",
                    icon: "trash.slash.fill",
                    colorHex: "#6EE7B7"
                )
            ]

            let welcomeText = """
            **Halo! Saya Asisten AI Produktivitas Anda.**

            Saya terhubung langsung dengan database lokal aplikasi Anda untuk mencari, menambah, mencentang, memindahkan jadwal, memecah tugas menjadi subtask, hingga memulai sesi fokus Pomodoro.

            Pilih salah satu aksi cepat di bawah atau ketik langsung permintaan Anda!
            """

            messages.append(
                AIMessage(
                    isUser: false,
                    content: welcomeText,
                    quickActionButtons: welcomeButtons
                )
            )
        }
    }

    func clearHistory() {
        messages.removeAll()
        setupWelcomeMessage()
    }

    // MARK: - Mengirim Pesan & Eksekusi MCP Tool Router
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

        // Tambahkan pesan user
        messages.append(AIMessage(isUser: true, content: trimmed))
        isProcessing = true

        defer {
            isProcessing = false
            activeToolName = nil
        }

        let lower = trimmed.lowercased()

        // 1. Deteksi Permintaan Jadwal / Kurikulum Bertahap Multi-Tugas (Multi-Step Task Generation)
        if isMultiStepPlanIntent(lower) {
            await executeMultiStepTaskGeneration(
                prompt: trimmed,
                provider: provider,
                apiKey: apiKey,
                ninerouterBaseUrl: ninerouterBaseUrl,
                ninerouterModel: ninerouterModel,
                modelContext: modelContext
            )
            return
        }

        // 2. Deteksi Ceklis / Tandai Selesai Tugas (Complete Task Tool)
        if isCompleteTaskIntent(lower) {
            await executeCompleteTaskTool(prompt: trimmed, modelContext: modelContext)
            return
        }

        // 3. Deteksi Pindahkan / Ubah Waktu Tugas (Reschedule Task Tool)
        if isRescheduleTaskIntent(lower) {
            await executeRescheduleTaskTool(prompt: trimmed, modelContext: modelContext)
            return
        }

        // 4. Deteksi Hapus Tugas Spesifik (Delete Task Tool)
        if isDeleteTaskIntent(lower) {
            await executeDeleteTaskTool(prompt: trimmed, modelContext: modelContext)
            return
        }

        // 5. Deteksi Pecah Tugas Menjadi Subtasks (Breakdown Task Tool)
        if isBreakdownTaskIntent(lower) {
            await executeBreakdownTaskTool(prompt: trimmed, modelContext: modelContext)
            return
        }

        // 6. Deteksi Pencarian / Tanya Daftar Tugas Aktif (Search / Query Tasks Tool)
        if isSearchTasksIntent(lower) {
            await executeSearchTasksTool(prompt: trimmed, modelContext: modelContext)
            return
        }

        // 7. Deteksi Pembuatan & Penjadwalan Tugas Tunggal Langsung (Single Task Creation)
        let parsed = NaturalTimeParser.parse(from: trimmed)
        if isSingleTaskCreationIntent(lower, parsed: parsed) {
            let descriptor = FetchDescriptor<Item>()
            let items = (try? modelContext.fetch(descriptor)) ?? []
            await executeDirectCreateTaskTool(parsed: parsed, modelContext: modelContext, existingItems: items)
            return
        }

        // 8. Deteksi & Eksekusi Local MCP Tools Lainnya
        // AI Weekly Review & Infographic Report
        if lower.contains("mingguan") || lower.contains("weekly review") || lower.contains("evaluasi") || lower.contains("rapor") {
            await executeWeeklyReviewTool(modelContext: modelContext)
            return
        }

        // Habit Recommendations
        if lower.contains("rekomendasi habit") || lower.contains("saran kebiasaan") || lower.contains("kebiasaan baru") {
            await executeHabitRecommenderTool(modelContext: modelContext)
            return
        }

        // Habit Streak Radar
        if lower.contains("streak") || lower.contains("radar") || lower.contains("terancam") {
            await executeStreakRiskTool(modelContext: modelContext)
            return
        }

        // AI Schedule Rebalance
        if lower.contains("rebalance") || lower.contains("tata ulang") || lower.contains("jadwal ulang") || lower.contains("tabrakan") {
            await executeRebalanceScheduleTool(modelContext: modelContext)
            return
        }

        // Pomodoro Timer Control
        if lower.contains("pomodoro") || lower.contains("fokus") || lower.contains("timer") {
            await executePomodoroTool(prompt: trimmed)
            return
        }

        // Habit Check-In
        if lower.contains("ceklis habit") || lower.contains("checkin") || lower.contains("kebiasaan") {
            await executeHabitCheckInTool(prompt: trimmed, modelContext: modelContext)
            return
        }

        // Ringkasan Aktivitas & HealthKit
        if lower.contains("langkah") || lower.contains("kesehatan") || lower.contains("health") || lower.contains("ringkasan") {
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

        // 9. Jika Bukan Tools Lokal, Teruskan ke LLM (Gemini Headless / OpenRouter API)
        await sendToAIEngine(
            prompt: trimmed,
            provider: provider,
            apiKey: apiKey,
            ninerouterBaseUrl: ninerouterBaseUrl,
            ninerouterModel: ninerouterModel,
            modelContext: modelContext
        )
    }

    // MARK: - Intent Checkers
    private func isMultiStepPlanIntent(_ lower: String) -> Bool {
        let multiKeywords = [
            "bertahap", "terjadwal", "materinya kamu yang tentukan", "materi kamu yang tentukan",
            "kurikulum", "roadmap", "silabus", "rencana belajar", "secara berkala",
            "beberapa hari", "langkah demi langkah", "step by step", "tahapan",
            "jadwal belajar", "rancangkan jadwal", "susunkan rencana tugas", "rancangan tugas",
            "program belajar", "seri tugas", "buatkan jadwal bertahap", "buatkan task bertahap"
        ]
        return multiKeywords.contains { lower.contains($0) }
    }

    private func isCompleteTaskIntent(_ lower: String) -> Bool {
        let completeKeywords = [
            "selesaikan tugas", "ceklis tugas", "coret tugas", "tandai selesai",
            "task selesai", "tugas selesai", "complete task", "done tugas", "selesai tugas"
        ]
        return completeKeywords.contains { lower.contains($0) }
    }

    private func isRescheduleTaskIntent(_ lower: String) -> Bool {
        let rescheduleKeywords = [
            "pindahkan tugas", "ganti jam tugas", "ganti jadwal tugas", "undur tugas",
            "jadwal ulang tugas", "ubah waktu tugas", "reschedule task", "geser tugas", "pindah tugas"
        ]
        return rescheduleKeywords.contains { lower.contains($0) }
    }

    private func isDeleteTaskIntent(_ lower: String) -> Bool {
        let deleteKeywords = [
            "hapus tugas", "delete task", "buang tugas", "hilangkan tugas", "remove task"
        ]
        return deleteKeywords.contains { lower.contains($0) } && !lower.contains("selesai")
    }

    private func isBreakdownTaskIntent(_ lower: String) -> Bool {
        let breakdownKeywords = [
            "pecah tugas", "breakdown tugas", "bagi tugas", "buat subtask", "pecahkan tugas",
            "bagi menjadi langkah", "subtask untuk"
        ]
        return breakdownKeywords.contains { lower.contains($0) }
    }

    private func isSearchTasksIntent(_ lower: String) -> Bool {
        let searchKeywords = [
            "cari tugas", "apa saja tugas", "daftar tugas", "list tugas", "jadwal tugas",
            "cek tugas", "tugas hari ini", "tugas besok", "tugas belum selesai", "tugas aktif",
            "ada tugas apa", "tugas apa aja", "lihat tugas"
        ]
        return searchKeywords.contains { lower.contains($0) }
    }

    private func isSingleTaskCreationIntent(_ lower: String, parsed: ParsedNaturalSchedule) -> Bool {
        let taskKeywords = [
            "tambah", "tambahkan", "tambahin", "buat", "buatkan", "bikin", "bikinkan",
            "add task", "create task", "jadwalkan", "agendakan", "ingatkan",
            "catat", "masukkan", "remind", "task baru", "tugas baru", "to-do baru"
        ]
        let hasTaskKeyword = taskKeywords.contains { lower.contains($0) }
        let isAskingGeneralQuestion = lower.contains("bagaimana cara") || lower.contains("tips") || lower.contains("apa itu") || lower.contains("kenapa") || lower.contains("mengapa")
        return (hasTaskKeyword || parsed.hasExplicitTime) && !parsed.cleanText.isEmpty && !isAskingGeneralQuestion
    }

    // MARK: - MCP Tool: Search Tasks (Query & Filter Tasks from SwiftData)
    private func executeSearchTasksTool(prompt: String, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>(sortBy: [SortDescriptor(\.timestamp, order: .forward)])
        let allItems = (try? modelContext.fetch(descriptor)) ?? []

        let lower = prompt.lowercased()
        let calendar = Calendar.current
        let now = Date()

        let filteredItems: [Item]
        let filterDescription: String

        if lower.contains("hari ini") {
            filteredItems = allItems.filter { calendar.isDate($0.timestamp, inSameDayAs: now) }
            filterDescription = "Hari Ini"
        } else if lower.contains("besok") {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            filteredItems = allItems.filter { calendar.isDate($0.timestamp, inSameDayAs: tomorrow) }
            filterDescription = "Besok"
        } else if lower.contains("selesai") && !lower.contains("belum") {
            filteredItems = allItems.filter { $0.isCompleted }
            filterDescription = "Telah Selesai"
        } else if lower.contains("belum") || lower.contains("aktif") {
            filteredItems = allItems.filter { !$0.isCompleted }
            filterDescription = "Belum Selesai (Aktif)"
        } else {
            // Coba cari kata kunci spesifik
            let queryKeywords = lower
                .replacingOccurrences(of: "cari tugas", with: "")
                .replacingOccurrences(of: "daftar tugas", with: "")
                .replacingOccurrences(of: "list tugas", with: "")
                .replacingOccurrences(of: "cek tugas", with: "")
                .replacingOccurrences(of: "tugas", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !queryKeywords.isEmpty {
                filteredItems = allItems.filter {
                    $0.title.localizedCaseInsensitiveContains(queryKeywords) ||
                    $0.category.localizedCaseInsensitiveContains(queryKeywords)
                }
                filterDescription = "Kata Kunci '\(queryKeywords)'"
            } else {
                filteredItems = allItems.filter { !$0.isCompleted }
                filterDescription = "Semua Tugas Aktif"
            }
        }

        HapticManager.shared.impact(style: .light)

        let toolCall = MCPToolInvocation(
            name: "search_activities",
            argumentsSummary: "found: \(filteredItems.count) items (\(filterDescription))",
            icon: "magnifyingglass",
            badgeColorHex: "#93C5FD"
        )

        if filteredItems.isEmpty {
            let reply = """
            **Pencarian Tugas (\(filterDescription))**

            Tidak ditemukan tugas yang sesuai dengan kriteria tersebut. Daftar tugas Anda kosong atau sudah diselesaikan!
            """
            await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "0 items found")
            return
        }

        var taskListText = ""
        for item in filteredItems.prefix(8) {
            let statusIcon = item.isCompleted ? "✅" : "⏳"
            let timeStr = item.timestamp.formatted(date: .abbreviated, time: .shortened)
            taskListText += "\n\(statusIcon) **\(item.title)** (\(item.category))\n   • Waktu: \(timeStr) | Prioritas: \(item.priority)\n"
        }

        let reply = """
        **Hasil Pencarian Tugas (\(filterDescription)):**
        Ditemukan **\(filteredItems.count) tugas**:
        \(taskListText)
        *Tips: Anda bisa meminta saya mencentang, memindahkan jadwal, atau menghapus salah satu tugas di atas.*
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "\(filteredItems.count) items found")
    }

    // MARK: - MCP Tool: Complete Task (Ceklis / Selesaikan Tugas)
    private func executeCompleteTaskTool(prompt: String, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        let activeItems = items.filter { !$0.isCompleted }

        var targetQuery = prompt.lowercased()
            .replacingOccurrences(of: "selesaikan tugas", with: "")
            .replacingOccurrences(of: "ceklis tugas", with: "")
            .replacingOccurrences(of: "coret tugas", with: "")
            .replacingOccurrences(of: "tandai selesai", with: "")
            .replacingOccurrences(of: "selesai tugas", with: "")
            .replacingOccurrences(of: "complete task", with: "")
            .replacingOccurrences(of: "done tugas", with: "")
            .replacingOccurrences(of: "tugas", with: "")
            .replacingOccurrences(of: "task", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let matchedItem = activeItems.first { item in
            if targetQuery.isEmpty { return true }
            return item.title.localizedCaseInsensitiveContains(targetQuery) ||
                   targetQuery.localizedCaseInsensitiveContains(item.title)
        }

        guard let target = matchedItem else {
            let reply = """
            **Tugas Tidak Ditemukan**

            Tidak dapat menemukan tugas aktif yang cocok dengan \"\(targetQuery.isEmpty ? prompt : targetQuery)\". Pastikan judul tugas sesuai dengan yang ada di daftar tugas Anda.
            """
            await streamAssistantMessage(fullContent: reply)
            return
        }

        target.isCompleted = true
        target.completedAt = Date()
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        HapticManager.shared.success()
        SoundManager.shared.playSuccessChime()

        let toolCall = MCPToolInvocation(
            name: "complete_activity",
            argumentsSummary: "completed: \(target.title)",
            icon: "checkmark.circle.fill",
            badgeColorHex: "#6EE7B7"
        )

        let reply = """
        **Tugas Berhasil Diselesaikan! 🎉**

        • **Judul:** \(target.title)
        • **Kategori:** \(target.category)
        • **Waktu Selesai:** \(Date().formatted(date: .omitted, time: .shortened))

        Tugas telah dicoret dan statistik produktivitas Anda telah diperbarui!
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Completed \(target.title)")
    }

    // MARK: - MCP Tool: Reschedule Task (Pindahkan / Ubah Waktu Tugas)
    private func executeRescheduleTaskTool(prompt: String, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        let activeItems = items.filter { !$0.isCompleted }

        let parsedSchedule = NaturalTimeParser.parse(from: prompt)
        let newDate = parsedSchedule.targetDate

        var targetQuery = prompt.lowercased()
            .replacingOccurrences(of: "pindahkan tugas", with: "")
            .replacingOccurrences(of: "ganti jam tugas", with: "")
            .replacingOccurrences(of: "ganti jadwal tugas", with: "")
            .replacingOccurrences(of: "undur tugas", with: "")
            .replacingOccurrences(of: "jadwal ulang tugas", with: "")
            .replacingOccurrences(of: "ubah waktu tugas", with: "")
            .replacingOccurrences(of: "reschedule task", with: "")
            .replacingOccurrences(of: "geser tugas", with: "")
            .replacingOccurrences(of: "tugas", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let matchedItem = activeItems.first { item in
            if targetQuery.isEmpty { return true }
            return item.title.localizedCaseInsensitiveContains(targetQuery) ||
                   targetQuery.localizedCaseInsensitiveContains(item.title)
        }

        guard let target = matchedItem else {
            let reply = "Tidak dapat menemukan tugas yang cocok untuk dijadwalkan ulang. Silakan sebutkan nama tugas dengan jelas."
            await streamAssistantMessage(fullContent: reply)
            return
        }

        let oldDateFormatted = target.timestamp.formatted(date: .abbreviated, time: .shortened)
        target.timestamp = newDate
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        HapticManager.shared.success()

        let toolCall = MCPToolInvocation(
            name: "reschedule_activity",
            argumentsSummary: "shifted: \(target.title) to \(newDate.formatted(date: .abbreviated, time: .shortened))",
            icon: "calendar.badge.clock",
            badgeColorHex: "#FDBA74"
        )

        let reply = """
        **Jadwal Tugas Berhasil Diperbarui! ⏰**

        • **Judul:** \(target.title)
        • **Jadwal Semula:** \(oldDateFormatted)
        • **Jadwal Baru:** \(newDate.formatted(date: .complete, time: .shortened))

        Pengingat notifikasi dan kalender telah disesuaikan secara otomatis.
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Rescheduled \(target.title)")
    }

    // MARK: - MCP Tool: Delete Task (Hapus Tugas)
    private func executeDeleteTaskTool(prompt: String, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []

        var targetQuery = prompt.lowercased()
            .replacingOccurrences(of: "hapus tugas", with: "")
            .replacingOccurrences(of: "delete task", with: "")
            .replacingOccurrences(of: "buang tugas", with: "")
            .replacingOccurrences(of: "hilangkan tugas", with: "")
            .replacingOccurrences(of: "remove task", with: "")
            .replacingOccurrences(of: "tugas", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let matchedItem = items.first { item in
            if targetQuery.isEmpty { return false }
            return item.title.localizedCaseInsensitiveContains(targetQuery) ||
                   targetQuery.localizedCaseInsensitiveContains(item.title)
        }

        guard let target = matchedItem else {
            let reply = "Tidak dapat menemukan tugas dengan nama \"\(targetQuery)\" untuk dihapus."
            await streamAssistantMessage(fullContent: reply)
            return
        }

        let deletedTitle = target.title
        modelContext.delete(target)
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        SoundManager.shared.playPop()
        HapticManager.shared.warning()

        let toolCall = MCPToolInvocation(
            name: "delete_activity",
            argumentsSummary: "deleted: \(deletedTitle)",
            icon: "trash.fill",
            badgeColorHex: "#FCA5A5"
        )

        let reply = """
        **Tugas Berhasil Dihapus! 🗑️**

        Tugas **\"\(deletedTitle)\"** telah dihapus secara permanen dari daftar tugas Anda.
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Deleted \(deletedTitle)")
    }

    // MARK: - MCP Tool: Breakdown Task (Pecah Tugas Menjadi Subtasks)
    private func executeBreakdownTaskTool(prompt: String, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        let activeItems = items.filter { !$0.isCompleted }

        var targetQuery = prompt.lowercased()
            .replacingOccurrences(of: "pecah tugas", with: "")
            .replacingOccurrences(of: "breakdown tugas", with: "")
            .replacingOccurrences(of: "bagi tugas", with: "")
            .replacingOccurrences(of: "buat subtask untuk", with: "")
            .replacingOccurrences(of: "subtask untuk", with: "")
            .replacingOccurrences(of: "tugas", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let matchedItem = activeItems.first { item in
            if targetQuery.isEmpty { return true }
            return item.title.localizedCaseInsensitiveContains(targetQuery) ||
                   targetQuery.localizedCaseInsensitiveContains(item.title)
        }

        let targetTaskTitle = matchedItem?.title ?? (targetQuery.isEmpty ? "Aktivitas Fokus" : targetQuery)
        let generatedSubtasks = AITaskBreakdownService.shared.generateSubtasks(for: targetTaskTitle)

        let subtaskItems = generatedSubtasks.map { SubtaskItem(title: $0.title, isCompleted: false) }

        if let existing = matchedItem {
            existing.subtasks.append(contentsOf: subtaskItems)
        } else {
            let tagSuggestion = AITaskBreakdownService.shared.suggestTags(for: targetTaskTitle)
            let newItem = Item(
                title: targetTaskTitle,
                notes: "Dibuat dengan subtasks oleh AI Asisten",
                timestamp: Date(),
                isCompleted: false,
                completedAt: nil,
                priority: tagSuggestion.priority.rawValue,
                category: tagSuggestion.category.rawValue,
                isRecurring: false,
                recurrenceRule: "Sekali Saja",
                customSoundName: "cartoon_bell.caf",
                subtasks: subtaskItems,
                imageAttachmentData: nil
            )
            modelContext.insert(newItem)
        }

        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        HapticManager.shared.success()
        SoundManager.shared.playSuccessChime()

        let toolCall = MCPToolInvocation(
            name: "breakdown_activity",
            argumentsSummary: "added: \(subtaskItems.count) subtasks to \(targetTaskTitle)",
            icon: "list.bullet.indent",
            badgeColorHex: "#FDE047"
        )

        var subtasksListText = ""
        for s in subtaskItems {
            subtasksListText += "\n• [ ] **\(s.title)**"
        }

        let reply = """
        **Tugas Berhasil Dipecah Menjadi Subtasks! 🧩**

        Tugas **\"\(targetTaskTitle)\"** kini memiliki **\(subtaskItems.count) checklist subtask baru**:
        \(subtasksListText)

        Semua subtask langsung terhubung dan dapat diceklis di kartu tugas utama!
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Added \(subtaskItems.count) subtasks")
    }

    // MARK: - Eksekusi Pembuatan & Penjadwalan Tugas Bertahap Otomatis (Multi-Step Tasks to SwiftData)
    private func executeMultiStepTaskGeneration(
        prompt: String,
        provider: AIProviderType,
        apiKey: String,
        ninerouterBaseUrl: String,
        ninerouterModel: String,
        modelContext: ModelContext
    ) async {
        let systemInstruction = """
        Kamu adalah Asisten AI Kurikulum & Perencana Tugas Produktivitas iOS.
        Pengguna meminta kamu menyusunkan rencana tugas/kurikulum yang bertahap dan terjadwal, dengan materi yang kamu tentukan secara optimal.

        ATURAN STRUKTUR OUTPUT (WAJIB):
        1. Berikan kalimat pembuka singkat 1 baris.
        2. Tuliskan 3 hingga 7 tahapan tugas bertahap menggunakan format bullet point jelas:
           • **Hari 1: [Judul Singkat Tugas]** - [Penjelasan materi ringkas & aksi nyata yang harus dilakukan]
           • **Hari 2: [Judul Singkat Tugas]** - [Penjelasan materi ringkas & aksi nyata yang harus dilakukan]
           • **Hari 3: [Judul Singkat Tugas]** - [Penjelasan materi ringkas & aksi nyata yang harus dilakukan]
        3. PENTING: DILARANG menyuruh pengguna menghubungkan Google Tasks atau layanan eksternal. Aplikasi iOS ini akan otomatis memproses dan menyimpan daftar tugas ini ke database lokal.
        """

        let structuredPrompt = """
        [Instruksi: Susunkan rencana materi/tugas bertahap 3-7 hari. Format tiap poin: • **Hari N: Judul Tugas** - Penjelasan singkat materi. Dilarang sebutkan Google Tasks.]

        \(prompt)
        """

        do {
            let replyText: String
            switch provider {
            case .googleAccount:
                replyText = try await GeminiHeadlessEngine.shared.queryGemini(prompt: structuredPrompt)
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

            let cleanReply = postProcessAIResponse(replyText)

            // Parse blocks untuk mengekstrak tugas dan langsung menyimpannya ke SwiftData
            let blocks = AIMarkdownParser.parseBlocks(from: cleanReply)
            var insertedTasksCount = 0
            var calendar = Calendar.current
            calendar.locale = Locale(identifier: "id_ID")
            let now = Date()

            // Jadwalkan mulai besok pukul 09:00 pagi jika sekarang sudah siang/sore, atau hari ini jika pagi
            var baseScheduleDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
            if baseScheduleDate <= now {
                baseScheduleDate = calendar.date(byAdding: .day, value: 1, to: baseScheduleDate) ?? now
            }

            var dayOffset = 0
            for block in blocks {
                let rawText: String
                switch block {
                case .bullet(let text, _): rawText = text
                case .numbered(_, let text): rawText = text
                default: continue
                }

                let parsed = AIMarkdownParser.extractTitleAndNotes(from: rawText)
                guard !parsed.title.isEmpty, parsed.title.count >= 3 else { continue }

                let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: baseScheduleDate) ?? baseScheduleDate
                let tagSuggestion = AITaskBreakdownService.shared.suggestTags(for: parsed.title, notes: parsed.notes)

                let newItem = Item(
                    title: parsed.title,
                    notes: parsed.notes,
                    timestamp: targetDate,
                    isCompleted: false,
                    completedAt: nil,
                    priority: tagSuggestion.priority.rawValue,
                    category: tagSuggestion.category.rawValue,
                    isRecurring: false,
                    recurrenceRule: "Sekali Saja",
                    customSoundName: "cartoon_bell.caf",
                    subtasks: [],
                    imageAttachmentData: nil
                )

                modelContext.insert(newItem)
                insertedTasksCount += 1
                dayOffset += 1
            }

            if insertedTasksCount > 0 {
                try? modelContext.save()
                WidgetCenter.shared.reloadAllTimelines()
                HapticManager.shared.success()
                SoundManager.shared.playSuccessChime()

                let toolCall = MCPToolInvocation(
                    name: "schedule_curriculum_tasks",
                    argumentsSummary: "scheduled: \(insertedTasksCount) tasks",
                    icon: "calendar.badge.plus",
                    badgeColorHex: "#6EE7B7"
                )

                let finalReply = """
                \(cleanReply)

                ---
                ✨ **Berhasil! \(insertedTasksCount) tugas bertahap telah otomatis disimpan & dijadwalkan ke agenda lokal aplikasi Anda.**
                """
                await streamAssistantMessage(fullContent: finalReply, toolCall: toolCall, toolResult: "Created \(insertedTasksCount) tasks")
            } else {
                await streamAssistantMessage(fullContent: cleanReply)
            }
        } catch {
            await streamAssistantMessage(fullContent: "Maaf, terjadi kendala saat merancang kurikulum tugas: \(error.localizedDescription)")
        }
    }

    // MARK: - Eksekusi MCP Tool: Weekly Review & Productivity Infographic
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
        **Laporan Mingguan & Skor Produktivitas AI**

        **Skor Produktivitas:** **\(report.score)/100 (Grade: \(report.scoreGrade))**
        **Profil:** *\(report.persona.rawValue)*

        **Pencapaian Utama:**
        \(highlightsList)

        **Saran Pengembangan:**
        \(growthTipsList)
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Generated Report Score \(report.score)")
    }

    // MARK: - Eksekusi MCP Tool: Habit Recommendation
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
        **Rekomendasi Kebiasaan Positif AI:**
        \(proposalText)
        Kamu bisa langsung mengadopsi kebiasaan ini dalam 1 ketukan pada tab **Kebiasaan > AI Rutinitas**!
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "\(proposals.count) habit proposals")
    }

    // MARK: - Eksekusi MCP Tool: Streak Risk Radar
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
            **Radar Streak Aman!**

            Seluruh kebiasaan aktifmu sudah diceklis hari ini atau berada dalam kondisi aman. Pertahankan konsistensi luar biasamu!
            """
        } else {
            var riskList = ""
            for r in endangered {
                riskList += "\n• **\(r.title)** (Streak: \(r.currentStreak) hari) → Risiko: **\(r.riskLevel.rawValue)** (\(r.reason))"
            }
            reply = """
            **Perhatian! Ditemukan Streak yang Terancam Putus:**
            \(riskList)

            *Saran AI:* Segera luangkan waktu 5 menit untuk menyelesaikan kebiasaan ini sebelum hari berganti!
            """
        }

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "\(endangered.count) endangered streaks")
    }

    // MARK: - Eksekusi MCP Tool: Schedule Rebalancer
    private func executeRebalanceScheduleTool(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Item>(sortBy: [SortDescriptor(\.timestamp, order: .forward)])
        let items = (try? modelContext.fetch(descriptor)) ?? []

        let proposals = AIScheduleRebalancerService.shared.analyzeAndGenerateProposals(for: items)

        if proposals.isEmpty {
            let toolCall = MCPToolInvocation(
                name: "ai_schedule_rebalance",
                argumentsSummary: "status: perfect",
                icon: "checkmark.circle.fill",
                badgeColorHex: "#6EE7B7"
            )
            let reply = """
            **Jadwal Sangat Rapi & Optimal!**

            Tidak ditemukan tugas yang terlewat atau bertabrakan. Semua agenda tersusun dengan baik.
            """
            await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "No conflicts")
            return
        }

        await AIScheduleRebalancerService.shared.applyRebalance(proposals: proposals, in: modelContext)
        HapticManager.shared.success()

        let toolCall = MCPToolInvocation(
            name: "ai_schedule_rebalance",
            argumentsSummary: "rebalanced: \(proposals.count) tasks",
            icon: "wand.and.stars",
            badgeColorHex: "#FDE047"
        )

        var proposalListText = ""
        for p in proposals.prefix(4) {
            proposalListText += "\n• **\(p.item.title)** → Dipindah ke **\(p.proposedDate.formatted(date: .omitted, time: .shortened))** (\(p.reason))"
        }

        let reply = """
        **Jadwal Berhasil Ditata Ulang!**

        Ditemukan **\(proposals.count) tugas** yang terlewat atau bertabrakan. AI telah mengatur ulang jadwalnya ke slot kosong terbaik:
        \(proposalListText)

        Pengingat notifikasi dan widget juga telah diperbarui secara otomatis. Tetap semangat!
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "\(proposals.count) rebalanced")
    }

    // MARK: - Eksekusi MCP Tool: Pomodoro Timer
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
        **Sesi Pomodoro Berhasil Dimulai!**

        • Mode: **\(pomodoro.selectedPreset.rawValue)**
        • Durasi: **\(pomodoro.remainingSeconds / 60) Menit**
        • Dynamic Island & Live Activity telah aktif di layar kunci.

        Jauhkan distraksi dan mari mulai fokus menyelesaikan tugas pertamamu!
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Pomodoro started")
    }

    // MARK: - Eksekusi MCP Tool: Check-In Habit
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
        **Check-in Habit Berhasil!**

        Target kebiasaan **\(target.title)** telah diceklis hari ini!
        Streak kamu saat ini: **\(target.currentStreak) hari berturut-turut!**
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Streak \(target.currentStreak)")
    }

    // MARK: - Eksekusi MCP Tool: Summary Aktivitas & HealthKit
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
        **Ringkasan Aktivitas & Kebugaran Hari Ini:**

        **Status Tugas:**
        • Perlu Dikerjakan: **\(pending) tugas**
        • Telah Selesai: **\(completed) tugas**

        **HealthKit Kebugaran:**
        • Langkah: **\(health.steps)** / 10.000 langkah
        • Kalori Aktif: **\(Int(health.activeCalories))** kkal
        • Jarak Tempuh: **\(String(format: "%.2f", health.distanceKm))** km
        • Tidur Semalam: **\(health.sleepFormatted)**

        Kondisi fisik dan produktivitas harianmu terpantau sangat baik!
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Summary generated")
    }

    // MARK: - Eksekusi MCP Tool: Screen Time Shield
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
            "**Screen Time Shield Diaktifkan!**\nAplikasi distraksi (Instagram, TikTok, YouTube, Games) dibatasi agar kamu fokus penuh." :
            "**Screen Time Shield Dinonaktifkan.**\nAkses ke seluruh aplikasi telah dibuka kembali."

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Shield set to \(screenTime.isShieldActive)")
    }

    // MARK: - Eksekusi MCP Tool: Bersihkan Tugas Selesai
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
        **Daftar Tugas Telah Dibersihkan!**

        Sebanyak **\(completed.count) tugas selesai** berhasil dihapus dari daftar utama untuk menjaga antarmuka tetap rapi dan bersih.
        """

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Cleaned \(completed.count) items")
    }

    // MARK: - Komunikasi ke Cloud AI Engine (Gemini / Ninerouter / Headless Web)
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

        // HANYA sediakan referensi to-do list jika pengguna secara eksplisit menanyakan tugas/jadwalnya
        let userAsksAboutTasks = prompt.localizedCaseInsensitiveContains("tugas") ||
                                 prompt.localizedCaseInsensitiveContains("jadwal") ||
                                 prompt.localizedCaseInsensitiveContains("to-do") ||
                                 prompt.localizedCaseInsensitiveContains("agenda") ||
                                 prompt.localizedCaseInsensitiveContains("aktivitas")

        var taskContext = ""
        if userAsksAboutTasks {
            let pending = items.filter { !$0.isCompleted }.prefix(5).map { "- \($0.title) (\($0.category))" }.joined(separator: "\n")
            if !pending.isEmpty {
                taskContext = "\nReferensi tugas aktif pengguna (gunakan HANYA jika relevan dengan pertanyaan):\n\(pending)"
            }
        }

        let systemInstruction = """
        Kamu adalah Asisten AI Produktivitas cerdas, santai, dan to-the-point.
        ATURAN FORMAT & INTEGRASI WAJIB:
        1. Jawab secara SANGAT RINGKAS, PADAT, dan LANGSUNG KE INTI (Maksimal 2-3 bullet point atau 2 paragraf pendek).
        2. Gunakan bullet points (•) atau nomor untuk poin-poin agar mudah dibaca cepat.
        3. Tebalkan kata kunci penting (*bold*).
        4. JANGAN gunakan basa-basi pembuka atau penutup yang panjang.
        5. PENTING: Aplikasi ini adalah aplikasi to-do list iOS independen. JANGAN PERNAH menyuruh, mengarahkan, atau meminta pengguna menghubungkan akun ke Google Tasks, Google Workspace, atau layanan eksternal lainnya.
        6. PENTING: JANGAN PERNAH mengungkit, menyebutkan, atau mengingatkan sisa daftar tugas/to-do list kecuali pengguna secara eksplisit menanyakannya.\(taskContext)
        """

        do {
            let replyText: String
            switch provider {
            case .googleAccount:
                let structuredPrompt = """
                [Instruksi: Jawab SANGAT RINGKAS (maksimal 2-3 bullet point atau 2 paragraf pendek), to-the-point, tebalkan kata kunci, tanpa basa-basi. Ini adalah aplikasi to-do list mandiri (JANGAN PERNAH minta connect ke Google Tasks atau layanan eksternal lainnya), dan jangan ungkit sisa to-do list.]

                \(prompt)
                """
                replyText = try await GeminiHeadlessEngine.shared.queryGemini(prompt: structuredPrompt)

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

            let cleanReply = postProcessAIResponse(replyText)
            await streamAssistantMessage(fullContent: cleanReply)
        } catch {
            let errorReply: String
            if provider == .googleAccount {
                errorReply = """
                **Sesi Akun Google Gemini Belum Aktif**

                Untuk menggunakan mode web gratis:
                1. Ketuk tombol **Login** pada banner di atas chat, atau buka **Pengaturan**.
                2. Masuk ke akun Google Anda satu kali.

                *Tips: Anda juga bisa beralih ke **Gemini API Key** (gratis & cepat dari Google AI Studio) di menu Pengaturan.*
                """
            } else if provider == .geminiApiKey && apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorReply = """
                **Gemini API Key Belum Diisi**

                Silakan buka **Pengaturan** di pojok kanan atas dan masukkan API Key Anda dari Google AI Studio.
                """
            } else {
                errorReply = "Maaf, terjadi kendala koneksi AI: \(error.localizedDescription)\n\nSilakan periksa koneksi internet atau pengaturan AI di menu Pengaturan Asisten."
            }
            await streamAssistantMessage(fullContent: errorReply)
        }
    }

    // MARK: - Pembersih & Pemoles Respon AI (Menghilangkan Basa-Basi & Menjaga Kerapian)
    private func postProcessAIResponse(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Hapus basa-basi umum pembuka yang membuat jawaban bertele-tele
        let cliches = [
            "Tentu! ", "Tentu, ", "Tentu saja! ", "Halo! ", "Hai! ",
            "Sebagai asisten AI, ", "Sebagai asisten produktivitas Anda, ",
            "Berikut adalah ringkasan yang diminta:", "Berikut adalah penjelasannya:",
            "Berikut adalah jawabannya:", "Berikut informasinya:"
        ]
        for c in cliches {
            if text.hasPrefix(c) {
                text = String(text.dropFirst(c.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return text
    }

    // MARK: - Direct Single Task Creation Tool (Langsung Simpan ke Database Lokal Aplikasi)
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
        SoundManager.shared.playSuccessChime()

        let toolCall = MCPToolInvocation(
            name: "create_activity",
            argumentsSummary: "title: \(taskTitle), date: \(taskDate.formatted(date: .abbreviated, time: .shortened))",
            icon: "plus.circle.fill",
            badgeColorHex: "#6EE7B7"
        )

        var reply = """
        **Tugas Berhasil Ditambahkan ke Aplikasi!**

        • **Judul:** \(taskTitle)
        • **Kategori:** \(suggestedCategory)
        • **Prioritas:** \(suggestedPriority)
        • **Waktu:** \(taskDate.formatted(date: .complete, time: .shortened))
        """

        if let conflict = conflicts.first {
            let nextAvailableSlot = ScheduleConflictDetector.shared.suggestNextAvailableSlot(startingFrom: taskDate, in: existingItems)
            let nextSlotStr = nextAvailableSlot.formatted(date: .omitted, time: .shortened)
            reply += "\n\n**Catatan Jadwal:** Waktu ini berdekatan dengan *\"\(conflict.existingTaskTitle)\"*. Rekomendasi jam luang berikutnya: **\(nextSlotStr)**."
        }

        await streamAssistantMessage(fullContent: reply, toolCall: toolCall, toolResult: "Created \(taskTitle)")
    }

    // MARK: - Typing Effect Streaming Assistant Message
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

    // MARK: - HTTP AI Helpers
    private func sendGeminiAPIRequest(prompt: String, systemInstruction: String, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "MCPAIAssistant", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key Gemini belum diisi."])
        }

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "system_instruction": [
                "parts": [["text": systemInstruction]]
            ],
            "contents": [
                [
                    "role": "user",
                    "parts": [["text": prompt]]
                ]
            ],
            "generationConfig": [
                "temperature": 0.4,
                "maxOutputTokens": 600
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errString = String(data: data, encoding: .utf8) ?? "Unknown HTTP Error"
            throw NSError(domain: "GeminiAPI", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errString])
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let firstPart = parts.first,
           let text = firstPart["text"] as? String {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        throw NSError(domain: "GeminiAPI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Gagal memproses respon dari Gemini API."])
    }

    private func sendNinerouterRequest(
        prompt: String,
        systemInstruction: String,
        apiKey: String,
        baseUrl: String,
        model: String
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "Ninerouter", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key OpenRouter belum diisi."])
        }

        let cleanedBase = baseUrl.hasSuffix("/") ? String(baseUrl.dropLast()) : baseUrl
        guard let url = URL(string: "\(cleanedBase)/chat/completions") else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let payload: [String: Any] = [
            "model": model.isEmpty ? "google/gemini-flash-1.5" : model,
            "messages": [
                ["role": "system", "content": systemInstruction],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.4,
            "max_tokens": 600
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errString = String(data: data, encoding: .utf8) ?? "Unknown HTTP Error"
            throw NSError(domain: "Ninerouter", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errString])
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let msg = firstChoice["message"] as? [String: Any],
           let text = msg["content"] as? String {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        throw NSError(domain: "Ninerouter", code: 500, userInfo: [NSLocalizedDescriptionKey: "Gagal memproses respon dari OpenRouter."])
    }
}
