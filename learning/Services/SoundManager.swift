//
//  SoundManager.swift
//  learning
//
//  Created by macbook on 9/7/26.
//

import Foundation
import AVFoundation
import AudioToolbox
import SwiftUI
import UserNotifications
import Observation

// MARK: - 🔔 Notification Tone Options
enum NotificationTone: String, CaseIterable, Identifiable {
    case defaultSystem = "default_system"
    case cartoonBell = "cartoon_bell"
    case zenChime = "zen_chime"
    case energeticAlert = "energetic_alert"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .defaultSystem: return "Default iOS"
        case .cartoonBell: return "Cartoon Bell"
        case .zenChime: return "Zen Chime"
        case .energeticAlert: return "Energetic Pulse"
        }
    }

    var iconName: String {
        switch self {
        case .defaultSystem: return "bell.fill"
        case .cartoonBell: return "bell.badge.fill"
        case .zenChime: return "sparkles"
        case .energeticAlert: return "bolt.fill"
        }
    }

    var fileName: String? {
        switch self {
        case .defaultSystem: return nil
        case .cartoonBell: return "cartoon_bell.caf"
        case .zenChime: return "zen_chime.caf"
        case .energeticAlert: return "energetic_alert.caf"
        }
    }

    var notificationSound: UNNotificationSound {
        guard let fileName = fileName else {
            return .default
        }
        return UNNotificationSound(named: UNNotificationSoundName(fileName))
    }
}

// MARK: - 🌧️ Pomodoro Ambient Soundscapes
enum AmbientSound: String, CaseIterable, Identifiable {
    case none = "none"
    case rain = "rain"
    case ocean = "ocean"
    case forest = "forest"
    case cafe = "cafe"
    case whiteNoise = "white_noise"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "Mati"
        case .rain: return "Hujan Rintik"
        case .ocean: return "Deburan Ombak"
        case .forest: return "Hutan & Angin"
        case .cafe: return "Suasana Kafe"
        case .whiteNoise: return "White Noise"
        }
    }

    var iconName: String {
        switch self {
        case .none: return "speaker.slash.fill"
        case .rain: return "cloud.rain.fill"
        case .ocean: return "water.waves"
        case .forest: return "tree.fill"
        case .cafe: return "cup.and.saucer.fill"
        case .whiteNoise: return "waveform"
        }
    }

    var themeColor: Color {
        switch self {
        case .none: return Color.gray
        case .rain: return Color.cartoonBlue
        case .ocean: return Color.cartoonMint
        case .forest: return Color.cartoonYellow
        case .cafe: return Color.cartoonOrange
        case .whiteNoise: return Color.cartoonLavender
        }
    }
}

// MARK: - 🔊 Unified Sound & Ambient Audio Manager (High Performance & Zero Cold-Start Lag)
@Observable
@MainActor
final class SoundManager {
    static let shared = SoundManager()

    // MARK: - Published State
    var selectedTone: NotificationTone = .cartoonBell {
        didSet {
            UserDefaults.standard.set(selectedTone.rawValue, forKey: "selected_notification_tone")
        }
    }

    var selectedAmbient: AmbientSound = .none {
        didSet {
            UserDefaults.standard.set(selectedAmbient.rawValue, forKey: "selected_ambient_sound")
            if isPlayingAmbient {
                playAmbient(selectedAmbient)
            }
        }
    }

    var ambientVolume: Float = 0.5 {
        didSet {
            UserDefaults.standard.set(ambientVolume, forKey: "ambient_volume")
            mainMixer?.outputVolume = ambientVolume
        }
    }

    var isAutoPlayAmbientWithPomodoro: Bool = true {
        didSet {
            UserDefaults.standard.set(isAutoPlayAmbientWithPomodoro, forKey: "is_auto_ambient_pomodoro")
        }
    }

