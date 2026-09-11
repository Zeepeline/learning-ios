//
//  CartoonHealthCard.swift
//  learning
//
//  Created by macbook on 9/6/26.
//

import SwiftUI
import HealthKit

// MARK: - 🏃 Kartu Ringkasan Kebugaran & Olahraga Kartun Neo-Brutalist
struct CartoonHealthCard: View {
    var healthManager = HealthKitManager.shared
    @State private var isShowingAuthAlert: Bool = false
    
    dynamic var body: some View {
        VStack(spacing: HIGSpacing.sm) {
            if !healthManager.isAuthorized {
                // Banner Ajakan Koneksi Apple Health & Smartwatch
                healthAuthBanner
            } else {
                // 1. Kartu Statistik Kebugaran Terintegrasi (Langkah, Kalori, Olahraga, Tidur)
                healthMetricsCard
                
                // 2. Banner Workout Terakhir (misal: Sesi Lari dari Zepp) jika ada
                if let lastWorkout = healthManager.todaySummary.recentWorkouts.first {
                    workoutRecordCard(workout: lastWorkout)
                }
            }
        }
        .task {
            if healthManager.isAuthorized {
                await healthManager.fetchAllTodayHealthData()
            }
        }
    }
    
    // MARK: - 1. Kartu Metrik Kebugaran Hari Ini
    private var healthMetricsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Judul & Tombol Sync Cepat
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(Color.cartoonCoral)
                    
                    Text("KEBUGARAN & AKTIVITAS")
                        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Button {
                    HapticManager.shared.selection()
                    Task {
                        await healthManager.fetchAllTodayHealthData()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10, weight: .bold))
                            .rotationEffect(.degrees(healthManager.isLoading ? 360 : 0))
                            .animation(healthManager.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: healthManager.isLoading)
                        
                        Text("Sync")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.cartoonMint)
                            .shadow(color: .black, radius: 0, x: 1, y: 1)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
            
            // Grid 4 Metrik Utama: Langkah, Kalori, Olahraga, Tidur
            HStack(spacing: 8) {
                // A. Langkah Kaki (Steps)
                healthStatPill(
                    icon: "figure.walk",
                    iconColor: Color.cartoonYellow,
                    value: "\(healthManager.todaySummary.steps)",
                    unit: "langkah",
                    progress: healthManager.todaySummary.stepsProgress,
                    progressColor: Color.cartoonYellow
                )
                
                // B. Kalori Terbakar (kCal)
                healthStatPill(
                    icon: "flame.fill",
                    iconColor: Color.cartoonOrange,
                    value: "\(Int(healthManager.todaySummary.activeCalories))",
                    unit: "kkal aktif",
                    progress: healthManager.todaySummary.caloriesProgress,
                    progressColor: Color.cartoonOrange
                )
                
                // C. Waktu Olahraga (Exercise)
                healthStatPill(
                    icon: "bolt.fill",
                    iconColor: Color.cartoonMint,
                    value: "\(Int(healthManager.todaySummary.exerciseMinutes))",
                    unit: "menit",
                    progress: healthManager.todaySummary.exerciseProgress,
                    progressColor: Color.cartoonMint
                )
                
                // D. Waktu Tidur Semalam (Sleep)
                healthStatPill(
                    icon: "moon.stars.fill",
                    iconColor: Color.cartoonLavender,
                    value: healthManager.todaySummary.sleepFormatted,
                    unit: "tidur",
                    progress: min(1.0, healthManager.todaySummary.sleepDurationHours / 8.0),
                    progressColor: Color.cartoonLavender
                )
            }
        }
        .padding(HIGSpacing.md)
        .cartoonCard()
    }
    
    // Helper Stat Pill Individual
    private func healthStatPill(
        icon: String,
        iconColor: Color,
        value: String,
        unit: String,
        progress: Double,
        progressColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(iconColor)
                    .frame(width: 24, height: 24)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
                
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(unit)
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Progress Bar Mini
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 3.5)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(progressColor)
                        .frame(width: geo.size.width * CGFloat(progress), height: 3.5)
                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.black, lineWidth: 0.5))
                }
            }
            .frame(height: 3.5)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
        )
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.1))
    }
    
    // MARK: - 2. Kartu Sesi Olahraga Terakhir (Misal: Lari dari Zepp)
    private func workoutRecordCard(workout: HealthWorkoutItem) -> some View {
        HStack(spacing: 12) {
            // Icon Olahraga Kartun
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.cartoonCoral)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                    .frame(width: 44, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.6))
                
                Image(systemName: workout.icon)
                    .font(.system(size: 19, weight: .black))
                    .foregroundColor(.white)
            }
            
            // Info Olahraga
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(workout.title)
                        .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                    
                    // Badge Sumber (misal: "Zepp")
                    Text(workout.sourceName)
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Color.cartoonYellow)
                        .cornerRadius(4)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black, lineWidth: 0.8))
                    
                    Spacer()
                    
                    Text(workout.timeFormatted)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                // Ringkasan Jarak, Durasi, dan Kalori
                HStack(spacing: 10) {
                    if workout.distanceKm > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text(String(format: "%.2f km", workout.distanceKm))
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                        }
                    }
                    
                    HStack(spacing: 3) {
                        Image(systemName: "stopwatch.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text(workout.durationFormatted)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                    }
                    
                    if workout.calories > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text("\(Int(workout.calories)) kkal")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                        }
                    }
                }
                .foregroundColor(.black.opacity(0.8))
            }
        }
        .padding(HIGSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .fill(Color(red: 0.99, green: 0.94, blue: 0.88))
                .shadow(color: .black, radius: 0, x: 2, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
    }
    
    // MARK: - 3. Banner Ajakan Menghubungkan HealthKit
    private var healthAuthBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.cartoonPink)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                    .frame(width: 44, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.6))
                
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Sinkronkan Apple Health & Zepp")
                    .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                
                Text("Baca otomatis sesi lari, langkah kaki, dan durasi tidur.")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
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
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.cartoonMint)
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.4))
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
        }
        .padding(HIGSpacing.md)
        .cartoonCard()
    }
}

