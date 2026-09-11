//
//  AddActivity.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI
import SwiftData
import WidgetKit

struct AddActivity: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Form States
    @State private var taskTitle: String = ""
    @State private var taskDetails: String = ""
    @State private var dueDate: Date = Date()
    @State private var selectedCategory: String = "Belajar"
    @State private var getAlert: Bool = true
    @State private var syncToCalendar: Bool = false
    
    // Scheduler / Jadwal Rutin States (Mirip di Pengaturan)
    @State private var isSchedulerEnabled: Bool = false
    @State private var selectedRecurrence: RecurrenceRule = .daily

    dynamic var body: some View {
        NavigationStack {
            ZStack {
                // Background Utama
                Color.cartoonBg
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: HIGSpacing.lg) {
                        
                        // 1. Header Toolbar
                        HStack {
                            CartoonIconButton(icon: "xmark") {
                                dismiss()
                            }

                            Spacer()

                            Text("New Activity")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)

                            Spacer()

                            // Balancing spacer
                            Color.clear.frame(width: 44, height: 44)
                        }
                        .padding(.top, HIGSpacing.md)

                        // 2. Form Input: Title
                        VStack(spacing: HIGSpacing.xs) {
                            HStack(spacing: HIGSpacing.xs) {
                                Text("|")
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                    .foregroundColor(.secondary.opacity(0.6))
                                TextField("Activity Title", text: $taskTitle)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .padding(.horizontal, HIGSpacing.md)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(CartoonMetrics.cardCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                        }

                        // 3. Form Input: Category Picker Grid
                        CartoonCategoryPicker(
                            selectedCategory: $selectedCategory
                        )

                        // 4. Form Input: Details / Description
                        VStack(alignment: .leading, spacing: HIGSpacing.xxs) {
                            Text("DETAILS")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, HIGSpacing.xxs)

                            ZStack(alignment: .topLeading) {
                                if taskDetails.isEmpty {
                                    Text("Tambah catatan atau detail...")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary.opacity(0.6))
                                        .padding(.top, HIGSpacing.sm)
                                        .padding(.leading, HIGSpacing.xs)
                                }

                                TextEditor(text: $taskDetails)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .frame(minHeight: 70)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                            }
                            .padding(HIGSpacing.sm)
                            .background(Color.white)
                            .cornerRadius(CartoonMetrics.cardCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                        }

                        // 5. Form Input: Date & Time Picker
                        VStack(alignment: .leading, spacing: HIGSpacing.xxs) {
                            Text("DATE & TIME")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, HIGSpacing.xxs)

                            CartoonCalendarView(selectedDate: $dueDate)
                        }

                        // 6. Section Scheduler / Jadwal Rutin
                        schedulerSection

                        // 7. Pengaturan Tambahan (Toggles)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("PENGATURAN TAMBAHAN")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)

                            VStack(spacing: HIGSpacing.xs) {
                                CartoonToggleRow(
                                    icon: "bell.badge.fill",
                                    iconColor: .black,
                                    iconBgColor: Color.cartoonYellow,
                                    title: "Pengingat Notifikasi",
                                    subtitle: "Kirim pemberitahuan saat waktu tiba",
                                    isOn: $getAlert,
                                    activeColor: Color.cartoonMint
                                )

                                CartoonToggleRow(
                                    icon: "calendar.badge.plus",
                                    iconColor: .black,
                                    iconBgColor: Color.cartoonBlue,
                                    title: "Sinkronkan ke Kalender",
                                    subtitle: "Simpan ke aplikasi Kalender Apple",
                                    isOn: $syncToCalendar,
                                    activeColor: Color.cartoonBlue
                                )
                            }
                        }

                        // 8. Tombol Simpan (Create Task)
                        Button {
                            createTask()
                        } label: {
                            HStack(spacing: HIGSpacing.xs) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16, weight: .black))
                                Text("Create Task")
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.cartoonYellow)
                            .cornerRadius(CartoonMetrics.cardCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                            .shadow(color: .black, radius: 0, x: 3, y: 3)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.5))
                        .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                        .padding(.top, HIGSpacing.sm)
                        .padding(.bottom, 60)
                    }
                    .padding(.horizontal, HIGSpacing.lg)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Selesai") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(.black)
                }
            }
        }
    }

    // MARK: - Section Scheduler / Jadwal Rutin
    private var schedulerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("JADWAL RUTIN (SCHEDULER)")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            VStack(spacing: HIGSpacing.xs) {
                // Toggle Aktifkan Scheduler
                CartoonToggleRow(
                    icon: "repeat.circle.fill",
                    iconColor: .black,
                    iconBgColor: Color.cartoonLavender,
                    title: "Jadwal Rutin (Scheduler)",
                    subtitle: "Ulangi otomatis berkala mirip di pengaturan",
                    isOn: $isSchedulerEnabled,
                    activeColor: Color.cartoonLavender
                )

                if isSchedulerEnabled {
                    VStack(alignment: .leading, spacing: HIGSpacing.sm) {
                        Text("FREKUENSI PENGULANGAN")
                            .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)

                        // Chip Pilihan Frekuensi
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach([RecurrenceRule.daily, .weekdays, .weekends, .weekly]) { rule in
                                    Button {
                                        HapticManager.shared.selection()
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                            selectedRecurrence = rule
                                        }
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: rule.icon)
                                                .font(.system(size: 11, weight: .bold))
                                            Text(rule.title)
                                                .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                                        }
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedRecurrence == rule ? rule.badgeColor : Color.white)
                                                .shadow(color: .black.opacity(0.1), radius: 0, x: 1, y: 1)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.black, lineWidth: selectedRecurrence == rule ? 1.6 : 1.0)
                                        )
                                    }
                                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                                }
                            }
                            .padding(.vertical, 2)
                        }

                        // Info Box
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color.cartoonBlue)
                            Text("Aktivitas akan diulang setiap **\(selectedRecurrence.shortTitle)** pada pukul **\(dueDate.formatted(date: .omitted, time: .shortened))**.")
                                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                .foregroundColor(.black.opacity(0.8))
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.cartoonBlue.opacity(0.12))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cartoonBlue.opacity(0.3), lineWidth: 1.0))
                    }
                    .padding(HIGSpacing.md)
                    .cartoonCard()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity.combined(with: .scale(scale: 0.98))
                    ))
                }
            }
        }
    }

    private func createTask() {
        let trimmedTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let newItem = Item(
            title: trimmedTitle,
            notes: taskDetails,
            timestamp: dueDate,
            isCompleted: false,
            priority: "Normal",
            category: selectedCategory,
            isRecurring: isSchedulerEnabled,
            recurrenceRule: isSchedulerEnabled ? selectedRecurrence.rawValue : "Sekali Saja"
        )

        modelContext.insert(newItem)

        if getAlert {
            Task {
                await NotificationManager.shared.scheduleNotification(for: newItem)
            }
        }

        if syncToCalendar {
            Task {
                _ = try? await CalendarSyncManager.shared.addEventToCalendar(
                    title: newItem.title,
                    startDate: newItem.timestamp,
                    notes: newItem.notes
                )
            }
        }

        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()

        HapticManager.shared.success()
        dismiss()
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
// AddActivity: helper methods kept here — its body reads private member(s): createTask, dismiss, dueDate, getAlert, schedulerSection, selectedCategory, syncToCalendar, taskDetails, taskTitle.
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

extension AddActivity {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_a8750bea11cdb490"] = { (a: [String]) in a.count >= 16 ? AnyView(VStack(alignment: .leading, spacing: HIGSpacing.lg) {
                        
                        // 1. Header Toolbar
                        HStack {
                            CartoonIconButton(icon: a[0]) {
                                dismiss()
                            }

                            Spacer()

                            Text(LocalizedStringKey(a[1]))
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)

                            Spacer()

                            // Balancing spacer
                            Color.clear.frame(width: 44, height: 44)
                        }
                        .padding(.top, HIGSpacing.md)

                        // 2. Form Input: Title
                        VStack(spacing: HIGSpacing.xs) {
                            HStack(spacing: HIGSpacing.xs) {
                                Text(LocalizedStringKey(a[2]))
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                    .foregroundColor(.secondary.opacity(0.6))
                                TextField(LocalizedStringKey(a[3]), text: $taskTitle)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .padding(.horizontal, HIGSpacing.md)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(CartoonMetrics.cardCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                        }

                        // 3. Form Input: Category Picker Grid
                        CartoonCategoryPicker(
                            selectedCategory: $selectedCategory
                        )

                        // 4. Form Input: Details / Description
                        VStack(alignment: .leading, spacing: HIGSpacing.xxs) {
                            Text(LocalizedStringKey(a[4]))
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, HIGSpacing.xxs)

                            ZStack(alignment: .topLeading) {
                                if taskDetails.isEmpty {
                                    Text(LocalizedStringKey(a[5]))
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary.opacity(0.6))
                                        .padding(.top, HIGSpacing.sm)
                                        .padding(.leading, HIGSpacing.xs)
                                }

                                TextEditor(text: $taskDetails)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .frame(minHeight: 70)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                            }
                            .padding(HIGSpacing.sm)
                            .background(Color.white)
                            .cornerRadius(CartoonMetrics.cardCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                        }

                        // 5. Form Input: Date & Time Picker
                        VStack(alignment: .leading, spacing: HIGSpacing.xxs) {
                            Text(LocalizedStringKey(a[6]))
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, HIGSpacing.xxs)

                            CartoonCalendarView(selectedDate: $dueDate)
                        }

                        // 6. Section Scheduler / Jadwal Rutin
                        schedulerSection

                        // 7. Pengaturan Tambahan (Toggles)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(LocalizedStringKey(a[7]))
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)

                            VStack(spacing: HIGSpacing.xs) {
                                CartoonToggleRow(
                                    icon: a[8],
                                    iconColor: .black,
                                    iconBgColor: Color.cartoonYellow,
                                    title: a[9],
                                    subtitle: a[10],
                                    isOn: $getAlert,
                                    activeColor: Color.cartoonMint
                                )

                                CartoonToggleRow(
                                    icon: a[11],
                                    iconColor: .black,
                                    iconBgColor: Color.cartoonBlue,
                                    title: a[12],
                                    subtitle: a[13],
                                    isOn: $syncToCalendar,
                                    activeColor: Color.cartoonBlue
                                )
                            }
                        }

                        // 8. Tombol Simpan (Create Task)
                        Button {
                            createTask()
                        } label: {
                            HStack(spacing: HIGSpacing.xs) {
                                Image(systemName: a[14])
                                    .font(.system(size: 16, weight: .black))
                                Text(LocalizedStringKey(a[15]))
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.cartoonYellow)
                            .cornerRadius(CartoonMetrics.cardCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                            .shadow(color: .black, radius: 0, x: 3, y: 3)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.5))
                        .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                        .padding(.top, HIGSpacing.sm)
                        .padding(.bottom, 60)
                    }
                    .padding(.horizontal, HIGSpacing.lg)) : AnyView(EmptyView()) }
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
        var __a: [String: () -> Void] = [:]
        __a["actf9137b8bc9046816"] = { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
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
