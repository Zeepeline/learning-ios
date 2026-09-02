//
//  BiometricAuthManager.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import LocalAuthentication

// MARK: - 🔐 LocalAuthentication Manager (Face ID / Touch ID)
final class BiometricAuthManager {
    static let shared = BiometricAuthManager()
    private init() {}

    /// Mengecek apakah perangkat mendukung Face ID / Touch ID
    func canEvaluateBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Mendapatkan jenis biometrik yang aktif (Face ID / Touch ID)
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

    /// Melakukan autentikasi Face ID / Touch ID
    func authenticate(reason: String = "Gunakan biometrik untuk masuk ke aplikasi", completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    if success {
                        HapticManager.shared.success()
                        completion(true, nil)
                    } else {
                        HapticManager.shared.error()
                        let message = authError?.localizedDescription ?? "Autentikasi gagal"
                        completion(false, message)
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(false, error?.localizedDescription ?? "Perangkat tidak mendukung biometrik.")
            }
        }
    }
}
