//
//  HapticManager.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import UIKit

// MARK: - 📳 Haptic Vibration Engine (CoreHaptics / UIKit Feedback)
final class HapticManager {
    static let shared = HapticManager()
    private init() {}

    /// Getaran sukses saat tugas selesai
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// Getaran peringatan saat menghapus atau membatalkan
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    /// Getaran error
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }

    /// Getaran ketukan tombol pop (ringan / sedang / berat)
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Getaran saat memilih tanggal atau kategori
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
