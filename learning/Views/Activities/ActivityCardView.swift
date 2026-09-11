//
//  ActivityCardView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI

struct ActivityCardView: View {
    let item: Item
    var onToggle: () -> Void
    var onDelete: () -> Void
    var onTap: (() -> Void)?

    dynamic var body: some View {
        HStack(spacing: HIGSpacing.sm) {
            // 1. 🔘 Tombol Checkbox Kartun Pop Neo-Brutalist
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) {
                    onToggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(item.isCompleted ? Color.cartoonMint : Color.white)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: 2.0)
                        )
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                    
                    if item.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.black)
                    }
                }
                .frame(width: HIGSpacing.touchTargetMin, height: HIGSpacing.touchTargetMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))

            // 2. 📝 Detail Konten Aktivitas (Teks Hitam Tajam & Tegas Bergaya Kartun)
            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.black)
                    .strikethrough(item.isCompleted, color: Color.black.opacity(0.8))
                    .multilineTextAlignment(.leading)

                HStack(spacing: HIGSpacing.xs) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.black.opacity(0.65))
                        Text(item.timestamp, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color.black.opacity(0.65))
                    }

                    // Badge Prioritas Kartun
                    priorityBadge(for: item.priority)

                    // Badge Jadwal Rutin (Scheduler)
                    if item.isRecurring {
                        recurrenceBadge(for: item.recurrence)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap?()
            }

            Spacer()

            // 3. 🗑️ Tombol Hapus Kartun Pop
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    onDelete()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.cartoonPink)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: 1.8)
                        )
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                    
                    Image(systemName: "trash.fill")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.black)
                }
                .frame(width: HIGSpacing.touchTargetMin, height: HIGSpacing.touchTargetMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
        }
        .padding(.horizontal, HIGSpacing.md)
        .padding(.vertical, HIGSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .fill(item.isCompleted ? Color(red: 0.94, green: 0.94, blue: 0.94) : cardBgColor(for: item.priority))
                .shadow(color: .black, radius: 0, x: item.isCompleted ? 1.5 : 2.5, y: item.isCompleted ? 1.5 : 2.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
    }

    // MARK: - Warna Background Kartu Terang Solid
    private func cardBgColor(for priority: String) -> Color {
        switch priority {
        case "Tinggi": return Color(red: 1.0, green: 0.88, blue: 0.88)
        case "Normal": return Color(red: 1.0, green: 0.95, blue: 0.82)
        case "Rendah": return Color(red: 0.88, green: 0.95, blue: 1.0)
        default: return .white
        }
    }

    // MARK: - Badge Prioritas Bergaya Kartun
    @ViewBuilder
    private func priorityBadge(for priority: String) -> some View {
        let (color, text) = badgeData(for: priority)
        Text(text)
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .foregroundColor(.black)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(color)
            )
            .overlay(
                Capsule().stroke(Color.black, lineWidth: 1.2)
            )
            .shadow(color: .black, radius: 0, x: 1, y: 1)
    }

    // MARK: - Badge Jadwal Rutin (Scheduler)
    @ViewBuilder
    private func recurrenceBadge(for rule: RecurrenceRule) -> some View {
        HStack(spacing: 3) {
            Image(systemName: rule.icon)
                .font(.system(size: 8, weight: .bold))
            Text(rule.shortTitle)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
        }
        .foregroundColor(.black)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule().fill(rule.badgeColor)
        )
        .overlay(
            Capsule().stroke(Color.black, lineWidth: 1.2)
        )
        .shadow(color: .black, radius: 0, x: 1, y: 1)
    }

    private func badgeData(for priority: String) -> (Color, String) {
        switch priority {
        case "Tinggi": return (Color.cartoonPink, "Tinggi")
        case "Normal": return (Color.cartoonYellow, "Normal")
        case "Rendah": return (Color.cartoonMint, "Rendah")
        default: return (Color.white, priority)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ActivityCardView(
            item: Item(title: "Mengerjakan Desain UI Baru", timestamp: Date(), isCompleted: false, priority: "Tinggi", isRecurring: true, recurrenceRule: "Setiap Hari"),
            onToggle: {},
            onDelete: {}
        )
        ActivityCardView(
            item: Item(title: "Meeting Evaluasi Mingguan", timestamp: Date(), isCompleted: true, priority: "Normal"),
            onToggle: {},
            onDelete: {}
        )
    }
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
// ActivityCardView: helper methods kept here — its body reads private member(s): cardBgColor, priorityBadge, recurrenceBadge.
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

extension ActivityCardView {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_fae8196f80700150"] = { (a: [String]) in a.count >= 3 ? AnyView(HStack(spacing: HIGSpacing.sm) {
            // 1. 🔘 Tombol Checkbox Kartun Pop Neo-Brutalist
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) {
                    onToggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(item.isCompleted ? Color.cartoonMint : Color.white)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: 2.0)
                        )
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                    
                    if item.isCompleted {
                        Image(systemName: a[0])
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.black)
                    }
                }
                .frame(width: HIGSpacing.touchTargetMin, height: HIGSpacing.touchTargetMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))

            // 2. 📝 Detail Konten Aktivitas (Teks Hitam Tajam & Tegas Bergaya Kartun)
            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.black)
                    .strikethrough(item.isCompleted, color: Color.black.opacity(0.8))
                    .multilineTextAlignment(.leading)

                HStack(spacing: HIGSpacing.xs) {
                    HStack(spacing: 4) {
                        Image(systemName: a[1])
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.black.opacity(0.65))
                        Text(item.timestamp, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color.black.opacity(0.65))
                    }

                    // Badge Prioritas Kartun
                    priorityBadge(for: item.priority)

                    // Badge Jadwal Rutin (Scheduler)
                    if item.isRecurring {
                        recurrenceBadge(for: item.recurrence)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap?()
            }

            Spacer()

            // 3. 🗑️ Tombol Hapus Kartun Pop
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    onDelete()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.cartoonPink)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: 1.8)
                        )
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                    
                    Image(systemName: a[2])
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.black)
                }
                .frame(width: HIGSpacing.touchTargetMin, height: HIGSpacing.touchTargetMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
        }
        .padding(.horizontal, HIGSpacing.md)
        .padding(.vertical, HIGSpacing.sm)) : AnyView(EmptyView()) }
        __s["op_e3e6ecb1d6681846"] = { (_: [String]) in AnyView(RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .fill(item.isCompleted ? Color(red: 0.94, green: 0.94, blue: 0.94) : cardBgColor(for: item.priority))) }
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

#endif
// @generated — END OF AUTOGENERATED SECTION. DO NOT EDIT ABOVE (regenerated by `patchcli prepare`).
// PATCH-THUNKS-END
