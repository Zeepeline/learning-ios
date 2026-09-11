//
//  EditProfileView.swift
//  learning
//
//  Created by macbook on 9/6/26.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("userName") private var storedName: String = "Bruce Wayne"
    @AppStorage("userEmail") private var storedEmail: String = "brucewayne27@suarasa.com"
    @AppStorage("userBio") private var storedBio: String = "Productivity Master"
    @AppStorage("userAvatarIcon") private var storedAvatarIcon: String = "person.crop.circle.fill"
    @AppStorage("userAvatarColor") private var storedAvatarColor: String = "#FFD166"
    @AppStorage("userAvatarUrl") private var storedAvatarUrl: String = ""

    @State private var nameText: String = ""
    @State private var emailText: String = ""
    @State private var bioText: String = ""
    @State private var selectedAvatarIcon: String = "person.crop.circle.fill"
    @State private var selectedColorHex: String = "#FFD166"

    private let avatarIcons: [String] = [
        "person.crop.circle.fill",
        "star.circle.fill",
        "bolt.circle.fill",
        "heart.circle.fill",
        "sparkles",
        "crown.fill",
        "flame.fill",
        "brain.head.profile"
    ]

    private let avatarColors: [(name: String, hex: String, color: Color)] = [
        ("Kuning", "#FFD166", .cartoonYellow),
        ("Pink", "#FF99C8", .cartoonPink),
        ("Mint", "#6EE7B7", .cartoonMint),
        ("Biru", "#A0C4FF", .cartoonBlue),
        ("Lavender", "#DDA0DD", .cartoonLavender),
        ("Oranye", "#FFAA00", .cartoonOrange)
    ]

    dynamic var body: some View {
        NavigationStack {
            ZStack {
                Color.cartoonBg
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: HIGSpacing.lg) {
                        // MARK: - 🎨 Avatar Preview & Selector
                        avatarPreviewSection

                        // MARK: - 📝 Form Input Fields
                        VStack(spacing: HIGSpacing.md) {
                            // Field Nama Lengkap
                            cartoonInputField(
                                title: "NAMA LENGKAP",
                                icon: "person.fill",
                                placeholder: "Masukkan nama kamu",
                                text: $nameText
                            )

                            // Field Bio / Tagline
                            cartoonInputField(
                                title: "BIO / STATUS",
                                icon: "quote.bubble.fill",
                                placeholder: "Contoh: Productivity Master",
                                text: $bioText
                            )

                            // Field Email
                            cartoonInputField(
                                title: "EMAIL",
                                icon: "envelope.fill",
                                placeholder: "nama@domain.com",
                                text: $emailText,
                                keyboardType: .emailAddress
                            )
                        }
                        .padding(.horizontal, HIGSpacing.md)

                        // MARK: - 💾 Tombol Simpan
                        Button {
                            saveProfile()
                        } label: {
                            HStack(spacing: HIGSpacing.xs) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 15, weight: .black))
                                Text("Simpan Profil")
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.cartoonMint)
                            .cornerRadius(CartoonMetrics.cardCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                            .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
                        .padding(.horizontal, HIGSpacing.md)
                        .padding(.top, HIGSpacing.xs)
                        .padding(.bottom, HIGSpacing.xl)
                    }
                    .padding(.top, HIGSpacing.md)
                }
            }
            .navigationTitle("Edit Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticManager.shared.impact(style: .light)
                        dismiss()
                    } label: {
                        Text("Batal")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(.cartoonTextPrimary)
                    }
                }
            }
            .onAppear {
                nameText = storedName
                emailText = storedEmail
                bioText = storedBio
                selectedAvatarIcon = storedAvatarIcon
                selectedColorHex = storedAvatarColor
            }
        }
    }

    // MARK: - 🎨 Avatar Preview & Selector Section
    private var avatarPreviewSection: some View {
        VStack(spacing: HIGSpacing.md) {
            // Avatar Big Preview
            ZStack {
                Circle()
                    .fill(Color(hex: selectedColorHex))
                    .frame(width: 96, height: 96)
                    .overlay(
                        Circle().stroke(Color.black, lineWidth: CartoonMetrics.thickBorderWidth)
                    )
                    .shadow(color: .black, radius: 0, x: 3, y: 3)

                Image(systemName: selectedAvatarIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
                    .foregroundColor(.black)
            }

            // Pilihan Warna Avatar
            VStack(alignment: .leading, spacing: HIGSpacing.xs) {
                Text("WARNA BACKGROUND AVATAR")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)

                HStack(spacing: HIGSpacing.sm) {
                    ForEach(avatarColors, id: \.hex) { item in
                        Button {
                            HapticManager.shared.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedColorHex = item.hex
                            }
                        } label: {
                            Circle()
                                .fill(item.color)
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Circle().stroke(Color.black, lineWidth: selectedColorHex == item.hex ? 2.5 : 1.5)
                                )
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .black))
                                        .foregroundColor(.black)
                                        .opacity(selectedColorHex == item.hex ? 1 : 0)
                                )
                                .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    }
                }
            }
            .padding(.horizontal, HIGSpacing.md)

            // Pilihan Ikon Avatar
            VStack(alignment: .leading, spacing: HIGSpacing.xs) {
                Text("IKON AVATAR")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: HIGSpacing.xs) {
                        ForEach(avatarIcons, id: \.self) { icon in
                            Button {
                                HapticManager.shared.selection()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedAvatarIcon = icon
                                }
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(width: 44, height: 44)
                                    .background(selectedAvatarIcon == icon ? Color.cartoonYellow : Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.black, lineWidth: selectedAvatarIcon == icon ? 2.2 : 1.5)
                                    )
                                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                            }
                            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                        }
                    }
                    .padding(.horizontal, HIGSpacing.md)
                }
            }
        }
    }

    // MARK: - 🛠️ Reusable Cartoon Input Field
    private func cartoonInputField(
        title: String,
        icon: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 24)

                TextField(placeholder, text: text)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Color.white)
            .cornerRadius(CartoonMetrics.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
            )
            .shadow(color: .black, radius: 0, x: 2, y: 2)
        }
    }

    // MARK: - 💾 Save Action
    private func saveProfile() {
        let trimmedName = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = emailText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBio = bioText.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedName.isEmpty {
            storedName = trimmedName
        }
        if !trimmedEmail.isEmpty {
            storedEmail = trimmedEmail
        }
        storedBio = trimmedBio.isEmpty ? "Productivity Master" : trimmedBio
        storedAvatarIcon = selectedAvatarIcon
        storedAvatarColor = selectedColorHex
        // Reset Google photo avatar to show custom picked avatar
        storedAvatarUrl = ""

        HapticManager.shared.success()
        dismiss()
    }
}

