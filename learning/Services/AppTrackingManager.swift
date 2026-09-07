//
//  AppTrackingManager.swift
//  learning
//
//  Created by macbook on 9/5/26.
//

import Foundation
import AppTrackingTransparency
import AdSupport
import SwiftUI
import Combine

// MARK: - 📊 AppTrackingTransparency Manager
@MainActor
final class AppTrackingManager: ObservableObject {
    static let shared = AppTrackingManager()

    @Published var trackingStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    @Published var idfaString: String = "Belum Ada Izin"
    @Published var isAuthorized: Bool = false
    @Published var isRequesting: Bool = false

    private init() {
        checkTrackingStatus()
    }

    /// Mendapatkan IDFA jika diizinkan oleh pengguna
    var advertisingIdentifier: String? {
        guard trackingStatus == .authorized else { return nil }
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }

    /// Mengecek status izin pelacakan saat ini dan memperbarui properti reaktif
    func checkTrackingStatus() {
        self.trackingStatus = ATTrackingManager.trackingAuthorizationStatus
        switch self.trackingStatus {
        case .authorized:
            self.isAuthorized = true
            let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            self.idfaString = idfa
        case .denied:
            self.isAuthorized = false
            self.idfaString = "Ditolak oleh Pengguna (Denied)"
        case .restricted:
            self.isAuthorized = false
            self.idfaString = "Dibatasi Sistem / MDM (Restricted)"
        case .notDetermined:
            self.isAuthorized = false
            self.idfaString = "Belum Meminta Izin (Not Determined)"
        @unknown default:
            self.isAuthorized = false
            self.idfaString = "Status Tidak Diketahui"
        }
    }

    /// Meminta izin pelacakan resmi melalui dialog sistem Apple (Async/Await)
    @discardableResult
    func requestTrackingAuthorization() async -> ATTrackingManager.AuthorizationStatus {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            checkTrackingStatus()
            return self.trackingStatus
        }

        isRequesting = true
        defer { isRequesting = false }

        // Delay singkat agar UI siap memunculkan prompt dialog sistem
        try? await Task.sleep(nanoseconds: 300_000_000)

        let status = await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        self.checkTrackingStatus()
        return status
    }

    /// Membuka halaman Pengaturan iOS jika izin ditolak
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    /// Judul status yang rapi untuk UI
    var statusTitle: String {
        switch trackingStatus {
        case .authorized:
            return "Diizinkan (Authorized)"
        case .denied:
            return "Ditolak (Denied)"
        case .restricted:
            return "Dibatasi (Restricted)"
        case .notDetermined:
            return "Belum Ditentukan (Not Determined)"
        @unknown default:
            return "Tidak Dikenal"
        }
    }

    /// Deskripsi penjelas status
    var statusDescription: String {
        switch trackingStatus {
        case .authorized:
            return "Pengguna telah memberikan izin pelacakan. IDFA dapat digunakan untuk analisis & atribusi."
        case .denied:
            return "Pengguna memilih untuk tidak dilacak. Anda bisa mengubah izin ini di Pengaturan iOS."
        case .restricted:
            return "Akses pelacakan dibatasi oleh profil perangkat, Screen Time, atau akun di bawah umur."
        case .notDetermined:
            return "Aplikasi belum memunculkan dialog permintaan izin pelacakan Apple kepada pengguna."
        @unknown default:
            return "Status pelacakan saat ini tidak dapat diidentifikasi."
        }
    }

    /// Warna tema status bergaya kartun
    var statusColor: Color {
        switch trackingStatus {
        case .authorized:
            return Color.cartoonMint
        case .denied, .restricted:
            return Color.cartoonCoral
        case .notDetermined:
            return Color.cartoonYellow
        @unknown default:
            return Color.gray
        }
    }

    /// Ikon representasi status
    var statusIcon: String {
        switch trackingStatus {
        case .authorized:
            return "checkmark.seal.fill"
        case .denied:
            return "xmark.seal.fill"
        case .restricted:
            return "lock.shield.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        @unknown default:
            return "exclamationmark.triangle.fill"
        }
    }
}
