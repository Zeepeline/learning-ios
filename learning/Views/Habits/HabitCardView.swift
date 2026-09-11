//
//  HabitCardView.swift
//  learning
//
//  Created by macbook on 9/6/26.
//

import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    let onToggleToday: () -> Void
    let onToggleDate: (Date) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private let calendar = Calendar.current
    
    // 7 hari terakhir (dari 6 hari lalu sampai hari ini)
    private var last7Days: [Date] {
        (0..<7).compactMap { i in
            calendar.date(byAdding: .day, value: -(6 - i), to: Date())
        }
    }
    
    private func dayName(for date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).locale(Locale(identifier: "id_ID"))).uppercased()
    }
    
    dynamic var body: some View {
        VStack(spacing: 12) {
            // Header: Icon + Info + Current Streak Badge + Tombol Checklist Hari Ini
            HStack(spacing: 10) {
                // Icon Bulat Kartun dengan Warna Habit (Bisa di-tap untuk edit)
                Button {
                    HapticManager.shared.impact(style: .light)
                    onEdit()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(habit.color)
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                            .frame(width: 40, height: 40)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.6))
                        
                        Image(systemName: habit.icon)
                            .font(.system(size: 17, weight: .black))
                            .foregroundColor(.black)
                    }
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                
                // Judul & Kategori (Bisa di-tap untuk edit)
                Button {
                    HapticManager.shared.impact(style: .light)
                    onEdit()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(habit.title)
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                                .lineLimit(1)
                            
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.black.opacity(0.4))
                        }
                        
                        HStack(spacing: 6) {
                            Text(habit.category)
                                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color.cartoonBg)
                                )
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.black, lineWidth: 0.8))
                            
                            // Streak Counter Kartun
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 9.5, weight: .bold))
                                    .foregroundColor(.orange)
                                
                                Text("\(habit.currentStreak) Hari")
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Tombol Checklist Hari Ini
                Button {
                    onToggleToday()
                } label: {
                    ZStack {
                        Circle()
                            .fill(habit.isCompletedToday ? Color.cartoonMint : Color.white)
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                            .frame(width: 38, height: 38)
                            .overlay(Circle().stroke(Color.black, lineWidth: 1.8))
                        
                        if habit.isCompletedToday {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(.black)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 12, height: 12)
                        }
                    }
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
            
            // Weekly Heatmap 7 Hari Terakhir
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("RIWAYAT 7 HARI TERAKHIR")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(habit.weeklyCompletionRate * 100))% Konsisten")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(habit.weeklyCompletionRate >= 0.7 ? Color(red: 0.1, green: 0.6, blue: 0.3) : .secondary)
                }
                
                HStack(spacing: 6) {
                    ForEach(last7Days, id: \.self) { date in
                        let isCompleted = habit.isCompleted(on: date)
                        let isToday = calendar.isDateInToday(date)
                        
                        Button {
                            onToggleDate(date)
                        } label: {
                            VStack(spacing: 3) {
                                Text(dayName(for: date).prefix(2))
                                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                                    .foregroundColor(isToday ? .black : .secondary)
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isCompleted ? habit.color : Color(red: 0.94, green: 0.94, blue: 0.95))
                                        .frame(height: 26)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.black, lineWidth: isToday ? 1.5 : 0.8)
                                        )
                                    
                                    if isCompleted {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 9, weight: .black))
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    }
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.6))
            )
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.0))
        }
        .padding(HIGSpacing.md)
        .cartoonCard()
        .contextMenu {
            Button {
                HapticManager.shared.impact(style: .light)
                onEdit()
            } label: {
                Label("Edit Kebiasaan", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Hapus Kebiasaan", systemImage: "trash")
            }
        }
    }
}

#Preview {
    HabitCardView(
        habit: Habit(
            title: "Minum Air 2 Liter",
            icon: "drop.fill",
            colorHex: "#118AB2",
            category: "Kesehatan",
            completedDates: [Date()]
        ),
        onToggleToday: {},
        onToggleDate: { _ in },
        onEdit: {},
        onDelete: {}
    )
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
// HabitCardView: helper methods kept here — its body reads private member(s): calendar, dayName, last7Days.
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

extension HabitCardView {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_fcfc538aad402034"] = { (a: [String]) in a.count >= 5 ? AnyView(VStack(spacing: 12) {
            // Header: Icon + Info + Current Streak Badge + Tombol Checklist Hari Ini
            HStack(spacing: 10) {
                // Icon Bulat Kartun dengan Warna Habit (Bisa di-tap untuk edit)
                Button {
                    HapticManager.shared.impact(style: .light)
                    onEdit()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(habit.color)
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                            .frame(width: 40, height: 40)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.6))
                        
                        Image(systemName: habit.icon)
                            .font(.system(size: 17, weight: .black))
                            .foregroundColor(.black)
                    }
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                
                // Judul & Kategori (Bisa di-tap untuk edit)
                Button {
                    HapticManager.shared.impact(style: .light)
                    onEdit()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(habit.title)
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                                .lineLimit(1)
                            
                            Image(systemName: a[0])
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.black.opacity(0.4))
                        }
                        
                        HStack(spacing: 6) {
                            Text(habit.category)
                                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color.cartoonBg)
                                )
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.black, lineWidth: 0.8))
                            
                            // Streak Counter Kartun
                            HStack(spacing: 2) {
                                Image(systemName: a[1])
                                    .font(.system(size: 9.5, weight: .bold))
                                    .foregroundColor(.orange)
                                
                                Text("\(habit.currentStreak) Hari")
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Tombol Checklist Hari Ini
                Button {
                    onToggleToday()
                } label: {
                    ZStack {
                        Circle()
                            .fill(habit.isCompletedToday ? Color.cartoonMint : Color.white)
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                            .frame(width: 38, height: 38)
                            .overlay(Circle().stroke(Color.black, lineWidth: 1.8))
                        
                        if habit.isCompletedToday {
                            Image(systemName: a[2])
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(.black)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 12, height: 12)
                        }
                    }
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
            
            // Weekly Heatmap 7 Hari Terakhir
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(LocalizedStringKey(a[3]))
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(habit.weeklyCompletionRate * 100))% Konsisten")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(habit.weeklyCompletionRate >= 0.7 ? Color(red: 0.1, green: 0.6, blue: 0.3) : .secondary)
                }
                
                HStack(spacing: 6) {
                    ForEach(last7Days, id: \.self) { date in
                        let isCompleted = habit.isCompleted(on: date)
                        let isToday = calendar.isDateInToday(date)
                        
                        Button {
                            onToggleDate(date)
                        } label: {
                            VStack(spacing: 3) {
                                Text(dayName(for: date).prefix(2))
                                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                                    .foregroundColor(isToday ? .black : .secondary)
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isCompleted ? habit.color : Color(red: 0.94, green: 0.94, blue: 0.95))
                                        .frame(height: 26)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.black, lineWidth: isToday ? 1.5 : 0.8)
                                        )
                                    
                                    if isCompleted {
                                        Image(systemName: a[4])
                                            .font(.system(size: 9, weight: .black))
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    }
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.6))
            )
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.0))
        }
        .padding(HIGSpacing.md)
        .cartoonCard()) : AnyView(EmptyView()) }
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
        var __a: [String: () -> Void] = [:]
        __a["act733c10904308a1c5"] = { HapticManager.shared.impact(style: .light)
                onEdit() }
        __a["actbb3646fb226cb1d2"] = { onDelete() }
        return __a
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