    var isSoundFXEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isSoundFXEnabled, forKey: "is_sound_fx_enabled")
        }
    }

    var isPlayingAmbient: Bool = false

    // MARK: - Audio Engine Properties & In-Memory Player Cache
    @ObservationIgnored private var audioEngine: AVAudioEngine?
    @ObservationIgnored private var noiseNode: AVAudioSourceNode?
    @ObservationIgnored private var mainMixer: AVAudioMixerNode?
    @ObservationIgnored private var isAudioSessionConfigured: Bool = false
    @ObservationIgnored private var playerCache: [String: AVAudioPlayer] = [:]

    private init() {
        loadSettings()
        // ⚡ Catatan Optimasi: AudioSession sekarang diinisialisasi secara lazy (Just-In-Time)
        // saat pengguna memutar suara, sehingga menghemat waktu cold-start aplikasi.
    }

    private func loadSettings() {
        if let savedTone = UserDefaults.standard.string(forKey: "selected_notification_tone"),
           let tone = NotificationTone(rawValue: savedTone) {
            self.selectedTone = tone
        }

        if let savedAmbient = UserDefaults.standard.string(forKey: "selected_ambient_sound"),
           let ambient = AmbientSound(rawValue: savedAmbient) {
            self.selectedAmbient = ambient
        }

        if UserDefaults.standard.object(forKey: "ambient_volume") != nil {
            self.ambientVolume = UserDefaults.standard.float(forKey: "ambient_volume")
        }

        if UserDefaults.standard.object(forKey: "is_auto_ambient_pomodoro") != nil {
            self.isAutoPlayAmbientWithPomodoro = UserDefaults.standard.bool(forKey: "is_auto_ambient_pomodoro")
        }

        if UserDefaults.standard.object(forKey: "is_sound_fx_enabled") != nil {
            self.isSoundFXEnabled = UserDefaults.standard.bool(forKey: "is_sound_fx_enabled")
        }
    }

    /// Setup Audio Session secara Lazy & Non-blocking
    private func setupAudioSessionIfNeeded() {
        guard !isAudioSessionConfigured else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            self.isAudioSessionConfigured = true
        } catch {
            print("⚠️ Gagal inisialisasi AVAudioSession: \(error.localizedDescription)")
        }
    }

    // MARK: - 🔔 In-Memory Cached Sound Player
    func previewNotificationTone(_ tone: NotificationTone) {
        HapticManager.shared.selection()
        guard let fileName = tone.fileName else {
            AudioServicesPlaySystemSound(1007)
            return
        }

        setupAudioSessionIfNeeded()

        // ⚡ Gunakan cached player jika tersedia, hindari I/O disk berulang
        if let cachedPlayer = playerCache[fileName] {
            cachedPlayer.currentTime = 0
            cachedPlayer.play()
            return
        }

        let name = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension

        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.volume = 1.0
                player.play()
                playerCache[fileName] = player
            } catch {
                AudioServicesPlaySystemSound(1007)
            }
        } else {
            AudioServicesPlaySystemSound(1007)
        }
    }

    // MARK: - 🎛️ UI Sound Effects
    func playTaskCompletedSound() {
        guard isSoundFXEnabled else { return }
        HapticManager.shared.success()
        previewNotificationTone(.cartoonBell)
    }

    func playButtonTapSound() {
        guard isSoundFXEnabled else { return }
        AudioServicesPlaySystemSound(1104) // Tink/Tap pop
    }

    func playPomodoroFinishSound() {
        guard isSoundFXEnabled else { return }
        HapticManager.shared.impact(style: .heavy)
        previewNotificationTone(.zenChime)
    }

    // MARK: - 🌧️ Procedural Ambient White Noise & Nature Soundscapes
    func toggleAmbient() {
        if isPlayingAmbient {
            stopAmbient()
        } else {
            if selectedAmbient == .none {
                selectedAmbient = .rain
            }
            playAmbient(selectedAmbient)
        }
    }

    func playAmbient(_ ambient: AmbientSound) {
        stopAmbientEngine()

        guard ambient != .none else {
            self.isPlayingAmbient = false
            return
        }

        setupAudioSessionIfNeeded()

        let engine = AVAudioEngine()
        let mixer = engine.mainMixerNode
        mixer.outputVolume = ambientVolume

        let format = mixer.outputFormat(forBus: 0)
        let sampleRate = Float(format.sampleRate)

        // Variabel state generator prosedural
        var phase: Float = 0.0
        var b0: Float = 0.0, b1: Float = 0.0, b2: Float = 0.0
        var oceanPhase: Float = 0.0
        var windPhase: Float = 0.0
        var cafeFilter: Float = 0.0

        let sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let buffer = ablPointer[0]
            guard let ptr = buffer.mData?.assumingMemoryBound(to: Float.self) else { return noErr }

            for frame in 0..<Int(frameCount) {
                let white = Float.random(in: -1.0...1.0)
                var sample: Float = 0.0

                switch ambient {
                case .none:
                    sample = 0.0

                case .whiteNoise:
                    // Clean gentle white noise
                    sample = white * 0.12

                case .rain:
                    // Pink noise filtered + random droplet pops (Rain effect)
                    b0 = 0.99765 * b0 + white * 0.0990460
                    b1 = 0.96300 * b1 + white * 0.2965164
                    b2 = 0.57000 * b2 + white * 1.0526913
                    let pink = (b0 + b1 + b2 + white * 0.1848) * 0.04
                    let drip = Float.random(in: 0...1000) > 998 ? Float.random(in: -0.2...0.2) : 0.0
                    sample = pink + drip

                case .ocean:
                    // Slow sweeping ocean wave surge (0.1 Hz amplitude modulation)
                    oceanPhase += (2.0 * .pi * 0.08) / sampleRate
                    if oceanPhase > 2.0 * .pi { oceanPhase -= 2.0 * .pi }
                    let waveSurge = (sin(oceanPhase) + 1.0) * 0.5
                    b0 = 0.98 * b0 + white * 0.05
                    sample = b0 * (0.05 + waveSurge * 0.18)

                case .forest:
                    // Soft breeze wind + gentle chirp resonance
                    windPhase += (2.0 * .pi * 0.15) / sampleRate
                    if windPhase > 2.0 * .pi { windPhase -= 2.0 * .pi }
                    let breeze = (sin(windPhase) * 0.5 + 0.5) * 0.08
                    b0 = 0.95 * b0 + white * 0.04
                    phase += (2.0 * .pi * 2200.0) / sampleRate
                    if phase > 2.0 * .pi { phase -= 2.0 * .pi }
                    let chirp = Float.random(in: 0...10000) > 9995 ? sin(phase) * 0.05 : 0.0
                    sample = b0 * breeze + chirp

                case .cafe:
                    // Warm low-passed brownian noise + low rumble
                    cafeFilter = 0.99 * cafeFilter + white * 0.03
                    sample = cafeFilter * 0.15
                }

                // Tulis sample ke buffer
                ptr[frame] = max(-1.0, min(1.0, sample))

                // Jika format stereo (channel > 1)
                if ablPointer.count > 1, let rightPtr = ablPointer[1].mData?.assumingMemoryBound(to: Float.self) {
                    rightPtr[frame] = ptr[frame]
                }
            }
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mixer, format: format)

        do {
            try engine.start()
            self.audioEngine = engine
            self.noiseNode = sourceNode
            self.mainMixer = mixer
            self.isPlayingAmbient = true
        } catch {
            print("⚠️ Gagal memulai ambient sound engine: \(error.localizedDescription)")
            self.isPlayingAmbient = false
        }
    }

    func stopAmbient() {
        stopAmbientEngine()
        self.isPlayingAmbient = false
    }

    private func stopAmbientEngine() {
        audioEngine?.stop()
        if let node = noiseNode {
            audioEngine?.detach(node)
        }
        audioEngine = nil
        noiseNode = nil
        mainMixer = nil
    }
}
