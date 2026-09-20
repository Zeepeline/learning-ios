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

// MARK: - 🎙️ Voice Input & Speech Recognition Manager (Voice-to-Task Dictation)
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

    /// Mulai Merekam dan Menerjemahkan Suara Pengguna secara Real-Time
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
                let text = result.bestTranscription.formattedString
                Task { @MainActor in
                    self.transcribedText = text
                    onTranscription(text)
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
}
