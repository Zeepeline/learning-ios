//
//  ProfileSettingsSection.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI

struct ProfileSettingsSection: View {
    @Binding var useBiometrics: Bool
    @Binding var isNotificationEnabled: Bool
    @Binding var isMorningReminderEnabled: Bool
    @Binding var isEveningReminderEnabled: Bool
    @Binding var isHapticEnabled: Bool
    @AppStorage("isICloudSyncEnabled") private var isICloudSyncEnabled: Bool = true
    var healthManager = HealthKitManager.shared
    var soundManager = SoundManager.shared

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            Text("Pengaturan & Preferensi")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, HIGSpacing.md)

            VStack(spacing: HIGSpacing.md) {
                // MARK: - GRUP 1: Keamanan & Data
                settingsGroup(title: "KEAMANAN & DATA") {
                    VStack(spacing: HIGSpacing.xs) {
                        // 1. ☁️ Toggle Sinkronisasi iCloud
                        CartoonToggleRow(
                            icon: "icloud.fill",
                            iconColor: .black,
                            iconBgColor: Color.cartoonBlue,
                            title: "Sinkronisasi iCloud",
                            subtitle: "Cadangkan tugas & kebiasaan otomatis",
                            isOn: $isICloudSyncEnabled,
                            activeColor: Color.cartoonBlue
                        )

                        // 2. 🔐 Toggle Face ID / Biometrik
                        if BiometricAuthManager.shared.canEvaluateBiometrics() {
                            CartoonToggleRow(
                                icon: "faceid",
                                iconColor: .black,
                                iconBgColor: Color.cartoonLavender,
                                title: "Kunci \(BiometricAuthManager.shared.biometricType())",
                                subtitle: "Autentikasi keamanan saat membuka aplikasi",
                                isOn: $useBiometrics,
                                activeColor: Color.cartoonMint
                            )
                        }

                        // 3. 🏃 Integrasi Apple Health & Smartwatch
                        healthKitIntegrationRow
                    }
                }

                // MARK: - GRUP 2: Pengingat & Notifikasi
                settingsGroup(title: "PENGINGAT & NOTIFIKASI") {
                    VStack(spacing: HIGSpacing.xs) {
                        // 1. 🔔 Toggle Master Notifikasi Tugas
                        CartoonToggleRow(
                            icon: "bell.badge.fill",
                            iconColor: .black,
                            iconBgColor: Color.cartoonYellow,
                            title: "Pengingat Jadwal Tugas",
                            subtitle: "Notifikasi otomatis sebelum tenggat waktu",
                            isOn: $isNotificationEnabled,
                            activeColor: Color.cartoonCoral
                        )

                        if isNotificationEnabled {
                            // 2. ☀️ Pengingat Pagi
                            CartoonToggleRow(
                                icon: "sun.max.fill",
                                iconColor: .black,
                                iconBgColor: Color.cartoonYellow,
                                title: "Pengingat Pagi (08:00)",
                                subtitle: "Rencana & agenda tugas hari ini",
                                isOn: $isMorningReminderEnabled,
                                activeColor: Color.cartoonYellow
                            )
                            .onChange(of: isMorningReminderEnabled) { _, isEnabled in
                                handleMorningReminder(isEnabled)
                            }

                            // 3. 🌙 Pengingat Malam
                            CartoonToggleRow(
                                icon: "moon.stars.fill",
                                iconColor: .black,
                                iconBgColor: Color.cartoonLavender,
                                title: "Evaluasi Malam (20:00)",
                                subtitle: "Review capaian & ringkasan harian",
                                isOn: $isEveningReminderEnabled,
                                activeColor: Color.cartoonLavender
                            )
                            .onChange(of: isEveningReminderEnabled) { _, isEnabled in
                                handleEveningReminder(isEnabled)
                            }
                        }
                    }
                }

                // MARK: - GRUP 3: Audio & Umpan Balik
                settingsGroup(title: "FEEDBACK & SUARA") {
                    VStack(spacing: HIGSpacing.xs) {
                        // 1. 🔊 Toggle Efek Suara (Sound FX)
                        CartoonToggleRow(
                            icon: "speaker.wave.2.fill",
                            iconColor: .black,
                            iconBgColor: Color.cartoonOrange,
                            title: "Efek Suara (Sound FX)",
                            subtitle: "Suara pop ceria saat menyelesaikan tugas & timer",
                            isOn: Binding(
                                get: { soundManager.isSoundFXEnabled },
                                set: { soundManager.isSoundFXEnabled = $0 }
                            ),
                            activeColor: Color.cartoonOrange
                        )

                        // 2. 📳 Toggle Getaran Haptik
                        CartoonToggleRow(
                            icon: "hand.tap.fill",
                            iconColor: .black,
                            iconBgColor: Color.cartoonPink,
                            title: "Sensasi Getaran Haptik",
                            subtitle: "Umpan balik sentuhan responsif di setiap tombol",
                            isOn: $isHapticEnabled,
                            activeColor: Color.cartoonMint
                        )
                    }
                }
            }
            .padding(.horizontal, HIGSpacing.md)
        }
    }

    // MARK: - Helper Group Container dengan Header Kategori
    private func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            content()
        }
    }

    // MARK: - Baris Integrasi Apple Health & Zepp
    private var healthKitIntegrationRow: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.cartoonPink)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                    .frame(width: 44, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.6))

                Image(systemName: "heart.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Apple Health & Smartwatch")
                    .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Text(healthManager.isAuthorized ? "Terhubung (Auto-sync Zepp & Watch)" : "Sinkronkan lari, langkah & tidur")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(healthManager.isAuthorized ? Color(red: 0.1, green: 0.6, blue: 0.3) : .secondary)
            }

            Spacer()

            if healthManager.isAuthorized {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                    Text("Aktif")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.cartoonMint.opacity(0.4))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
            } else {
                Button {
                    HapticManager.shared.impact(style: .medium)
                    Task {
                        let success = await healthManager.requestAuthorization()
                        if success {
                            HapticManager.shared.success()
                        }
                    }
                } label: {
                    Text("Hubungkan")
                        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.cartoonYellow)
                                .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
        }
        .padding(HIGSpacing.md)
        .cartoonCard()
    }

    private func handleMorningReminder(_ isEnabled: Bool) {
        HapticManager.shared.selection()
        if isEnabled {
            Task {
                await NotificationManager.shared.scheduleDailyReminder(
                    hour: 8,
                    minute: 0,
                    title: "Semangat Pagi! Saatnya Mulai Hari",
                    body: "Buka aplikasi untuk melihat daftar tugas yang perlu diselesaikan hari ini!",
                    identifier: NotificationManager.morningReminderId
                )
            }
        } else {
            NotificationManager.shared.cancelReminder(identifier: NotificationManager.morningReminderId)
        }
    }

    private func handleEveningReminder(_ isEnabled: Bool) {
        HapticManager.shared.selection()
        if isEnabled {
            Task {
                await NotificationManager.shared.scheduleDailyReminder(
                    hour: 20,
                    minute: 0,
                    title: "Evaluasi Malam",
                    body: "Hebat! Cek berapa banyak tugas yang telah berhasil kamu selesaikan hari ini.",
                    identifier: NotificationManager.eveningReminderId
                )
            }
        } else {
            NotificationManager.shared.cancelReminder(identifier: NotificationManager.eveningReminderId)
        }
    }
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
// ProfileSettingsSection: helper methods kept here — its body reads private member(s): handleEveningReminder, handleMorningReminder, healthKitIntegrationRow, isICloudSyncEnabled, settingsGroup.
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

