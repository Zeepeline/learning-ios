//
//  AITaskBreakdownService.swift
//  learning
//
//  Created by macbook on 9/20/26.
//

import Foundation
import SwiftUI

// MARK: - AI Subtask Proposal Model
public struct AISubtaskProposal: Identifiable, Sendable, Equatable {
    public let id: String
    public var title: String
    public var isSelected: Bool

    public init(id: String = UUID().uuidString, title: String, isSelected: Bool = true) {
        self.id = id
        self.title = title
        self.isSelected = isSelected
    }
}

// MARK: - AI Auto-Tag Result
public struct AITagSuggestion: Sendable, Equatable {
    public let category: TaskCategory
    public let priority: TaskPriority
    public let estimatedDurationMinutes: Int
    public let reasoning: String
}

// MARK: - AITaskBreakdownService
@MainActor
public final class AITaskBreakdownService {
    public static let shared = AITaskBreakdownService()

    private init() {}

    // MARK: - Generate Subtasks from Task Title & Context
    public func generateSubtasks(for taskTitle: String, notes: String = "") -> [AISubtaskProposal] {
        let trimmed = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let lower = (trimmed + " " + notes).lowercased()

        // 1. Template-based intelligent domain matching
        if lower.contains("presentasi") || lower.contains("pitch") || lower.contains("slides") || lower.contains("deck") {
            return [
                AISubtaskProposal(title: "Tentukan outline & poin-poin utama materi"),
                AISubtaskProposal(title: "Rancang slide presentasi & visual grafik"),
                AISubtaskProposal(title: "Latihan rehearsal & timer penyampaian"),
                AISubtaskProposal(title: "Kirim draft ke rekan tim untuk review")
            ]
        }

        if lower.contains("ujian") || lower.contains("exam") || lower.contains("kuis") || lower.contains("uts") || lower.contains("uas") || lower.contains("test") {
            return [
                AISubtaskProposal(title: "Kumpulkan silabus & rangkuman materi"),
                AISubtaskProposal(title: "Kerjakan latihan soal & flashcards"),
                AISubtaskProposal(title: "Review topik yang masih belum dipahami"),
                AISubtaskProposal(title: "Istirahat cukup sebelum hari H")
            ]
        }

        if lower.contains("belajar") || lower.contains("kursus") || lower.contains("baca buku") || lower.contains("chapter") || lower.contains("study") || lower.contains("read") || lower.contains("materi") {
            return [
                AISubtaskProposal(title: "Pelajari materi target selama 25 menit"),
                AISubtaskProposal(title: "Buat catatan ringkas poin-poin penting"),
                AISubtaskProposal(title: "Praktekkan 1 contoh studi kasus / latihan"),
                AISubtaskProposal(title: "Uji pemahaman dengan self-quiz")
            ]
        }

        if lower.contains("coding") || lower.contains("code") || lower.contains("bug") || lower.contains("fitur") || lower.contains("app") || lower.contains("deploy") || lower.contains("refactor") || lower.contains("swift") {
            return [
                AISubtaskProposal(title: "Buat rancangan alur logic & arsitektur"),
                AISubtaskProposal(title: "Implementasi kode komponen inti"),
                AISubtaskProposal(title: "Tulis unit test & jalankan build verify"),
                AISubtaskProposal(title: "Commit modular & push ke repository")
            ]
        }

        if lower.contains("gym") || lower.contains("workout") || lower.contains("olahraga") || lower.contains("lari") || lower.contains("fitness") || lower.contains("exercise") {
            return [
                AISubtaskProposal(title: "Pemanasan dinamis & stretching 5 menit"),
                AISubtaskProposal(title: "Latihan inti (target reps & sets)"),
                AISubtaskProposal(title: "Pendinginan & recovery hidrasi"),
                AISubtaskProposal(title: "Catat progres di log aktivitas")
            ]
        }

        if lower.contains("bersih") || lower.contains("kamar") || lower.contains("rumah") || lower.contains("beres") || lower.contains("clean") {
            return [
                AISubtaskProposal(title: "Pilah barang yang tidak terpakai"),
                AISubtaskProposal(title: "Rapikan meja & area kerja"),
                AISubtaskProposal(title: "Sapu & pel lantai hingga bersih"),
                AISubtaskProposal(title: "Buang sampah ke tempat pembuangan")
            ]
        }

        if lower.contains("belanja") || lower.contains("pasar") || lower.contains("supermarket") || lower.contains("shopping") || lower.contains("buy") {
            return [
                AISubtaskProposal(title: "Cek stok bahan yang sudah habis"),
                AISubtaskProposal(title: "Buat checklist daftar belanjaan"),
                AISubtaskProposal(title: "Siapkan tas belanja ramah lingkungan"),
                AISubtaskProposal(title: "Beli barang sesuai prioritas anggaran")
            ]
        }

        if lower.contains("meeting") || lower.contains("rapat") || lower.contains("diskusi") || lower.contains("sync") || lower.contains("call") {
            return [
                AISubtaskProposal(title: "Siapkan agenda & tujuan utama meeting"),
                AISubtaskProposal(title: "Kumpulkan bahan pendukung / dokumen"),
                AISubtaskProposal(title: "Catat notula & action items selama rapat"),
                AISubtaskProposal(title: "Follow up hasil meeting ke peserta")
            ]
        }

        // Generic intelligent fallback breakdown
        return [
            AISubtaskProposal(title: "Persiapkan materi dan kebutuhan awal"),
            AISubtaskProposal(title: "Kerjakan eksekusi tahap utama fokus 25m"),
            AISubtaskProposal(title: "Review kualitas hasil pengerjaan"),
            AISubtaskProposal(title: "Tuntaskan finalisasi & checklist selesai")
        ]
    }

