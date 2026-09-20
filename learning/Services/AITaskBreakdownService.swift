//
//  AITaskBreakdownService.swift
//  learning
//
//  Created by macbook on 9/20/26.
//

import Foundation
import SwiftUI

// MARK: - 🧩 AI Subtask Proposal Model
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

// MARK: - 🏷️ AI Auto-Tag Result
public struct AITagSuggestion: Sendable, Equatable {
    public let category: TaskCategory
    public let priority: TaskPriority
    public let estimatedDurationMinutes: Int
    public let reasoning: String
}

// MARK: - 🧠 AITaskBreakdownService
@MainActor
public final class AITaskBreakdownService {
    public static let shared = AITaskBreakdownService()

    private init() {}

    // MARK: - 🪄 Generate Subtasks from Task Title & Context
    public func generateSubtasks(for taskTitle: String, notes: String = "") -> [AISubtaskProposal] {
        let trimmed = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let lower = (trimmed + " " + notes).lowercased()

        // 1. Template-based intelligent domain matching
        if lower.contains("presentasi") || lower.contains("pitch") || lower.contains("slides") {
            return [
                AISubtaskProposal(title: "Tentukan outline & poin-poin utama materi"),
                AISubtaskProposal(title: "Rancang slide presentasi & visual grafik"),
                AISubtaskProposal(title: "Latihan rehearsal & timer penyampaian"),
                AISubtaskProposal(title: "Kirim draft ke rekan tim untuk review")
            ]
        }

        if lower.contains("ujian") || lower.contains("exam") || lower.contains("kuis") || lower.contains("uts") || lower.contains("uas") {
            return [
                AISubtaskProposal(title: "Kumpulkan silabus & rangkuman materi"),
                AISubtaskProposal(title: "Kerjakan latihan soal & flashcards"),
                AISubtaskProposal(title: "Review topik yang masih belum dipahami"),
                AISubtaskProposal(title: "Istirahat cukup sebelum hari H")
            ]
        }

        if lower.contains("belajar") || lower.contains("kursus") || lower.contains("baca buku") || lower.contains("chapter") {
            return [
                AISubtaskProposal(title: "Baca bab/modul target selama 25 menit"),
                AISubtaskProposal(title: "Buat catatan ringkas poin-poin penting"),
                AISubtaskProposal(title: "Praktekkan 1 contoh studi kasus"),
                AISubtaskProposal(title: "Uji pemahaman dengan self-quiz")
            ]
        }

        if lower.contains("coding") || lower.contains("bug") || lower.contains("fitur") || lower.contains("app") || lower.contains("deploy") || lower.contains("refactor") {
            return [
                AISubtaskProposal(title: "Buat rancangan alur logic & arsitektur"),
                AISubtaskProposal(title: "Implementasi kode komponen inti"),
                AISubtaskProposal(title: "Tulis unit test & jalankan build verify"),
                AISubtaskProposal(title: "Commit modular & push ke repository")
            ]
        }

        if lower.contains("gym") || lower.contains("workout") || lower.contains("olahraga") || lower.contains("lari") {
            return [
                AISubtaskProposal(title: "Pemanasan dinamis & stretching 5 menit"),
                AISubtaskProposal(title: "Latihan inti (target reps & sets)"),
                AISubtaskProposal(title: "Pendinginan & recovery hidrasi"),
                AISubtaskProposal(title: "Catat progres di log aktivitas")
            ]
        }

        if lower.contains("bersih") || lower.contains("kamar") || lower.contains("rumah") || lower.contains("beres") {
            return [
                AISubtaskProposal(title: "Pilah barang yang tidak terpakai"),
                AISubtaskProposal(title: "Rapikan meja & area kerja"),
                AISubtaskProposal(title: "Sapu & pel lantai hingga bersih"),
                AISubtaskProposal(title: "Buang sampah ke tempat pembuangan")
            ]
        }

        if lower.contains("belanja") || lower.contains("pasar") || lower.contains("supermarket") || lower.contains("shopping") {
            return [
                AISubtaskProposal(title: "Cek stok bahan yang sudah habis"),
                AISubtaskProposal(title: "Buat checklist daftar belanjaan"),
                AISubtaskProposal(title: "Siapkan tas belanja ramah lingkungan"),
                AISubtaskProposal(title: "Beli barang sesuai prioritas anggaran")
            ]
        }

        if lower.contains("meeting") || lower.contains("rapat") || lower.contains("diskusi") {
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

    // MARK: - 🏷️ Suggest Category & Priority Automatically
    public func suggestTags(for taskTitle: String, notes: String = "") -> AITagSuggestion {
        let combined = (taskTitle + " " + notes).lowercased()

        // 1. Detect Category
        let category: TaskCategory
        if combined.contains("code") || combined.contains("coding") || combined.contains("bug") || combined.contains("swift") || combined.contains("deploy") || combined.contains("api") || combined.contains("git") {
            category = .coding
        } else if combined.contains("belajar") || combined.contains("buku") || combined.contains("ujian") || combined.contains("kursus") || combined.contains("kuliah") || combined.contains("materi") {
            category = .learning
        } else if combined.contains("lari") || combined.contains("gym") || combined.contains("workout") || combined.contains("olahraga") || combined.contains("sehat") || combined.contains("jalan") {
            category = .health
        } else if combined.contains("kerja") || combined.contains("kantor") || combined.contains("proyek") || combined.contains("klien") || combined.contains("laporan") || combined.contains("target") {
            category = .work
        } else if combined.contains("meeting") || combined.contains("rapat") || combined.contains("zoom") || combined.contains("call") || combined.contains("sync") {
            category = .meeting
        } else if combined.contains("design") || combined.contains("ui") || combined.contains("ux") || combined.contains("figma") || combined.contains("logo") || combined.contains("banner") {
            category = .design
        } else if combined.contains("beli") || combined.contains("belanja") || combined.contains("pasar") || combined.contains("supermarket") || combined.contains("checkout") {
            category = .shopping
        } else if combined.contains("uang") || combined.contains("bayar") || combined.contains("tagihan") || combined.contains("transfer") || combined.contains("gaji") || combined.contains("budget") {
            category = .finance
        } else if combined.contains("sholat") || combined.contains("doa") || combined.contains("ibadah") || combined.contains("meditasi") || combined.contains("mengaji") {
            category = .spiritual
        } else if combined.contains("rumah") || combined.contains("kamar") || combined.contains("bersih") || combined.contains("cucian") || combined.contains("masak") {
            category = .home
        } else {
            category = .personal
        }

        // 2. Detect Priority
        let priority: TaskPriority
        if combined.contains("penting") || combined.contains("urgent") || combined.contains("darurat") || combined.contains("segera") || combined.contains("asap") || combined.contains("deadline") || combined.contains("tinggi") || combined.contains("ujian") {
            priority = .high
        } else if combined.contains("santai") || combined.contains("kapan-kapan") || combined.contains("opsional") || combined.contains("nanti") || combined.contains("rendah") {
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