#Preview {
    CartoonHealthCard()
        .padding()
        .background(Color.cartoonBg)
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
// CartoonHealthCard: helper methods kept here — its body reads private member(s): healthStatPill, workoutRecordCard.
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

extension CartoonHealthCard {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_cb7665fb0595bac0"] = { (a: [String]) in a.count >= 4 ? AnyView(HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.cartoonPink)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                    .frame(width: 44, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.6))
                
                Image(systemName: a[0])
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(a[1]))
                    .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                
                Text(LocalizedStringKey(a[2]))
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button {
                HapticManager.shared.impact(style: .medium)
                Task {
                    let success = await healthManager.requestAuthorization()
                    if success {
                        HapticManager.shared.success()
                    }
                }
            } label: {
                Text(LocalizedStringKey(a[3]))
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.cartoonMint)
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.4))
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
        }
        .padding(HIGSpacing.md)
        .cartoonCard()) : AnyView(EmptyView()) }
        __s["op_6d239f165fb1bced"] = { (a: [String]) in a.count >= 8 ? AnyView(VStack(alignment: .leading, spacing: 10) {
            // Header: Judul & Tombol Sync Cepat
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: a[0])
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(Color.cartoonCoral)
                    
                    Text(LocalizedStringKey(a[1]))
                        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Button {
                    HapticManager.shared.selection()
                    Task {
                        await healthManager.fetchAllTodayHealthData()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: a[2])
                            .font(.system(size: 10, weight: .bold))
                            .rotationEffect(.degrees(healthManager.isLoading ? 360 : 0))
                            .animation(healthManager.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: healthManager.isLoading)
                        
                        Text(LocalizedStringKey(a[3]))
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.cartoonMint)
                            .shadow(color: .black, radius: 0, x: 1, y: 1)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
            
            // Grid 4 Metrik Utama: Langkah, Kalori, Olahraga, Tidur
            HStack(spacing: 8) {
                // A. Langkah Kaki (Steps)
                healthStatPill(
                    icon: a[4],
                    iconColor: Color.cartoonYellow,
                    value: "\(healthManager.todaySummary.steps)",
                    unit: "langkah",
                    progress: healthManager.todaySummary.stepsProgress,
                    progressColor: Color.cartoonYellow
                )
                
                // B. Kalori Terbakar (kCal)
                healthStatPill(
                    icon: a[5],
                    iconColor: Color.cartoonOrange,
                    value: "\(Int(healthManager.todaySummary.activeCalories))",
                    unit: "kkal aktif",
                    progress: healthManager.todaySummary.caloriesProgress,
                    progressColor: Color.cartoonOrange
                )
                
                // C. Waktu Olahraga (Exercise)
                healthStatPill(
                    icon: a[6],
                    iconColor: Color.cartoonMint,
                    value: "\(Int(healthManager.todaySummary.exerciseMinutes))",
                    unit: "menit",
                    progress: healthManager.todaySummary.exerciseProgress,
                    progressColor: Color.cartoonMint
                )
                
                // D. Waktu Tidur Semalam (Sleep)
                healthStatPill(
                    icon: a[7],
                    iconColor: Color.cartoonLavender,
                    value: healthManager.todaySummary.sleepFormatted,
                    unit: "tidur",
                    progress: min(1.0, healthManager.todaySummary.sleepDurationHours / 8.0),
                    progressColor: Color.cartoonLavender
                )
            }
        }
        .padding(HIGSpacing.md)
        .cartoonCard()) : AnyView(EmptyView()) }
        __s["op_c594699d4592ecac"] = { (_: [String]) in AnyView(Group {
if let lastWorkout = healthManager.todaySummary.recentWorkouts.first {
                    workoutRecordCard(workout: lastWorkout)
                }
}) }
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
        var __e: [String: (AnyView) -> AnyView] = [:]
        __e["eff1a46b5c2632b4718"] = { (content: AnyView) -> AnyView in AnyView(content.task {
            if healthManager.isAuthorized {
                await healthManager.fetchAllTodayHealthData()
            }
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