    // MARK: - Suggest Category & Priority Automatically (Universal Multi-Domain)
    public func suggestTags(for taskTitle: String, notes: String = "") -> AITagSuggestion {
        let combined = (taskTitle + " " + notes).lowercased()

        // 1. Detect Category (Universal Multilingual Matching)
        let category: TaskCategory
        if combined.contains("code") || combined.contains("coding") || combined.contains("bug") || combined.contains("swift") || combined.contains("deploy") || combined.contains("api") || combined.contains("git") || combined.contains("backend") || combined.contains("frontend") || combined.contains("database") {
            category = .coding
        } else if combined.contains("belajar") || combined.contains("buku") || combined.contains("ujian") || combined.contains("kursus") || combined.contains("kuliah") || combined.contains("materi") || combined.contains("inggris") || combined.contains("english") || combined.contains("vocab") || combined.contains("reading") || combined.contains("listening") || combined.contains("speaking") || combined.contains("study") || combined.contains("learn") || combined.contains("baca") {
            category = .learning
        } else if combined.contains("lari") || combined.contains("gym") || combined.contains("workout") || combined.contains("olahraga") || combined.contains("sehat") || combined.contains("jalan") || combined.contains("fitness") || combined.contains("diet") || combined.contains("tidur") || combined.contains("air putih") || combined.contains("stretching") {
            category = .health
        } else if combined.contains("kerja") || combined.contains("kantor") || combined.contains("proyek") || combined.contains("klien") || combined.contains("laporan") || combined.contains("target") || combined.contains("client") || combined.contains("report") || combined.contains("business") || combined.contains("email") {
            category = .work
        } else if combined.contains("meeting") || combined.contains("rapat") || combined.contains("zoom") || combined.contains("call") || combined.contains("sync") || combined.contains("diskusi") {
            category = .meeting
        } else if combined.contains("design") || combined.contains("ui") || combined.contains("ux") || combined.contains("figma") || combined.contains("logo") || combined.contains("banner") || combined.contains("sketsa") || combined.contains("mockup") {
            category = .design
        } else if combined.contains("beli") || combined.contains("belanja") || combined.contains("pasar") || combined.contains("supermarket") || combined.contains("checkout") || combined.contains("shopping") || combined.contains("order") {
            category = .shopping
        } else if combined.contains("uang") || combined.contains("bayar") || combined.contains("tagihan") || combined.contains("transfer") || combined.contains("gaji") || combined.contains("budget") || combined.contains("investasi") || combined.contains("finance") || combined.contains("nabung") {
            category = .finance
        } else if combined.contains("sholat") || combined.contains("doa") || combined.contains("ibadah") || combined.contains("meditasi") || combined.contains("mengaji") || combined.contains("dzikir") || combined.contains("bible") || combined.contains("quran") {
            category = .spiritual
        } else if combined.contains("rumah") || combined.contains("kamar") || combined.contains("bersih") || combined.contains("cucian") || combined.contains("masak") || combined.contains("cleaning") || combined.contains("cook") || combined.contains("laundry") {
            category = .home
        } else if combined.contains("teman") || combined.contains("keluarga") || combined.contains("kumpul") || combined.contains("reuni") || combined.contains("ngobrol") || combined.contains("hangout") {
            category = .social
        } else {
            category = .personal
        }

        // 2. Detect Priority
        let priority: TaskPriority
        if combined.contains("penting") || combined.contains("urgent") || combined.contains("darurat") || combined.contains("segera") || combined.contains("asap") || combined.contains("deadline") || combined.contains("tinggi") || combined.contains("ujian") || combined.contains("critical") {
            priority = .high
        } else if combined.contains("santai") || combined.contains("kapan-kapan") || combined.contains("opsional") || combined.contains("nanti") || combined.contains("rendah") || combined.contains("low") {
            priority = .low
        } else {
            priority = .normal
        }

        let duration: Int = (priority == .high) ? 45 : (category == .coding || category == .learning ? 30 : 20)
        let reasoning = "Terdeteksi kategori \(category.rawValue) dengan urgensi prioritas \(priority.rawValue)."

        return AITagSuggestion(
            category: category,
            priority: priority,
            estimatedDurationMinutes: duration,
            reasoning: reasoning
        )
    }
}
