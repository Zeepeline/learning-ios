//
//  CartoonHomeDashboard.swift
//  learning
//
//  Created by macbook on 9/1/26.
//

import SwiftUI

// MARK: - 🌟 1. Banner Progress & Sapaan Kartun (HIG Glanceability)
struct CartoonProgressBanner: View {
    let userName: String
    let completedCount: Int
    let totalCount: Int

    private var progressRatio: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    private var progressPercentage: Int {
        Int(progressRatio * 100)
    }

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            // Header Sapaan & Badge Streak
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Halo, \(userName)")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)

                    Text(motivationalSubtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Badge Streak Kartun
                HStack(spacing: 4) {
                    Text("3 Hari")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.cartoonYellow)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 1.6)
                )
                .shadow(color: .black, radius: 0, x: 2, y: 2)
            }

            // Progress Bar Kartun Neo-Brutalist
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Progres Tugas")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.black)

                    Spacer()

                    Text("\(completedCount)/\(totalCount) Selesai (\(progressPercentage)%)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.cartoonCoral)
                }

                // Bar Fisik
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(red: 0.93, green: 0.93, blue: 0.95))
                            .frame(height: 14)
                            .overlay(Capsule().stroke(Color.black, lineWidth: 1.6))

                        Capsule()
                            .fill(Color.cartoonMint)
                            .frame(width: max(geo.size.width * CGFloat(progressRatio), (progressRatio > 0 ? 14 : 0)), height: 14)
                            .overlay(Capsule().stroke(Color.black, lineWidth: 1.6))
                            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: progressRatio)
                    }
                }
                .frame(height: 14)
            }
            .padding(.top, HIGSpacing.xxs)
        }
        .padding(HIGSpacing.md)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
    }

    private var motivationalSubtitle: String {
        if totalCount == 0 {
            return "Mulai hari ini dengan membuat tugas baru!"
        } else if completedCount == totalCount {
            return "Luar biasa! Semua tugas selesai!"
        } else {
            return "Yuk selesaikan \(totalCount - completedCount) tugas lagi hari ini!"
        }
    }
}

// MARK: - 📊 2. Kartu Mini Statistik Ringkasan (3 Kolom Horisontal)
struct CartoonStatCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 26, height: 26)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.4))

                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.black)
                }

                Spacer()

                Text("\(count)")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
            }

            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black, lineWidth: 1.6)
        )
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }
}

// MARK: - 🔍 3. Search Bar Kartun Neo-Brutalist (HIG Search Standards)
struct CartoonSearchBar: View {
    @Binding var searchText: String

    dynamic var body: some View {
        HStack(spacing: HIGSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.black)

            TextField("Cari tugas atau catatan...", text: $searchText)
                .font(.system(size: 13, weight: .medium, design: .rounded))

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    HapticManager.shared.impact(style: .light)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, HIGSpacing.md)
        .frame(height: 44)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black, lineWidth: 1.6)
        )
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }
}

// MARK: - 🏷️ 4. Horizontal Filter Segment Chips (HIG Filtering)
struct CartoonFilterStrip: View {
    @Binding var selectedFilter: String
    let filters: [(id: String, label: String, icon: String)]

    dynamic var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: HIGSpacing.xs) {
                ForEach(filters, id: \.id) { filter in
                    let isSelected = selectedFilter == filter.id

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedFilter = filter.id
                            HapticManager.shared.selection()
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: filter.icon)
                                .font(.system(size: 10, weight: .bold))

                            Text(filter.label)
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.cartoonCoral : Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: isSelected ? 2.0 : 1.4)
                        )
                        .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                        .scaleEffect(isSelected ? 1.03 : 1.0)
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
    }
}

// MARK: - ✨ 5. Template Cepat untuk Zero-State (HIG Onboarding)
struct CartoonQuickTemplateCard: View {
    let title: String
    let category: String
    let icon: String
    let color: Color
    let onAdd: () -> Void

    dynamic var body: some View {
        Button {
            onAdd()
        } label: {
            HStack(spacing: HIGSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.6))

                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(.black)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)

                    Text(category)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(Color.cartoonCoral)
            }
            .padding(HIGSpacing.sm)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: 1.5)
            )
            .shadow(color: .black, radius: 0, x: 2, y: 2)
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
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
// CartoonProgressBanner: helper methods kept here — its body reads private member(s): motivationalSubtitle, progressPercentage, progressRatio.
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

extension CartoonProgressBanner {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_ee6a6306344907d6"] = { (a: [String]) in a.count >= 1 ? AnyView(VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(LocalizedStringKey(a[0]))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.black)

                    Spacer()

                    Text("\(completedCount)/\(totalCount) Selesai (\(progressPercentage)%)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.cartoonCoral)
                }

                // Bar Fisik
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(red: 0.93, green: 0.93, blue: 0.95))
                            .frame(height: 14)
                            .overlay(Capsule().stroke(Color.black, lineWidth: 1.6))

                        Capsule()
                            .fill(Color.cartoonMint)
                            .frame(width: max(geo.size.width * CGFloat(progressRatio), (progressRatio > 0 ? 14 : 0)), height: 14)
                            .overlay(Capsule().stroke(Color.black, lineWidth: 1.6))
                            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: progressRatio)
                    }
                }
                .frame(height: 14)
            }
            .padding(.top, HIGSpacing.xxs)) : AnyView(EmptyView()) }
        return __s
    }

    /// Resolved design-system token values for this view's `.hostToken(id)`/
    /// `.fontToken(id)`/numeric/string token slots. Empty when the view uses none.
    @MainActor func __patchTokens() -> [String: PatchHostToken] {
        var __t: [String: PatchHostToken] = [:]
        __t["nt_7be55366dcb65dae"] = .number(Double(HIGSpacing.sm))
        __t["st_1c03dd990dd3e894"] = .string(motivationalSubtitle)
        __t["ct_fe8e837f4bbdb528"] = .color(Color.cartoonYellow)
        __t["nt_7bfa3866dcc88bd7"] = .number(Double(HIGSpacing.md))
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

#endif
// @generated — END OF AUTOGENERATED SECTION. DO NOT EDIT ABOVE (regenerated by `patchcli prepare`).
// PATCH-THUNKS-END
