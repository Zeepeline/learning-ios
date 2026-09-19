//
//  HapticManager.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import UIKit

// MARK: - 📱 Pre-Warmed Ultra-Low Latency Haptic Engine
@MainActor
final class HapticManager {
    static let shared = HapticManager()

    // Pre-allocated feedback generators to eliminate allocation overhead during touches
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        prepare()
    }

    /// Pre-warm all haptic engines for instant tactile response
    func prepare() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }

    /// Getaran sukses saat tugas selesai
    func success() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    /// Getaran peringatan saat menghapus atau membatalkan
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    /// Getaran error
    func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }

    /// Getaran ketukan tombol pop (ringan / sedang / berat / rigid / soft)
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        switch style {
        case .light:
            lightGenerator.impactOccurred()
            lightGenerator.prepare()
        case .medium:
            mediumGenerator.impactOccurred()
            mediumGenerator.prepare()
        case .heavy:
            heavyGenerator.impactOccurred()
            heavyGenerator.prepare()
        case .rigid:
            rigidGenerator.impactOccurred()
            rigidGenerator.prepare()
        case .soft:
            softGenerator.impactOccurred()
            softGenerator.prepare()
        @unknown default:
            mediumGenerator.impactOccurred()
            mediumGenerator.prepare()
        }
    }

    /// Getaran saat memilih tanggal atau kategori
    func selection() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }
}