#Preview {
    EditProfileView()
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
// EditProfileView: helper methods kept here — its body reads private member(s): avatarPreviewSection, bioText, cartoonInputField, dismiss, emailText, nameText, saveProfile, selectedAvatarIcon, selectedColorHex, storedAvatarColor, storedAvatarIcon, storedBio, storedEmail, storedName.
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

extension EditProfileView {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_ce7e21e0e6717c40"] = { (a: [String]) in a.count >= 11 ? AnyView(VStack(spacing: HIGSpacing.lg) {
                        // MARK: - 🎨 Avatar Preview & Selector
                        avatarPreviewSection

                        // MARK: - 📝 Form Input Fields
                        VStack(spacing: HIGSpacing.md) {
                            // Field Nama Lengkap
                            cartoonInputField(
                                title: a[0],
                                icon: a[1],
                                placeholder: a[2],
                                text: $nameText
                            )

                            // Field Bio / Tagline
                            cartoonInputField(
                                title: a[3],
                                icon: a[4],
                                placeholder: a[5],
                                text: $bioText
                            )

                            // Field Email
                            cartoonInputField(
                                title: a[6],
                                icon: a[7],
                                placeholder: a[8],
                                text: $emailText,
                                keyboardType: .emailAddress
                            )
                        }
                        .padding(.horizontal, HIGSpacing.md)

                        // MARK: - 💾 Tombol Simpan
                        Button {
                            saveProfile()
                        } label: {
                            HStack(spacing: HIGSpacing.xs) {
                                Image(systemName: a[9])
                                    .font(.system(size: 15, weight: .black))
                                Text(LocalizedStringKey(a[10]))
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.cartoonMint)
                            .cornerRadius(CartoonMetrics.cardCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                            .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
                        .padding(.horizontal, HIGSpacing.md)
                        .padding(.top, HIGSpacing.xs)
                        .padding(.bottom, HIGSpacing.xl)
                    }
                    .padding(.top, HIGSpacing.md)) : AnyView(EmptyView()) }
        return __s
    }

    /// Resolved design-system token values for this view's `.hostToken(id)`/
    /// `.fontToken(id)`/numeric/string token slots. Empty when the view uses none.
    @MainActor func __patchTokens() -> [String: PatchHostToken] {
        var __t: [String: PatchHostToken] = [:]
        __t["ct_896c50b68f3107a3"] = .color(Color.cartoonBg)
        __t["ct_d7ce1e71dfa37088"] = .color(.cartoonTextPrimary)
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
        var __a: [String: () -> Void] = [:]
        __a["act8cce2580e0df1d73"] = { HapticManager.shared.impact(style: .light)
                        dismiss() }
        return __a
    }

    /// Native effect-modifier slots for this view's `.nativeEffectSlot` modifiers — an
    /// undispatchable `.task`/`.onAppear`/`.refreshable`/`.onSubmit`/gesture whose closure
    /// runs a native side-effect. Each closure (`(AnyView) -> AnyView`, over `self`) applies
    /// the real modifier to its content; the SDK applies it to the rendered subtree by id.
    /// Empty when the view has none.
    @MainActor func __patchEffectSlots() -> [String: (AnyView) -> AnyView] {
        var __e: [String: (AnyView) -> AnyView] = [:]
        __e["effef90bb526fbd45cb"] = { (content: AnyView) -> AnyView in AnyView(content.onAppear {
                nameText = storedName
                emailText = storedEmail
                bioText = storedBio
                selectedAvatarIcon = storedAvatarIcon
                selectedColorHex = storedAvatarColor
            }) }
        return __e
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
