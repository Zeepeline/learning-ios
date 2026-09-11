//
//  CartoonTimelineComponents.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import SwiftUI

// MARK: - 📅 Reusable Strip Seleksi Hari Mingguan
struct CartoonWeeklyStrip: View {
    @Binding var selectedDate: Date
    let weekDays: [Date]
    var taskCountForDate: ((Date) -> (total: Int, completed: Int))? = nil

    private let calendar = Calendar.current

    dynamic var body: some View {
        HStack(spacing: HIGSpacing.xs) {
            ForEach(weekDays, id: \.self) { date in
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let isToday = calendar.isDateInToday(date)
                let taskStats = taskCountForDate?(date) ?? (total: 0, completed: 0)

                Button {
                    HapticManager.shared.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedDate = date
                    }
                } label: {
                    VStack(spacing: 4) {
                        // Nama Hari (SEN, SEL, RAB / MON, TUE, WED...)
                        Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(isSelected ? .white : .secondary)

                        // Angka Tanggal (14, 15, 17...)
                        Text(date.formatted(.dateTime.day()))
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(isSelected ? .white : .black)

                        // Indikator Titik Tugas (Task Dots)
                        HStack(spacing: 3) {
                            if taskStats.total > 0 {
                                Circle()
                                    .fill(
                                        isSelected
                                            ? Color.white
                                            : (taskStats.completed == taskStats.total ? Color.cartoonMint : Color.cartoonCoral)
                                    )
                                    .frame(width: 5, height: 5)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black, lineWidth: isSelected ? 0.8 : 0.8)
                                    )
                            } else {
                                // Spacer dot transparan untuk menjaga tinggi konsisten
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 5, height: 5)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                isSelected
                                    ? Color.cartoonCoral
                                    : (isToday ? Color.cartoonYellow.opacity(0.35) : Color.white)
                            )
                            .shadow(
                                color: isSelected ? .black : (isToday ? Color.black.opacity(0.15) : Color.black.opacity(0.08)),
                                radius: 0,
                                x: isSelected ? 2 : 1,
                                y: isSelected ? 2 : 1
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                Color.black,
                                lineWidth: isSelected ? 2.0 : (isToday ? 1.5 : 1.2)
                            )
                    )
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
        }
    }
}

// MARK: - 🗂️ Reusable Kartu Timeline Aktivitas (Item)
struct CartoonTimelineCard: View {
    let title: String
    let timeText: String
    var category: String = ""
    var notes: String = ""
    var isCompleted: Bool = false
    var isRecurring: Bool = false
    var recurrenceTitle: String = ""
    let onToggle: () -> Void
    let onDelete: () -> Void
    var onTap: (() -> Void)?

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.xs) {
            // Header Kartu: Judul & Menu More (•••)
            HStack(alignment: .top) {
                Button {
                    onTap?()
                } label: {
                    Text(title)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .strikethrough(isCompleted, color: .black)
                        .opacity(isCompleted ? 0.6 : 1.0)
                        .multilineTextAlignment(.leading)
                }
                .buttonStyle(.plain)

                Spacer()

                Menu {
                    Button("Edit Tugas") {
                        onTap?()
                    }
                    Button(isCompleted ? "Tandai Belum Selesai" : "Tandai Selesai") {
                        onToggle()
                    }
                    Button("Hapus Tugas", role: .destructive) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
            }

            // Waktu Tugas
            HStack(spacing: 6) {
                Text(timeText)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)

                if isRecurring && !recurrenceTitle.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "repeat")
                            .font(.system(size: 8, weight: .bold))
                        Text(recurrenceTitle)
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.cartoonLavender)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.black, lineWidth: 1.0))
                }
            }

            // Category Pill (Jika Ada)
            if !category.isEmpty {
                Text(category)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, HIGSpacing.sm)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.94, green: 0.94, blue: 0.94))
                    )
                    .padding(.top, 2)
            }

            // Catatan Tugas / Notes (Jika Ada)
            if !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(HIGSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isCompleted ? Color.gray.opacity(0.12) : Color.white)
                .shadow(color: .black, radius: 0, x: 2, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
    }
}

// MARK: - ➕ Reusable Input Cepat Subtask ("Add new subtask")
struct CartoonQuickAddBar: View {
    let timeLabel: String
    @Binding var text: String
    let onSubmit: () -> Void

    dynamic var body: some View {
        HStack(alignment: .center, spacing: HIGSpacing.sm) {
            Text(timeLabel)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 58, alignment: .leading)

            HStack(spacing: HIGSpacing.xs) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.secondary)

                TextField("Add new subtask...", text: $text)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .submitLabel(.done)
                    .onSubmit {
                        onSubmit()
                    }

                if !text.isEmpty {
                    Button(action: onSubmit) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.black)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, HIGSpacing.md)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.black, lineWidth: 1.5)
            )
        }
        .padding(.vertical, 4)
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
// CartoonWeeklyStrip: helper methods kept here — its body reads private member(s): calendar.
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

extension CartoonWeeklyStrip {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_db56ffc87fd51d4c"] = { (_: [String]) in AnyView(ForEach(weekDays, id: \.self) { date in
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let isToday = calendar.isDateInToday(date)
                let taskStats = taskCountForDate?(date) ?? (total: 0, completed: 0)

                Button {
                    HapticManager.shared.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedDate = date
                    }
                } label: {
                    VStack(spacing: 4) {
                        // Nama Hari (SEN, SEL, RAB / MON, TUE, WED...)
                        Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(isSelected ? .white : .secondary)

                        // Angka Tanggal (14, 15, 17...)
                        Text(date.formatted(.dateTime.day()))
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(isSelected ? .white : .black)

                        // Indikator Titik Tugas (Task Dots)
                        HStack(spacing: 3) {
                            if taskStats.total > 0 {
                                Circle()
                                    .fill(
                                        isSelected
                                            ? Color.white
                                            : (taskStats.completed == taskStats.total ? Color.cartoonMint : Color.cartoonCoral)
                                    )
                                    .frame(width: 5, height: 5)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black, lineWidth: isSelected ? 0.8 : 0.8)
                                    )
                            } else {
                                // Spacer dot transparan untuk menjaga tinggi konsisten
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 5, height: 5)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                isSelected
                                    ? Color.cartoonCoral
                                    : (isToday ? Color.cartoonYellow.opacity(0.35) : Color.white)
                            )
                            .shadow(
                                color: isSelected ? .black : (isToday ? Color.black.opacity(0.15) : Color.black.opacity(0.08)),
                                radius: 0,
                                x: isSelected ? 2 : 1,
                                y: isSelected ? 2 : 1
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                Color.black,
                                lineWidth: isSelected ? 2.0 : (isToday ? 1.5 : 1.2)
                            )
                    )
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }) }
        return __s
    }

    /// Resolved design-system token values for this view's `.hostToken(id)`/
    /// `.fontToken(id)`/numeric/string token slots. Empty when the view uses none.
    @MainActor func __patchTokens() -> [String: PatchHostToken] {
        var __t: [String: PatchHostToken] = [:]
        __t["nt_7bce3566dca34bd3"] = .number(Double(HIGSpacing.xs))
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
