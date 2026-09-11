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

    dynamic var body: some View {
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

// PATCH-THUNKS-BEGIN (generated by `patchcli prepare` — DO NOT EDIT)
// @generated
// =========================================================================
// AUTOGENERATED BY `patchcli prepare` — DO NOT EDIT THIS SECTION.
//
// Do NOT edit any code in this generated section — neither by hand NOR with
// an AI coding assistant (Copilot, Cursor, Claude, etc.).
//
// Reason: this block is REGENERATED on every `patchcli prepare` run (which
// also runs automatically inside `patchcli build`/`push`/`release`). Any
// manual change here is SILENTLY OVERWRITTEN on the next prepare, and an
// inconsistent thunk can break the OTA fingerprint (causing a MISMATCH that
// blocks your release).
//
// To change a view's behaviour: edit the VIEW SOURCE FILE itself — never
// this generated thunk. To remove this section entirely, delete the block
// from BEGIN to END and re-run `patchcli prepare` (it recreates it).
// =========================================================================
// Patch kept the patch-thunk code for the view(s) below in YOUR file because each is
// declared `private`/`fileprivate` (or its body host-resolves a `private` member) —
// and Swift access control is file-scoped, so a thunk in the separate
// `Patch/Generated/` folder cannot reach it. Only the minimum that genuinely needs
// file-scoped access is here.
// LoginView: helper methods kept here — its body reads private member(s): email, handleBiometricAuth, handleGoogleSignIn, isGoogleLoading, isLoggedIn, isShowingRegister, password, rememberMe.
//   To move this into Patch/Generated/, make those member(s) `internal` (drop
//   `private`/`fileprivate`) and re-run `patchcli prepare`.
#if canImport(SwiftUI)
import SwiftUI
import PatchSDK
import PatchSwiftUI
import PatchRender
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(ActivityKit)
import ActivityKit
#endif
#if canImport(AdSupport)
import AdSupport
#endif
#if canImport(AppIntents)
import AppIntents
#endif
#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif
#if canImport(Combine)
import Combine
#endif
#if canImport(DeviceActivity)
import DeviceActivity
#endif
#if canImport(EventKit)
import EventKit
#endif
#if canImport(ExtensionKit)
import ExtensionKit
#endif
#if canImport(FamilyControls)
import FamilyControls
#endif
#if canImport(Foundation)
import Foundation
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
#if canImport(HealthKit)
import HealthKit
#endif
#if canImport(LocalAuthentication)
import LocalAuthentication
#endif
#if canImport(ManagedSettings)
import ManagedSettings
#endif
#if canImport(Observation)
import Observation
#endif
#if canImport(SafariServices)
import SafariServices
#endif
#if canImport(SwiftData)
import SwiftData
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(UserNotifications)
import UserNotifications
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif

extension LoginView {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_8db8da9b80cafe15"] = { (a: [String]) in a.count >= 14 ? AnyView(VStack(alignment: .leading, spacing: HIGSpacing.xl) {
                        
                        // 1. Header Judul
                        VStack(alignment: .leading, spacing: HIGSpacing.xs) {
                            HStack(spacing: HIGSpacing.xxs) {
                                Text(LocalizedStringKey(a[0]))
                                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                                    .foregroundColor(.black)
                            }

                            Text(LocalizedStringKey(a[1]))
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .lineSpacing(3)
                        }
                        .padding(.top, HIGSpacing.xxl)

                        // 2. Form Input Fields (Email & Password)
                        VStack(spacing: HIGSpacing.md) {
                            // Field Email
                            CartoonInputField(
                                placeholder: a[2],
                                text: $email,
                                icon: a[3],
                                keyboardType: .emailAddress
                            )

                            // Field Password
                            CartoonSecureInputField(
                                placeholder: a[4],
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
                                            Image(systemName: a[5])
                                                .font(.system(size: 10, weight: .black))
                                                .foregroundColor(.white)
                                        }
                                    }

                                    Text(LocalizedStringKey(a[6]))
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
                                Text(LocalizedStringKey(a[7]))
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
                            Text(LocalizedStringKey(a[8]))
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
                                    Image(systemName: a[9])
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
                            
                            Text(LocalizedStringKey(a[10]))
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
                            title: a[11],
                            isLoading: isGoogleLoading
                        ) {
                            handleGoogleSignIn()
                        }

                        Spacer(minLength: 30)

                        // 8. Footer Link ke Register
                        HStack(spacing: HIGSpacing.xxs) {
                            Spacer()
                            Text(LocalizedStringKey(a[12]))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.black)

                            Button {
                                isShowingRegister = true
                            } label: {
                                Text(LocalizedStringKey(a[13]))
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.cartoonCoral)
                                    .underline()
                                    .frame(minHeight: HIGSpacing.touchTargetMin)
                            }
                            Spacer()
                        }
                        .padding(.bottom, HIGSpacing.lg)
                    }
                    .padding(.horizontal, HIGSpacing.lg)) : AnyView(EmptyView()) }
        __s["op_424da24113f49bd6"] = { (_: [String]) in AnyView(RegisterView()) }
        return __s
    }

    /// Resolved design-system token values for this view's `.hostToken(id)`/
    /// `.fontToken(id)`/numeric/string token slots. Empty when the view uses none.
    @MainActor func __patchTokens() -> [String: PatchHostToken] {
        var __t: [String: PatchHostToken] = [:]
        __t["ct_896c50b68f3107a3"] = .color(Color.cartoonBg)
        return __t
    }

    /// Per-row indexed native-action slots for this view's `.indexedForEachSlot`
    /// nodes. Each natively evaluates the body-local collection (over `self`) →
    /// a row count + a per-row factory `(Int) -> AnyView` (closing over `self`, so
    /// each row's real per-row native action works). Empty when the view has none.
    @MainActor func __patchRowSlots() -> [String: PatchRowSlot] {
        [:]
    }

    /// Native-action slots for this view's `.actionSlotButton` nodes — an actions-list
    /// Button (`.swipeActions`/`.toolbar`/`.alert`/`Menu`/`.contextMenu`) whose action is a
    /// native method call. Each closure (`() -> Void`, over `self`) runs the real action;
    /// the SDK wires it to the reconstituted Button by id. Empty when the view has none.
    @MainActor func __patchActionSlots() -> [String: () -> Void] {
        [:]
    }

    /// Native effect-modifier slots for this view's `.nativeEffectSlot` modifiers — an
    /// undispatchable `.task`/`.onAppear`/`.refreshable`/`.onSubmit`/gesture whose closure
    /// runs a native side-effect. Each closure (`(AnyView) -> AnyView`, over `self`) applies
    /// the real modifier to its content; the SDK applies it to the rendered subtree by id.
    /// Empty when the view has none.
    @MainActor func __patchEffectSlots() -> [String: (AnyView) -> AnyView] {
        [:]
    }

    /// Child-view callback slots for this view's `.callbackSlot` nodes — a custom child-view
    /// call whose `() -> Void` closure arg lowers to a WASM dispatch sequence. Each closure
    /// returns the full child-view `AnyView` with the callback arg replaced by a stable
    /// forwarder `{ self.__patchDispatchCallback("<id>") }`. The SDK fills the opaque slot
    /// position from this table by id. Empty when the view has no callback slots.
    @MainActor func __patchCallbackSlots() -> [String: () -> AnyView] {
        [:]
    }
}

#endif
// @generated — END OF AUTOGENERATED SECTION. DO NOT EDIT ABOVE (regenerated by `patchcli prepare`).
// PATCH-THUNKS-END
