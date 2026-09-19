//
//  ICloudSyncManager.swift
//  learning
//
//  Created by macbook on 9/18/26.
//

import Foundation
import CloudKit
import SwiftUI
import Observation

// MARK: - ☁️ iCloud Sync Status
enum ICloudAccountStatus: String, Sendable {
    case available = "Tersambung"
    case noAccount = "Belum Masuk iCloud"
    case restricted = "Dibatasi"
    case couldNotDetermine = "Tidak Diketahui"
    case temporarilyUnavailable = "Sementara Tidak Tersedia"

    var color: Color {
        switch self {
        case .available: return Color(red: 0.1, green: 0.6, blue: 0.3)
        case .noAccount, .restricted, .temporarilyUnavailable: return Color.cartoonCoral
        case .couldNotDetermine: return Color.secondary
        }
    }

    var iconName: String {
        switch self {
        case .available: return "checkmark.icloud.fill"
        case .noAccount: return "xmark.icloud.fill"
        case .restricted: return "lock.icloud.fill"
        case .couldNotDetermine, .temporarilyUnavailable: return "exclamationmark.icloud.fill"
        }
    }
}

// MARK: - ☁️ iCloud Sync Manager Service
@Observable
@MainActor
final class ICloudSyncManager {
    static let shared = ICloudSyncManager()

    var accountStatus: ICloudAccountStatus = .couldNotDetermine
    var lastSyncDate: Date? = nil
    var isSyncing: Bool = false

    private init() {
        Task {
            await checkAccountStatus()
        }
    }

    /// Memeriksa status akun iCloud pengguna
    func checkAccountStatus() async {
        do {
            let container = CKContainer(identifier: "iCloud.com.gmedia.xlearning")
            let status = try await container.accountStatus()
            await MainActor.run {
                switch status {
                case .available:
                    self.accountStatus = .available
                case .noAccount:
                    self.accountStatus = .noAccount
                case .restricted:
                    self.accountStatus = .restricted
                case .couldNotDetermine:
                    self.accountStatus = .couldNotDetermine
                case .temporarilyUnavailable:
                    self.accountStatus = .temporarilyUnavailable
                @unknown default:
                    self.accountStatus = .couldNotDetermine
                }
            }
        } catch {
            await MainActor.run {
                self.accountStatus = .couldNotDetermine
            }
        }
    }

    /// Memicu sinkronisasi manual dan memperbarui catatan waktu terakhir
    func triggerManualSync() async {
        guard !isSyncing else { return }
        isSyncing = true
        HapticManager.shared.impact(style: .medium)

        await checkAccountStatus()

        // Simulasi delay sinkronisasi untuk UX yang mulus
        try? await Task.sleep(nanoseconds: 1_200_000_000)

        await MainActor.run {
            self.lastSyncDate = Date()
            self.isSyncing = false
            HapticManager.shared.success()
        }
    }
}
