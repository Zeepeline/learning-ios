import SwiftUI
import GoogleSignIn

@MainActor
final class GoogleAuthManager {
    static let shared = GoogleAuthManager()
    private init() {}

    func signIn(completion: @escaping (Result<GIDGoogleUser, Error>) -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = result?.user else {
                return
            }

            completion(.success(user))
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
}
