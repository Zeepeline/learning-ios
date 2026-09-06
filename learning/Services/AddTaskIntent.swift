//
//  AddTaskIntent.swift
//  learning
//
//  Created by macbook on 9/6/26.
//

import AppIntents
import SwiftData
import WidgetKit
import Foundation

// MARK: - 🎙️ App Intent: Tambah Tugas Kilat (Siri & Shortcuts)
struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Tambah Tugas Cepat"
    static var description = IntentDescription("Menambahkan tugas atau jadwal aktivitas baru ke Learning secara otomatis di background.")
    static var openAppWhenRun: Bool = false

    @Parameter(
        title: "Judul Tugas",
        description: "Nama atau judul aktivitas yang ingin dicatat",
        requestValueDialog: IntentDialog("Apa nama tugas atau aktivitas yang ingin ditambahkan?")
    )
    var title: String

    @Parameter(
        title: "Catatan Tambahan",
        description: "Catatan atau deskripsi pendukung tugas"
    )
    var notes: String?

    @Parameter(
        title: "Waktu Aktivitas",
        description: "Jadwal tanggal dan jam tugas"
    )
    var timestamp: Date?

    @Parameter(
        title: "Kategori",
        description: "Kategori tugas (misal: Kerja, Pribadi, Belajar, Olahraga, Umum)",
        default: "Umum"
    )
    var category: String

    @Parameter(
        title: "Prioritas",
        description: "Tingkat prioritas tugas (Rendah, Normal, Tinggi)",
        default: "Normal"
    )
    var priority: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 🧠 Normalisasi Suara & Smart Auto-Correction kata-kata Siri
        let (processedTitle, detectedCategory, detectedDate) = VoiceTextProcessor.process(rawText: title)
        
        let finalTitle = processedTitle.isEmpty ? title.trimmingCharacters(in: .whitespacesAndNewlines) : processedTitle
        guard !finalTitle.isEmpty else {
            return .result(dialog: "Judul tugas tidak boleh kosong.")
        }

        let schema = Schema([Item.self, Habit.self])
        let appGroupIdentifier = "group.com.gmedia.xlearning"
        var container: ModelContainer?

        // Akses Shared SQLite Database di App Group
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let storeURL = containerURL.appendingPathComponent("learning.sqlite")
            let config = ModelConfiguration(schema: schema, url: storeURL)
            container = try? ModelContainer(for: schema, configurations: [config])
        }

        // Fallback Container jika App Group belum terpasang
        if container == nil {
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try? ModelContainer(for: schema, configurations: [fallbackConfig])
        }

        guard let validContainer = container else {
            return .result(dialog: "Gagal menghubungkan ke database aplikasi.")
        }

        let context = validContainer.mainContext
        let taskDate = timestamp ?? detectedDate ?? Date()
        let finalCategory = (category == "Umum" && detectedCategory != nil) ? detectedCategory! : category
        
        let newItem = Item(
            title: finalTitle,
            notes: notes ?? "",
            timestamp: taskDate,
            isCompleted: false,
            priority: priority,
            category: finalCategory
        )

        context.insert(newItem)
        try? context.save()

        // Perbarui tampilan Widget di Home Screen / Lock Screen secara instan
        WidgetCenter.shared.reloadAllTimelines()

        return .result(dialog: "✅ Tugas \"\(finalTitle)\" berhasil dicatat ke Learning!")
    }
}

// MARK: - 🧠 Smart Voice Text Processor (Auto-Correct Siri Phonetics & Auto Categorization)
struct VoiceTextProcessor {
    /// Kamus koreksi fonetik Siri untuk Bahasa Indonesia
    private static let phoneticCorrections: [String: String] = [
        "tirumala": "Tidur Malam",
        "tiru malam": "Tidur Malam",
        "tido malam": "Tidur Malam",
        "tidur mlm": "Tidur Malam",
        "tidur malem": "Tidur Malam",
        "lari page": "Lari Pagi",
        "lari pak gi": "Lari Pagi",
        "joging": "Jogging Pagi",
        "makansian": "Makan Siang",
        "makan malem": "Makan Malam",
        "solat": "Sholat",
        "sholat subu": "Sholat Subuh",
        "sholat dzuhur": "Sholat Dzuhur",
        "sholat ashar": "Sholat Ashar",
        "sholat magrib": "Sholat Maghrib",
        "sholat isya": "Sholat Isya",
        "belajar koding": "Belajar Coding",
        "bikin pr": "Mengerjakan PR",
        "kerja bakti": "Kerja Bakti",
        "ngoding": "Ngoding Project"
    ]

    static func process(rawText: String) -> (title: String, category: String?, detectedDate: Date?) {
        var text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = text.lowercased()

        // 1. Cek koreksi kata persis / fonetik
        for (wrong, correct) in phoneticCorrections {
            if lower == wrong || lower.contains(wrong) {
                text = text.replacingOccurrences(of: wrong, with: correct, options: .caseInsensitive)
            }
        }

        // 2. Deteksi Kategori Otomatis berdasarkan kata kunci
        var category: String? = nil
        let textLower = text.lowercased()
        if textLower.contains("lari") || textLower.contains("jogging") || textLower.contains("gym") || textLower.contains("workout") || textLower.contains("renang") || textLower.contains("sepeda") {
            category = "Health"
        } else if textLower.contains("tidur") || textLower.contains("makan") || textLower.contains("istirahat") || textLower.contains("sholat") || textLower.contains("doa") {
            category = "Personal"
        } else if textLower.contains("meeting") || textLower.contains("rapat") || textLower.contains("kerja") || textLower.contains("client") || textLower.contains("proyek") || textLower.contains("project") {
            category = "Work"
        } else if textLower.contains("belajar") || textLower.contains("kuliah") || textLower.contains("baca") || textLower.contains("buku") || textLower.contains("kursus") {
            category = "Study"
        } else if textLower.contains("desain") || textLower.contains("design") || textLower.contains("figma") || textLower.contains("ui") {
            category = "Design"
        } else if textLower.contains("coding") || textLower.contains("ngoding") || textLower.contains("bug") || textLower.contains("code") {
            category = "Code"
        }

        // 3. Format Kapitalisasi Awal Kata (Title Case)
        let formattedTitle = text.prefix(1).uppercased() + text.dropFirst()

        // 4. Deteksi Waktu Pintar (misal "malam" -> jam 21:00, "pagi" -> jam 07:00, "siang" -> jam 12:00)
        var detectedDate: Date? = nil
        let calendar = Calendar.current
        let now = Date()

        if textLower.contains("malam") || textLower.contains("malem") {
            detectedDate = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: now)
        } else if textLower.contains("pagi") {
            detectedDate = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now)
        } else if textLower.contains("siang") {
            detectedDate = calendar.date(bySettingHour: 12, minute: 30, second: 0, of: now)
        } else if textLower.contains("sore") {
            detectedDate = calendar.date(bySettingHour: 16, minute: 30, second: 0, of: now)
        }

        return (formattedTitle, category, detectedDate)
    }
}
