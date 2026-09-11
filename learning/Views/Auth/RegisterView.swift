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
    @AppStorage("userName") private var userName: String = "Bruce Wayne"
    @AppStorage("userEmail") private var userEmail: String = "brucewayne27@suarasa.com"
    @AppStorage("userAvatarUrl") private var userAvatarUrl: String = ""
    
    // Form States
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isAgreed: Bool = false
    @State private var isShowingLogin: Bool = false
    @State private var isGoogleLoading: Bool = false

    dynamic var body: some View {
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
                                .background(
                                    RoundedRectangle(cornerRadius: CartoonMetrics.cornerRadius)
                                        .fill(Color.white)
                                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: CartoonMetrics.cornerRadius)
                                        .stroke(Color.black, lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                        .padding(.top, HIGSpacing.xs)

                        // 2. Header Judul
                        VStack(alignment: .leading, spacing: HIGSpacing.xs) {
                            HStack(spacing: HIGSpacing.xxs) {
                                Text("Create Account")
                                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                                    .foregroundColor(.black)
                                
                                ZStack {
                                    Circle()
                                        .fill(Color.cartoonYellow)
                                        .frame(width: 30, height: 30)
                                        .shadow(color: .black, radius: 0, x: 1, y: 1)
                                        .overlay(Circle().stroke(Color.black, lineWidth: 1.4))
                                    Image(systemName: "hand.wave.fill")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.black)
                                }
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
                        CartoonGoogleSignInButton(
                            title: "Sign up with Google",
                            isLoading: isGoogleLoading
                        ) {
                            handleGoogleSignUp()
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

    // MARK: - Google Sign Up Action (Async/Await)
    private func handleGoogleSignUp() {
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
                    // Dibatalkan secara sengaja oleh pengguna
                    return
                }
                print("Google Auth Error: \(error.localizedDescription)")
                HapticManager.shared.warning()
            } catch {
                print("Google Sign Up Error: \(error.localizedDescription)")
                HapticManager.shared.warning()
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

    dynamic var body: some View {
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
        .background(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .fill(Color.white)
                .shadow(color: .black, radius: 0, x: 2, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
    }
}

// MARK: - 🔐 Input Field Password Kartun
struct CartoonSecureInputField: View {
    var placeholder: String
    @Binding var text: String
    @State private var isSecured: Bool = true

    dynamic var body: some View {
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
        .background(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .fill(Color.white)
                .shadow(color: .black, radius: 0, x: 2, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
    }
}

#Preview {
    RegisterView()
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
// CartoonSecureInputField: helper methods kept here — its body reads private member(s): isSecured.
//   To move this into Patch/Generated/, make those member(s) `internal` (drop
//   `private`/`fileprivate`) and re-run `patchcli prepare`.
// RegisterView: helper methods kept here — its body reads private member(s): dismiss, email, fullName, handleGoogleSignUp, isAgreed, isGoogleLoading, isLoggedIn, isShowingLogin, password.
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

extension CartoonSecureInputField {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_727739d7aa16a3d0"] = { (a: [String]) in a.count >= 3 ? AnyView(HStack(spacing: HIGSpacing.sm) {
            Image(systemName: a[0])
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
                Image(systemName: isSecured ? a[1] : a[2])
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, HIGSpacing.md)) : AnyView(EmptyView()) }
        return __s
    }

    /// Resolved design-system token values for this view's `.hostToken(id)`/
    /// `.fontToken(id)`/numeric/string token slots. Empty when the view uses none.
    @MainActor func __patchTokens() -> [String: PatchHostToken] {
        var __t: [String: PatchHostToken] = [:]
        __t["nt_98ff9976f3b5d171"] = .number(Double(CartoonMetrics.cardCornerRadius))
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


extension RegisterView {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_1158be0876906c5e"] = { (a: [String]) in a.count >= 16 ? AnyView(VStack(alignment: .leading, spacing: HIGSpacing.xl) {
                        
                        // 1. Tombol Back Kartun (Touch Target 44x44)
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: a[0])
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: HIGSpacing.touchTargetMin, height: HIGSpacing.touchTargetMin)
                                .background(
                                    RoundedRectangle(cornerRadius: CartoonMetrics.cornerRadius)
                                        .fill(Color.white)
                                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: CartoonMetrics.cornerRadius)
                                        .stroke(Color.black, lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                        .padding(.top, HIGSpacing.xs)

                        // 2. Header Judul
                        VStack(alignment: .leading, spacing: HIGSpacing.xs) {
                            HStack(spacing: HIGSpacing.xxs) {
                                Text(LocalizedStringKey(a[1]))
                                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                                    .foregroundColor(.black)
                                
                                ZStack {
                                    Circle()
                                        .fill(Color.cartoonYellow)
                                        .frame(width: 30, height: 30)
                                        .shadow(color: .black, radius: 0, x: 1, y: 1)
                                        .overlay(Circle().stroke(Color.black, lineWidth: 1.4))
                                    Image(systemName: a[2])
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.black)
                                }
                            }

                            Text(LocalizedStringKey(a[3]))
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .lineSpacing(3)
                        }
                        .padding(.top, HIGSpacing.xxs)

                        // 3. Form Input Fields (Kartun Neo-Brutalist)
                        VStack(spacing: HIGSpacing.md) {
                            // Field Nama Lengkap
                            CartoonInputField(
                                placeholder: a[4],
                                text: $fullName,
                                icon: a[5]
                            )

                            // Field Email
                            CartoonInputField(
                                placeholder: a[6],
                                text: $email,
                                icon: a[7],
                                keyboardType: .emailAddress
                            )

                            // Field Password
                            CartoonSecureInputField(
                                placeholder: a[8],
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
                                        Image(systemName: a[9])
                                            .font(.system(size: 11, weight: .black))
                                            .foregroundColor(.white)
                                        }
                                }
                                .frame(width: 36, height: 36)
                            }
                            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                            Text(LocalizedStringKey(a[10]))
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
                            Text(LocalizedStringKey(a[11]))
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
                        .disabled(!isAgreed || fullName.isEmpty || email.isEmpty || password.isEmpty)
                        .opacity((!isAgreed || fullName.isEmpty || email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                        .padding(.top, HIGSpacing.xs)

                        // 6. Pembatas "Or"
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            
                            Text(LocalizedStringKey(a[12]))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, HIGSpacing.xs)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical, HIGSpacing.xxs)

                        // 7. Tombol Google Sign Up
                        CartoonGoogleSignInButton(
                            title: a[13],
                            isLoading: isGoogleLoading
                        ) {
                            handleGoogleSignUp()
                        }

                        Spacer(minLength: 25)

                        // 8. Footer Link ke Sign In
                        HStack(spacing: HIGSpacing.xxs) {
                            Spacer()
                            Text(LocalizedStringKey(a[14]))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.black)
                            
                            Button {
                                isShowingLogin = true
                            } label: {
                                Text(LocalizedStringKey(a[15]))
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
        __s["op_cfd6f8bc66122a0"] = { (_: [String]) in AnyView(LoginView()) }
        return __s
    }

    /// Resolved design-system token values for this view's `.hostToken(id)`/
    /// `.fontToken(id)`/numeric/string token slots. Empty when the view uses none.
    @MainActor func __patchTokens() -> [String: PatchHostToken] {
        [:]
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
