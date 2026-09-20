//
//  VoiceInputManager.swift
//  learning
//
//  Created by macbook on 9/20/26.
//

import Foundation
import Speech
import AVFoundation
import SwiftUI
import Combine

// MARK: - 🎙️ Voice Input & Speech Recognition Manager (Voice-to-Task Dictation with Smart Phonetic Normalizer)
@MainActor
final class VoiceInputManager: ObservableObject {
    static let shared = VoiceInputManager()

    @Published var isRecording: Bool = false
    @Published var transcribedText: String = ""
    @Published var errorMessage: String? = nil
    @Published var audioLevel: CGFloat = 0.0

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // Domain Keywords for Speech Recognition Bias
    private let contextualAppKeywords = [
        "Pomodoro", "SwiftData", "SwiftUI", "Coding", "Habit",
        "Screen Time", "Subtask", "Belajar", "Prioritas", "Notifikasi",
        "Kalender", "Olahraga", "Tugas", "To-Do", "Catat", "Jadwal",
        "Selesai", "Checklist", "Fokus", "Tinggi", "Sedang", "Rendah",
        "Meeting", "Workout", "Gym", "Langkah", "Kalori", "Shield"
    ]

    private init() {
        // Coba gunakan Bahasa Indonesia terlebih dahulu, fallback ke sistem lokal jika tidak tersedia
        let indonesianLocale = Locale(identifier: "id-ID")
        if SFSpeechRecognizer.supportedLocales().contains(indonesianLocale) {
            self.speechRecognizer = SFSpeechRecognizer(locale: indonesianLocale)
        } else {
            self.speechRecognizer = SFSpeechRecognizer(locale: Locale.current) ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        }
    }

    /// Memeriksa dan meminta izin Speech Recognition & Mikrofon
    func requestPermissions() async -> Bool {
        let speechAuthStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechAuthStatus == .authorized else {
            self.errorMessage = "Izin Pengenalan Suara belum diaktifkan di Pengaturan."
            return false
        }

        let micAuthStatus: Bool
        if #available(iOS 17.0, *) {
            micAuthStatus = await AVAudioApplication.requestRecordPermission()
        } else {
            micAuthStatus = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

        guard micAuthStatus else {
            self.errorMessage = "Izin Mikrofon belum diizinkan di Pengaturan."
            return false
        }

        return true
    }

    /// Mulai Merekam dan Menerjemahkan Suara Pengguna secara Real-Time dengan Context Bias
    func startRecording(onTranscription: @escaping (String) -> Void) async {
        guard !isRecording else { return }

        let hasPermissions = await requestPermissions()
        guard hasPermissions else { return }

        // Bersihkan sesi sebelumnya jika ada
        stopRecording()
        transcribedText = ""
        errorMessage = nil

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.errorMessage = "Gagal mengonfigurasi audio session: \(error.localizedDescription)"
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            self.errorMessage = "Gagal membuat speech recognition request."
            return
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.contextualStrings = contextualAppKeywords
        if #available(iOS 16.0, *) {
            recognitionRequest.addsPunctuation = true
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Install Audio Tap untuk merekam dan menganalisis audio meter level
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)

            // Hitung level rata-rata amplitudo suara untuk visualisasi kartun
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frames = buffer.frameLength
            var sum: Float = 0
            for i in 0..<Int(frames) {
                sum += abs(channelData[i])
            }
            let avg = sum / Float(frames)
            let level = CGFloat(min(max(avg * 8.0, 0.0), 1.0))

            Task { @MainActor [weak self] in
                self?.audioLevel = level
            }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            self.errorMessage = "Audio engine gagal dimulai: \(error.localizedDescription)"
            return
        }

        self.isRecording = true
        HapticManager.shared.impact(style: .medium)

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let rawText = result.bestTranscription.formattedString
                let normalized = Self.normalizeSpokenText(rawText)
                Task { @MainActor in
                    self.transcribedText = normalized
                    onTranscription(normalized)
                }
            }

            if error != nil || (result?.isFinal ?? false) {
                Task { @MainActor in
                    self.stopRecording()
                }
            }
        }
    }

    /// Menghentikan Perekaman Suara
    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        isRecording = false
        audioLevel = 0.0

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Toggle Record / Stop
    func toggleRecording(onTranscription: @escaping (String) -> Void) async {
        if isRecording {
            HapticManager.shared.impact(style: .light)
            stopRecording()
        } else {
            await startRecording(onTranscription: onTranscription)
        }
    }

    // MARK: - 🧠 Smart Phonetic & Indonesian Speech Normalizer (Instan ~0.001s)
    static func normalizeSpokenText(_ raw: String) -> String {
        guard !raw.isEmpty else { return raw }
        var text = raw

        // Kamus Perbaikan Fonetik & Salah Dengar Suara Umum (Indo-English Mixed)
        let phoneticRules: [(pattern: String, replacement: String)] = [
            // Typo Kata Tugas / Task
            ("(?i)\\b(tas|tes|taks|teks)\\s+(koding|coding|belajar|swift|kerja)", "tugas $2"),
            ("(?i)\\b(bikin|buat|tambah|tambahkan|catat)\\s+(tas|taks|tek)\\b", "$1 tugas"),
            ("(?i)\\b(to\\s*do|tu\\s*du|tudu)\\b", "to-do"),

            // Typo Nama Teknologi & Istilah
            ("(?i)\\b(suif|suift|swif)\\s*(data|ui)?\\b", "Swift$2"),
            ("(?i)\\b(koding|ngoding)\\b", "coding"),
            ("(?i)\\b(pomo|pomodori|pemodoro|pomodro)\\b", "Pomodoro"),
            ("(?i)\\b(hebit|hebit\\s*tracker)\\b", "Habit"),
            ("(?i)\\b(skrin\\s*tem|skrip\\s*time|screen\\s*tem)\\b", "Screen Time"),
            ("(?i)\\b(miting|rapat\\s*online)\\b", "meeting"),
            ("(?i)\\b(olga|gym\\s*session)\\b", "olahraga"),
            ("(?i)\\b(notip|notipikasi)\\b", "notifikasi"),
            ("(?i)\\b(ceklis|cek\\s*list|centang)\\b", "ceklis"),
            ("(?i)\\b(sub\\s*tas|sub\\s*taks|sabtes)\\b", "subtasks"),
            ("(?i)\\b(urgent|urgen|mendesak)\\b", "prioritas tinggi"),
            ("(?i)\\b(fokus\\s*duapuluh\\s*lima)\\b", "fokus 25 menit"),
            ("(?i)\\b(fokus\\s*limapuluh)\\b", "fokus 50 menit")
        ]

        for rule in phoneticRules {
            if let regex = try? NSRegularExpression(pattern: rule.pattern, options: []) {
                let range = NSRange(location: 0, length: text.utf16.count)
                text = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: rule.replacement)
            }
        }

        // Rapikan spasi berlebih
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
