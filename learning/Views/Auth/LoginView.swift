//
//  LoginView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI
import GoogleSignIn

struct LoginView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("userName") private var userName: String = "Bruce Wayne"
    @AppStorage("userEmail") private var userEmail: String = "brucewayne27@suarasa.com"
    @AppStorage("userAvatarUrl") private var userAvatarUrl: String = ""

    // Form States
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = true
    @State private var isShowingRegister: Bool = false
    @State private var isGoogleLoading: Bool = false
    @State private var authErrorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.cartoonBg
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: HIGSpacing.xl) {
                        
                        // 1. Header Judul
                        VStack(alignment: .leading, spacing: HIGSpacing.xs) {
                            HStack(spacing: HIGSpacing.xxs) {
                                Text("Welcome Back")
                                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                                    .foregroundColor(.black)
                            }

                            Text("Please sign in with your registered account to continue using our service.")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .lineSpacing(3)
                        }
                        .padding(.top, HIGSpacing.xxl)

                        // 2. Form Input Fields (Email & Password)
                        VStack(spacing: HIGSpacing.md) {
                            // Field Email
                            CartoonInputField(
                                placeholder: "brucewayne27@suarasa.com",
                                text: $email,
                                icon: "envelope.fill",
                                keyboardType: .emailAddress
                            )

                            // Field Password
                            CartoonSecureInputField(
                                placeholder: "••••••••",
                                text: $password
                            )
                        }
                        .padding(.top, HIGSpacing.xs)

                        // 3. Remember Me & Forgot Password
                        HStack {
                            Button {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    rememberMe.toggle()
                                    HapticManager.shared.selection()
                                }
                            } label: {
                                HStack(spacing: HIGSpacing.xs) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(rememberMe ? Color.cartoonCoral : Color.white)
                                            .frame(width: 22, height: 22)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.black, lineWidth: 1.8)
                                            )

                                        if rememberMe {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .black))
                                                .foregroundColor(.white)
                                        }
                                    }

                                    Text("Remember me")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                .frame(minHeight: HIGSpacing.touchTargetMin)
                            }
                            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                            Spacer()

                            Button {
                                // Aksi Forgot Password
                            } label: {
                                Text("Forgot password?")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.cartoonCoral)
                                    .underline()
                                    .frame(minHeight: HIGSpacing.touchTargetMin)
                            }
                        }

                        // 4. Tombol Sign In (Coral Red)
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                HapticManager.shared.success()
                                isLoggedIn = true
                            }
                        } label: {
                            Text("Sign In")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                        .fill(Color.cartoonCoral)
                                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                        .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                                )
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                        .disabled(email.isEmpty || password.isEmpty)
                        .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                        .padding(.top, HIGSpacing.xs)

                        // 🔐 5. Tombol Masuk Cepat Face ID / Touch ID (Async/Await)
                        if BiometricAuthManager.shared.canEvaluateBiometrics() {
                            Button {
                                handleBiometricAuth()
                            } label: {
                                HStack(spacing: HIGSpacing.xs) {
                                    Image(systemName: "faceid")
                                        .font(.system(size: 16, weight: .bold))
                                    Text("Masuk dengan \(BiometricAuthManager.shared.biometricType())")
                                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                        .fill(Color.cartoonMint)
                                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                        .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                                )
                            }
                            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                        }

                        // 6. Pembatas "Or"
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("Or")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, HIGSpacing.xs)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical, HIGSpacing.xxs)

                        // 7. Tombol Google Sign In
                        CartoonGoogleSignInButton(
                            title: "Sign in with Google",
                            isLoading: isGoogleLoading
                        ) {
                            handleGoogleSignIn()
                        }

                        Spacer(minLength: 30)

                        // 8. Footer Link ke Register
                        HStack(spacing: HIGSpacing.xxs) {
                            Spacer()
                            Text("Don't have an account?")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.black)

                            Button {
                                isShowingRegister = true
                            } label: {
                                Text("Sign up instead")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.cartoonCoral)
                                    .underline()
                                    .frame(minHeight: HIGSpacing.touchTargetMin)
                            }
                            Spacer()
                        }
                        .padding(.bottom, HIGSpacing.lg)
                    }
                    .padding(.horizontal, HIGSpacing.lg)
                }
            }
            .navigationDestination(isPresented: $isShowingRegister) {
                RegisterView()
                    .navigationBarBackButtonHidden(true)
            }
        }
    }

    // MARK: - Biometric Auth Action (Async/Await)
    private func handleBiometricAuth() {
        Task { @MainActor in
            do {
                let success = try await BiometricAuthManager.shared.authenticate(reason: "Masuk cepat ke aplikasi")
                if success {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isLoggedIn = true
                    }
                }
            } catch let error as BiometricAuthError {
                if case .userCanceled = error {
                    // Dibatalkan secara sengaja oleh pengguna
                    return
                }
                authErrorMessage = error.localizedDescription
            } catch {
                authErrorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Google Sign In Action (Async/Await)
    private func handleGoogleSignIn() {
        Task { @MainActor in
            isGoogleLoading = true
            defer { isGoogleLoading = false }

            do {
                let user = try await GoogleAuthManager.shared.signIn()
                let name = user.profile?.name ?? "Google User"
                let email = user.profile?.email ?? ""
                let avatar = user.profile?.imageURL(withDimension: 240)?.absoluteString ?? ""

                userName = name
                userEmail = email
                userAvatarUrl = avatar

                HapticManager.shared.success()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isLoggedIn = true
                }
            } catch let error as GoogleAuthError {
                if case .userCanceled = error {
                    // Dibatalkan oleh user secara sengaja, tidak perlu warning keras
                    return
                }
                print("Google Auth Error: \(error.localizedDescription)")
                HapticManager.shared.warning()
            } catch {
                print("Google Sign In Error: \(error.localizedDescription)")
                HapticManager.shared.warning()
            }
        }
    }
}

#Preview {
    LoginView()
}
