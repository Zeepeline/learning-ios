//
//  RegisterView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI
import GoogleSignIn

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    
    // Form States
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isAgreed: Bool = false
    @State private var isShowingLogin: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(red: 0.98, green: 0.97, blue: 0.96)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: HIGSpacing.xl) {
                        
                        // 1. Tombol Back Kartun (Touch Target 44x44)
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: HIGSpacing.touchTargetMin, height: HIGSpacing.touchTargetMin)
                                .background(Color.white)
                                .cornerRadius(CartoonMetrics.cornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CartoonMetrics.cornerRadius)
                                        .stroke(Color.black, lineWidth: 1.5)
                                )
                                .shadow(color: .black, radius: 0, x: 2, y: 2)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                        .padding(.top, HIGSpacing.xs)

                        // 2. Header Judul
                        VStack(alignment: .leading, spacing: HIGSpacing.xs) {
                            HStack(spacing: HIGSpacing.xxs) {
                                Text("Create Account")
                                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                                    .foregroundColor(.black)
                                
                                Text("👋")
                                    .font(.system(size: 26))
                            }

                            Text("Please register on our Streamline, where you can continue using our service.")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .lineSpacing(3)
                        }
                        .padding(.top, HIGSpacing.xxs)

                        // 3. Form Input Fields (Kartun Neo-Brutalist)
                        VStack(spacing: HIGSpacing.md) {
                            // Field Nama Lengkap
                            CartoonInputField(
                                placeholder: "Bruce Wayne",
                                text: $fullName,
                                icon: "person.fill"
                            )

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

                        // 4. Checkbox Persetujuan Terms (Touch Target Friendly)
                        HStack(spacing: HIGSpacing.xs) {
                            Button {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    isAgreed.toggle()
                                }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isAgreed ? Color.cartoonCoral : Color.white)
                                        .frame(width: 22, height: 22)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.black, lineWidth: 1.8)
                                        )

                                    if isAgreed {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11, weight: .black))
                                            .foregroundColor(.white)
                                        }
                                }
                                .frame(width: 36, height: 36)
                            }
                            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                            Text("I agree to privacy policy & terms")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .underline()
                        }
                        .padding(.top, HIGSpacing.xxs)

                        // 5. Tombol Continue (Warna Coral-Red Tebal) - 52pt Height
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isLoggedIn = true
                            }
                        } label: {
                            Text("Continue")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.cartoonCoral)
                                .cornerRadius(CartoonMetrics.cardCornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                        .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                                )
                                .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.5))
                        .disabled(!isAgreed || fullName.isEmpty || email.isEmpty || password.isEmpty)
                        .opacity((!isAgreed || fullName.isEmpty || email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                        .padding(.top, HIGSpacing.xs)

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

                        // 7. Tombol Google Sign Up
                        CartoonGoogleSignInButton(title: "Sign up with Google") {
                            GoogleAuthManager.shared.signIn { result in
                                switch result {
                                case .success(let user):
                                    let name = user.profile?.name ?? "Google User"
                                    let email = user.profile?.email ?? ""
                                    
                                    UserDefaults.standard.set(name, forKey: "userName")
                                    UserDefaults.standard.set(email, forKey: "userEmail")
                                    
                                    withAnimation {
                                        isLoggedIn = true
                                    }
                                    HapticManager.shared.success()
                                    
                                case .failure(let error):
                                    print("Google Sign In Error: \(error.localizedDescription)")
                                    HapticManager.shared.warning()
                                }
                            }
                        }

                        Spacer(minLength: 25)

                        // 8. Footer Link ke Sign In
                        HStack(spacing: HIGSpacing.xxs) {
                            Spacer()
                            Text("Already have an account?")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.black)
                            
                            Button {
                                isShowingLogin = true
                            } label: {
                                Text("Sign in instead")
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
            .navigationDestination(isPresented: $isShowingLogin) {
                LoginView()
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}

// MARK: - 🎨 Komponen Input Field Kartun (Sesuai HIG Spacing)
struct CartoonInputField: View {
    var placeholder: String
    @Binding var text: String
    var icon: String?
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: HIGSpacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            TextField(placeholder, text: $text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .keyboardType(keyboardType)
                .autocapitalization(.none)
        }
        .padding(.horizontal, HIGSpacing.md)
        .frame(minHeight: 48)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
    }
}

// MARK: - 🔐 Input Field Password Kartun
struct CartoonSecureInputField: View {
    var placeholder: String
    @Binding var text: String
    @State private var isSecured: Bool = true

    var body: some View {
        HStack(spacing: HIGSpacing.sm) {
            Image(systemName: "lock.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            if isSecured {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }

            Button {
                isSecured.toggle()
            } label: {
                Image(systemName: isSecured ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, HIGSpacing.md)
        .frame(minHeight: 48)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
    }
}

#Preview {
    RegisterView()
}
