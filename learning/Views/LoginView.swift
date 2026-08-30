//
//  LoginView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    
    // Form States
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = true
    @State private var isShowingRegister: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(red: 0.98, green: 0.97, blue: 0.96)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        
                        // 1. Header Judul
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Text("Welcome Back")
                                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                                    .foregroundColor(.black)
                            }

                            Text("Please sign in with your registered account to continue using our service.")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .lineSpacing(3)
                        }
                        .padding(.top, 40)

                        // 2. Form Input Fields (Email & Password)
                        VStack(spacing: 16) {
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
                        .padding(.top, 8)

                        // 3. Remember Me & Forgot Password
                        HStack {
                            Button {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    rememberMe.toggle()
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(rememberMe ? Color(red: 0.95, green: 0.42, blue: 0.33) : Color.white)
                                            .frame(width: 20, height: 20)
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
                            }
                            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                            Spacer()

                            Button {
                                // Aksi Forgot Password
                            } label: {
                                Text("Forgot password?")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.95, green: 0.42, blue: 0.33))
                                    .underline()
                            }
                        }

                        // 4. Tombol Sign In (Coral Red)
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isLoggedIn = true
                            }
                        } label: {
                            Text("Sign In")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color(red: 0.95, green: 0.42, blue: 0.33))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                                .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.5))
                        .disabled(email.isEmpty || password.isEmpty)
                        .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                        .padding(.top, 8)

                        // 5. Pembatas "Or"
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("Or")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 6)

                        // 6. Tombol Social Login
                        HStack(spacing: 14) {
                            SocialCartoonButton(icon: "g.circle.fill", iconColor: .red) {
                                withAnimation(.spring()) { isLoggedIn = true }
                            }
                            
                            SocialCartoonButton(icon: "apple.logo", iconColor: .black) {
                                withAnimation(.spring()) { isLoggedIn = true }
                            }
                            
                            SocialCartoonButton(icon: "f.circle.fill", iconColor: .blue) {
                                withAnimation(.spring()) { isLoggedIn = true }
                            }
                        }

                        Spacer(minLength: 30)

                        // 7. Footer Link ke Register
                        HStack(spacing: 4) {
                            Spacer()
                            Text("Don't have an account?")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.black)
                            
                            Button {
                                isShowingRegister = true
                            } label: {
                                Text("Sign up instead")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.95, green: 0.42, blue: 0.33))
                                    .underline()
                            }
                            Spacer()
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 22)
                }
            }
            .navigationDestination(isPresented: $isShowingRegister) {
                RegisterView()
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}

#Preview {
    LoginView()
}
