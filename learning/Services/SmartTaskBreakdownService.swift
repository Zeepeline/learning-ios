//
//  SmartTaskBreakdownService.swift
//  learning
//
//  Created by macbook on 9/18/26.
//

import Foundation

// MARK: - 🧠 Smart Task Breakdown & Subtask Generator Service
struct SmartTaskBreakdownService: Sendable {
    static let shared = SmartTaskBreakdownService()

    private init() {}

    /// Menghasilkan saran langkah-langkah subtask secara cerdas berdasarkan judul dan kategori tugas
    func generateSuggestions(for title: String, category: String = "Umum") -> [String] {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanTitle.isEmpty else {
            return [
                "Persiapan awal & perencanaan",
                "Eksekusi langkah utama",
                "Review & periksa hasil akhir"
            ]
        }

        // 1. Coding & Software Development
        if cleanTitle.contains("coding") || cleanTitle.contains("swift") || cleanTitle.contains("ios") || cleanTitle.contains("flutter") || cleanTitle.contains("react") || cleanTitle.contains("bug") || cleanTitle.contains("fitur") || cleanTitle.contains("app") || cleanTitle.contains("api") || category == "Coding" {
            return [
                "Analisis kebutuhan fitur & arsitektur kode",
                "Implementasi antarmuka (UI) & tata letak",
                "Hubungkan logika data & state management",
                "Uji coba di Simulator & perbaiki edge cases",
                "Review kode & commit ke Git repository"
            ]
        }

        // 2. Belajar, Kuliah & Ujian
        if cleanTitle.contains("belajar") || cleanTitle.contains("kuliah") || cleanTitle.contains("tugas") || cleanTitle.contains("skripsi") || cleanTitle.contains("buku") || cleanTitle.contains("ujian") || cleanTitle.contains("materi") || category == "Belajar" {
            return [
                "Baca dan pahami materi utama",
                "Rangkum poin-poin penting ke catatan",
                "Latihan soal atau studi kasus mandiri",
                "Evaluasi pemahaman & tandai bagian sulit"
            ]
        }

        // 3. Pekerjaan, Meeting & Proyek
        if cleanTitle.contains("meeting") || cleanTitle.contains("rapat") || cleanTitle.contains("kerja") || cleanTitle.contains("proyek") || cleanTitle.contains("klien") || cleanTitle.contains("presentasi") || category == "Pekerjaan" || category == "Meeting" {
            return [
                "Siapkan agenda & materi presentasi",
                "Ikuti diskusi & catat poin penting notulen",
                "Buat daftar tindak lanjut (Action Items)",
                "Kirim ringkasan hasil meeting ke tim"
            ]
        }

        // 4. Olahraga & Kesehatan
        if cleanTitle.contains("lari") || cleanTitle.contains("gym") || cleanTitle.contains("olahraga") || cleanTitle.contains("workout") || cleanTitle.contains("sepeda") || cleanTitle.contains("sehat") || category == "Kesehatan" {
            return [
                "Pemanasan dinamis 5-10 menit",
                "Latihan sesi inti sesuai target",
                "Pendinginan & peregangan otot",
                "Cukupi asupan cairan & nutrisi pemulihan"
            ]
        }

        // 5. Belanja & Kebutuhan Rumah
        if cleanTitle.contains("beli") || cleanTitle.contains("belanja") || cleanTitle.contains("pasar") || cleanTitle.contains("supermarket") || category == "Belanja" || category == "Rumah" {
            return [
                "Cek persediaan & catat daftar barang",
                "Bandingkan harga & siapkan anggaran",
                "Beli barang sesuai prioritas kebutuhan",
                "Rapikan struk belanja & tata barang di rumah"
            ]
        }

        // 6. Desain & Kreatif
        if cleanTitle.contains("desain") || cleanTitle.contains("design") || cleanTitle.contains("logo") || cleanTitle.contains("figma") || cleanTitle.contains("gambar") || category == "Design" {
            return [
                "Riset inspirasi visual & moodboard",
                "Buat sketsa kasar / wireframe",
                "Desain detail dengan warna & tipografi kartun",
                "Export asset & minta feedback"
            ]
        }

        // 7. Finansial & Keuangan
        if cleanTitle.contains("uang") || cleanTitle.contains("keuangan") || cleanTitle.contains("gaji") || cleanTitle.contains("tagihan") || cleanTitle.contains("investasi") || category == "Keuangan" {
            return [
                "Kumpulkan semua tagihan & mutasi rekening",
                "Alokasikan pos tabungan & kebutuhan wajib",
                "Bayar tagihan sebelum jatuh tempo",
                "Update pencatatan anggaran bulanan"
            ]
        }

        // Default Fallback
        return [
            "Siapkan perlengkapan & rencana kerja",
            "Mulai selesaikan tahap pertama",
            "Lanjutkan hingga progres utama selesai",
            "Cek kualitas & tandai selesai"
        ]
    }
}
