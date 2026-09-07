//
//  BiometricAuthManager.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import LocalAuthentication
import SwiftUI

// MARK: - 🔐 Biometric Auth Error Types
enum BiometricAuthError: LocalizedError {
    case notAvailable(String)
    case userCanceled
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable(let message):
            return message
        case .userCanceled:
            return "Autentikasi biometrik dibatalkan."
        case .failed(let message):
            return message
        }
    }
}

// MARK: - 🔐 LocalAuthentication Manager (Face ID / Touch ID / Optic ID)
@MainActor
final class BiometricAuthManager {
    static let shared = BiometricAuthManager()
    private init() {}

    /// Mengecek apakah perangkat mendukung Face ID / Touch ID
    func canEvaluateBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Mendapatkan jenis biometrik yang aktif (Face ID / Touch ID / Optic ID)
    func biometricType() -> String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID:
            return "Face ID"

        case .touchID:
            return "Touch ID"

        case .opticID:
            return "Optic ID"

        default:
            return "Biometrik"
        }
    }

    /// Melakukan autentikasi Face ID / Touch ID dengan async/await
    @discardableResult
    func authenticate(reason: String = "Gunakan biometrik untuk masuk ke aplikasi") async throws -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            let message = error?.localizedDescription ?? "Perangkat tidak mendukung biometrik."
            throw BiometricAuthError.notAvailable(message)
        }

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            if success {
                HapticManager.shared.success()
                return true
            } else {
                HapticManager.shared.error()
                throw BiometricAuthError.failed("Autentikasi biometrik tidak berhasil.")
            }
        } catch let laError as LAError {
            if laError.code == .userCancel || laError.code == .appCancel || laError.code == .systemCancel {
                throw BiometricAuthError.userCanceled
            }
            HapticManager.shared.error()
            throw BiometricAuthError.failed(laError.localizedDescription)
        } catch {
            HapticManager.shared.error()
            throw error
        }
    }
}