extension ProfileSettingsSection {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_15364991947a1edd"] = { (a: [String]) in a.count >= 1 ? AnyView(Text(LocalizedStringKey(a[0]))
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, HIGSpacing.md)) : AnyView(EmptyView()) }
        __s["op_cb828923c446f33e"] = { (a: [String]) in a.count >= 23 ? AnyView(VStack(spacing: HIGSpacing.md) {
                // MARK: - GRUP 1: Keamanan & Data
                settingsGroup(title: a[5]) {
                    VStack(spacing: HIGSpacing.xs) {
                        // 1. ☁️ Toggle Sinkronisasi iCloud
                        CartoonToggleRow(
                            icon: a[0],
                            iconColor: .black,
                            iconBgColor: Color.cartoonBlue,
                            title: a[1],
                            subtitle: a[2],
                            isOn: $isICloudSyncEnabled,
                            activeColor: Color.cartoonBlue
                        )

                        // 2. 🔐 Toggle Face ID / Biometrik
                        if BiometricAuthManager.shared.canEvaluateBiometrics() {
                            CartoonToggleRow(
                                icon: a[3],
                                iconColor: .black,
                                iconBgColor: Color.cartoonLavender,
                                title: "Kunci \(BiometricAuthManager.shared.biometricType())",
                                subtitle: a[4],
                                isOn: $useBiometrics,
                                activeColor: Color.cartoonMint
                            )
                        }

                        // 3. 🏃 Integrasi Apple Health & Smartwatch
                        healthKitIntegrationRow
                    }
                }

                // MARK: - GRUP 2: Pengingat & Notifikasi
                settingsGroup(title: a[15]) {
                    VStack(spacing: HIGSpacing.xs) {
                        // 1. 🔔 Toggle Master Notifikasi Tugas
                        CartoonToggleRow(
                            icon: a[6],
                            iconColor: .black,
                            iconBgColor: Color.cartoonYellow,
                            title: a[7],
                            subtitle: a[8],
                            isOn: $isNotificationEnabled,
                            activeColor: Color.cartoonCoral
                        )

                        if isNotificationEnabled {
                            // 2. ☀️ Pengingat Pagi
                            CartoonToggleRow(
                                icon: a[9],
                                iconColor: .black,
                                iconBgColor: Color.cartoonYellow,
                                title: a[10],
                                subtitle: a[11],
                                isOn: $isMorningReminderEnabled,
                                activeColor: Color.cartoonYellow
                            )
                            .onChange(of: isMorningReminderEnabled) { _, isEnabled in
                                handleMorningReminder(isEnabled)
                            }

                            // 3. 🌙 Pengingat Malam
                            CartoonToggleRow(
                                icon: a[12],
                                iconColor: .black,
                                iconBgColor: Color.cartoonLavender,
                                title: a[13],
                                subtitle: a[14],
                                isOn: $isEveningReminderEnabled,
                                activeColor: Color.cartoonLavender
                            )
                            .onChange(of: isEveningReminderEnabled) { _, isEnabled in
                                handleEveningReminder(isEnabled)
                            }
                        }
                    }
                }

                // MARK: - GRUP 3: Audio & Umpan Balik
                settingsGroup(title: a[22]) {
                    VStack(spacing: HIGSpacing.xs) {
                        // 1. 🔊 Toggle Efek Suara (Sound FX)
                        CartoonToggleRow(
                            icon: a[16],
                            iconColor: .black,
                            iconBgColor: Color.cartoonOrange,
                            title: a[17],
                            subtitle: a[18],
                            isOn: Binding(
                                get: { soundManager.isSoundFXEnabled },
                                set: { soundManager.isSoundFXEnabled = $0 }
                            ),
                            activeColor: Color.cartoonOrange
                        )

                        // 2. 📳 Toggle Getaran Haptik
                        CartoonToggleRow(
                            icon: a[19],
                            iconColor: .black,
                            iconBgColor: Color.cartoonPink,
                            title: a[20],
                            subtitle: a[21],
                            isOn: $isHapticEnabled,
                            activeColor: Color.cartoonMint
                        )
                    }
                }
            }
            .padding(.horizontal, HIGSpacing.md)) : AnyView(EmptyView()) }
        return __s
    }

    /// Resolved design-system token values for this view's `.hostToken(id)`/
    /// `.fontToken(id)`/numeric/string token slots. Empty when the view uses none.
    @MainActor func __patchTokens() -> [String: PatchHostToken] {
        var __t: [String: PatchHostToken] = [:]
        __t["nt_7be55366dcb65dae"] = .number(Double(HIGSpacing.sm))
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
