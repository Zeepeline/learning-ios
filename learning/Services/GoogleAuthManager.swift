import Foundation
import UIKit
import SwiftUI
import GoogleSignIn

// MARK: - 🌐 Google Auth Error Types
enum GoogleAuthError: LocalizedError {
    case noRootViewController
    case userCanceled
    case missingProfile
    case notSignedIn
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .noRootViewController:
            return "Tidak dapat menemukan tampilan utama untuk autentikasi."
        case .userCanceled:
            return "Proses login Google dibatalkan."
        case .missingProfile:
            return "Data profil Google tidak ditemukan."
        case .notSignedIn:
            return "Belum login dengan akun Google."
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - 🔐 Google Authentication Service Manager
@MainActor
final class GoogleAuthManager {
    static let shared = GoogleAuthManager()
    private init() {}

    /// Status apakah pengguna saat ini sedang login dengan Google
    var isUserLoggedIn: Bool {
        GIDSignIn.sharedInstance.currentUser != nil
    }

    /// Email pengguna Google saat ini
    var currentUserEmail: String? {
        GIDSignIn.sharedInstance.currentUser?.profile?.email
    }

    /// Nama pengguna Google saat ini
    var currentUserName: String? {
        GIDSignIn.sharedInstance.currentUser?.profile?.name
    }

    /// Mendapatkan Access Token aktif milik user (otomatis refresh jika kedaluwarsa)
    func getValidAccessToken() async throws -> String {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GoogleAuthError.notSignedIn
        }

        let refreshedUser = try await user.refreshTokensIfNeeded()
        return refreshedUser.accessToken.tokenString
    }

    /// Login standar Google Sign-In (Lancar & Bebas Error Consent Screen)
    func signIn() async throws -> GIDGoogleUser {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController ?? windowScene.windows.first?.rootViewController else {
            throw GoogleAuthError.noRootViewController
        }

        do {
            // Gunakan standard scopes agar proses sign in tidak diblokir oleh Google OAuth Consent Screen
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController
            )
            return result.user
        } catch {
            let nsError = error as NSError
            // GIDSignInError.canceled error code is -5
            if nsError.domain == kGIDSignInErrorDomain && nsError.code == GIDSignInError.canceled.rawValue {
                throw GoogleAuthError.userCanceled
            }
            throw error
        }
    }

    /// Meminta izin tambahan Generative Language (Gemini) secara bertahap (Incremental Auth)
    func requestGenerativeLanguageScope() async -> Bool {
        guard let user = GIDSignIn.sharedInstance.currentUser,
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController ?? windowScene.windows.first?.rootViewController else {
            return false
        }

        let generativeScope = "https://www.googleapis.com/auth/generative-language"
        if user.grantedScopes?.contains(generativeScope) == true {
            return true
        }

        do {
            _ = try await user.addScopes([generativeScope], presenting: rootViewController)
            return true
        } catch {
            return false
        }
    }

    /// Restore previous sign-in secara diam-diam (silent sign in)
    func restorePreviousSignIn() async -> GIDGoogleUser? {
        do {
            let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            return user
        } catch {
            return nil
        }
    }

    /// Sign out dari Google session
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
}
