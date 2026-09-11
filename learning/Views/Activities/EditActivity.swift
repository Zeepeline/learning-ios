//
//  EditActivity.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import SwiftUI
import SwiftData
import WidgetKit

struct EditActivity: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Binding item yang sedang diedit
    @Bindable var item: Item
    var onDelete: (() -> Void)?

    // State form
    @State private var taskTitle: String = ""
    @State private var dueDate: Date = Date()
    @State private var taskDetails: String = ""
    @State private var selectedCategory: String = "Belajar"
    @State private var selectedPriority: String = "Normal"
    @State private var isCompleted: Bool = false
    @State private var isShowingDatePicker: Bool = false
    
    // Scheduler States
    @State private var isSchedulerEnabled: Bool = false
    @State private var selectedRecurrence: RecurrenceRule = .daily

    private let priorities = ["Tinggi", "Normal", "Rendah"]

    dynamic var body: some View {
        NavigationStack {
            ZStack {
                Color.cartoonBg
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: HIGSpacing.lg) {
                        
                        // 1. Header Toolbar (Tombol Tutup & Hapus)
                        HStack {
                            CartoonIconButton(icon: "xmark") {
                                HapticManager.shared.impact(style: .light)
                                dismiss()
                            }

                            Spacer()

                            Text("Edit Task")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)

                            Spacer()

                            CartoonIconButton(icon: "trash.fill", iconColor: .red) {
                                HapticManager.shared.warning()
                                dismiss()
                                onDelete?()
                            }
                        }
                        .padding(.top, HIGSpacing.md)

                        // 2. Status Selesai / Belum Selesai (Toggle Box Kartun)
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isCompleted.toggle()
                                if isCompleted {
                                    HapticManager.shared.success()
                                } else {
                                    HapticManager.shared.impact(style: .medium)
                                }
                            }
                        } label: {
                            HStack(spacing: HIGSpacing.sm) {
                                ZStack {
                                    Circle()
                                        .fill(isCompleted ? Color.cartoonMint : Color.white)
                                        .frame(width: 32, height: 32)
                                        .shadow(color: .black, radius: 0, x: 1, y: 1)
                                        .overlay(Circle().stroke(Color.black, lineWidth: 2))

                                    if isCompleted {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 15, weight: .black))
                                            .foregroundColor(.black)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(isCompleted ? "Status: Selesai" : "Status: Belum Selesai")
                                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                                        .foregroundColor(.black)

                                    Text("Ketuk untuk mengubah status pengerjaan")
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding(HIGSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .fill(isCompleted ? Color.cartoonMint.opacity(0.3) : Color.white)
                                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                        // 3. Form Input Utama
                        VStack(spacing: HIGSpacing.sm) {
                            
                            // Field 1: Task Title
                            HStack(spacing: HIGSpacing.xs) {
                                Text("|")
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                    .foregroundColor(.secondary.opacity(0.6))
                                TextField("Task Title", text: $taskTitle)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .padding(.horizontal, HIGSpacing.md)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .fill(Color.white)
                                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )

                            // Field 2: Date Picker Selector
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    isShowingDatePicker.toggle()
                                    HapticManager.shared.selection()
                                }
                            } label: {
                                HStack(spacing: HIGSpacing.xs) {
                                    Text("|")
                                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                                        .foregroundColor(.secondary.opacity(0.6))
                                    
                                    Image(systemName: "calendar")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.secondary)
                                    
                                    Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    Image(systemName: isShowingDatePicker ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.black)
                                }
                                .padding(.horizontal, HIGSpacing.md)
                                .frame(height: 50)
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
                            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                            // 🎨 Reusable Cartoon Calendar Component
                            if isShowingDatePicker {
                                CartoonCalendarView(selectedDate: $dueDate)
                                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                            }

                            // Field 3: Task Details
                            VStack(alignment: .leading, spacing: HIGSpacing.xxs) {
                                ZStack(alignment: .topLeading) {
                                    if taskDetails.isEmpty {
                                        Text("Catatan atau detail tugas...")
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundColor(.secondary.opacity(0.7))
                                            .padding(.top, HIGSpacing.xs)
                                            .padding(.leading, HIGSpacing.xxs)
                                    }
                                    
                                    TextEditor(text: $taskDetails)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .frame(minHeight: 100)
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                }
                            }
                            .padding(HIGSpacing.sm)
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

                        // 4. Section Scheduler / Jadwal Rutin (Mirip Pengaturan)
                        schedulerSection

                        // 5. Prioritas Selector Kartun (Tinggi, Normal, Rendah)
                        VStack(alignment: .leading, spacing: HIGSpacing.xs) {
                            Text("Prioritas Tugas")
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)

                            HStack(spacing: HIGSpacing.xs) {
                                ForEach(priorities, id: \.self) { priority in
                                    let isSelected = selectedPriority == priority
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedPriority = priority
                                            HapticManager.shared.selection()
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            if priority == "Tinggi" {
                                                Image(systemName: "bolt.fill")
                                            }
                                            Text(priority)
                                        }
                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(priorityBgColor(for: priority, isSelected: isSelected))
                                                .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.black, lineWidth: isSelected ? 2.0 : 1.4)
                                        )
                                    }
                                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                                }
                            }
                        }

                        // 6. 🎨 Reusable Category Picker Grid
                        CartoonCategoryPicker(selectedCategory: $selectedCategory)
                            .padding(.top, HIGSpacing.xxs)

                        // 7. Tombol Simpan Perubahan
                        CartoonPrimaryButton(
                            title: "Simpan Perubahan",
                            icon: "checkmark.circle.fill",
                            bgColor: Color.cartoonYellow,
                            fgColor: .black,
                            isEnabled: !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ) {
                            saveChanges()
                        }
                        .padding(.top, HIGSpacing.xs)
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
        .onAppear {
            taskTitle = item.title
            dueDate = item.timestamp
            taskDetails = item.notes
            selectedCategory = item.category.isEmpty ? "Belajar" : item.category
            selectedPriority = item.priority.isEmpty ? "Normal" : item.priority
            isCompleted = item.isCompleted
            isSchedulerEnabled = item.isRecurring
            selectedRecurrence = item.recurrence
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

    private func priorityBgColor(for priority: String, isSelected: Bool) -> Color {
        guard isSelected else { return Color.white }
        switch priority {
        case "Tinggi": return Color.cartoonPink
        case "Normal": return Color.cartoonYellow
        case "Rendah": return Color.cartoonMint
        default: return Color.white
        }
    }

    private func saveChanges() {
        withAnimation {
            item.title = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            item.timestamp = dueDate
            item.notes = taskDetails
            item.category = selectedCategory
            item.priority = selectedPriority
            item.isCompleted = isCompleted
            item.isRecurring = isSchedulerEnabled
            item.recurrenceRule = isSchedulerEnabled ? selectedRecurrence.rawValue : "Sekali Saja"

            // Perbarui jadwal notifikasi lokal
            if !isCompleted {
                Task {
                    await NotificationManager.shared.scheduleNotification(for: item)
                }
            } else {
                NotificationManager.shared.cancelNotification(for: item)
            }

            // Simpan perubahan ke SQLite shared container secara instan
            try? modelContext.save()

            // Perbarui Widget di Home Screen
            WidgetCenter.shared.reloadAllTimelines()

            HapticManager.shared.success()
            dismiss()
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
// EditActivity: helper methods kept here — its body reads private member(s): dismiss, dueDate, isCompleted, isSchedulerEnabled, isShowingDatePicker, priorities, priorityBgColor, saveChanges, schedulerSection, selectedCategory, selectedPriority, selectedRecurrence, taskDetails, taskTitle.
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

extension EditActivity {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_947f7e37d9bca43d"] = { (a: [String]) in a.count >= 18 ? AnyView(VStack(alignment: .leading, spacing: HIGSpacing.lg) {
                        
                        // 1. Header Toolbar (Tombol Tutup & Hapus)
                        HStack {
                            CartoonIconButton(icon: a[0]) {
                                HapticManager.shared.impact(style: .light)
                                dismiss()
                            }

                            Spacer()

                            Text(LocalizedStringKey(a[1]))
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)

                            Spacer()

                            CartoonIconButton(icon: a[2], iconColor: .red) {
                                HapticManager.shared.warning()
                                dismiss()
                                onDelete?()
                            }
                        }
                        .padding(.top, HIGSpacing.md)

                        // 2. Status Selesai / Belum Selesai (Toggle Box Kartun)
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isCompleted.toggle()
                                if isCompleted {
                                    HapticManager.shared.success()
                                } else {
                                    HapticManager.shared.impact(style: .medium)
                                }
                            }
                        } label: {
                            HStack(spacing: HIGSpacing.sm) {
                                ZStack {
                                    Circle()
                                        .fill(isCompleted ? Color.cartoonMint : Color.white)
                                        .frame(width: 32, height: 32)
                                        .shadow(color: .black, radius: 0, x: 1, y: 1)
                                        .overlay(Circle().stroke(Color.black, lineWidth: 2))

                                    if isCompleted {
                                        Image(systemName: a[3])
                                            .font(.system(size: 15, weight: .black))
                                            .foregroundColor(.black)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(isCompleted ? LocalizedStringKey(a[4]) : LocalizedStringKey(a[5]))
                                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                                        .foregroundColor(.black)

                                    Text(LocalizedStringKey(a[6]))
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding(HIGSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .fill(isCompleted ? Color.cartoonMint.opacity(0.3) : Color.white)
                                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                        // 3. Form Input Utama
                        VStack(spacing: HIGSpacing.sm) {
                            
                            // Field 1: Task Title
                            HStack(spacing: HIGSpacing.xs) {
                                Text(LocalizedStringKey(a[7]))
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                    .foregroundColor(.secondary.opacity(0.6))
                                TextField(LocalizedStringKey(a[8]), text: $taskTitle)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .padding(.horizontal, HIGSpacing.md)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .fill(Color.white)
                                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )

                            // Field 2: Date Picker Selector
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    isShowingDatePicker.toggle()
                                    HapticManager.shared.selection()
                                }
                            } label: {
                                HStack(spacing: HIGSpacing.xs) {
                                    Text(LocalizedStringKey(a[9]))
                                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                                        .foregroundColor(.secondary.opacity(0.6))
                                    
                                    Image(systemName: a[10])
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.secondary)
                                    
                                    Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    Image(systemName: isShowingDatePicker ? a[11] : a[12])
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.black)
                                }
                                .padding(.horizontal, HIGSpacing.md)
                                .frame(height: 50)
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
                            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                            // 🎨 Reusable Cartoon Calendar Component
                            if isShowingDatePicker {
                                CartoonCalendarView(selectedDate: $dueDate)
                                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                            }

                            // Field 3: Task Details
                            VStack(alignment: .leading, spacing: HIGSpacing.xxs) {
                                ZStack(alignment: .topLeading) {
                                    if taskDetails.isEmpty {
                                        Text(LocalizedStringKey(a[13]))
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundColor(.secondary.opacity(0.7))
                                            .padding(.top, HIGSpacing.xs)
                                            .padding(.leading, HIGSpacing.xxs)
                                    }
                                    
                                    TextEditor(text: $taskDetails)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .frame(minHeight: 100)
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                }
                            }
                            .padding(HIGSpacing.sm)
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

                        // 4. Section Scheduler / Jadwal Rutin (Mirip Pengaturan)
                        schedulerSection

                        // 5. Prioritas Selector Kartun (Tinggi, Normal, Rendah)
                        VStack(alignment: .leading, spacing: HIGSpacing.xs) {
                            Text(LocalizedStringKey(a[14]))
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)

                            HStack(spacing: HIGSpacing.xs) {
                                ForEach(priorities, id: \.self) { priority in
                                    let isSelected = selectedPriority == priority
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedPriority = priority
                                            HapticManager.shared.selection()
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            if priority == "Tinggi" {
                                                Image(systemName: a[15])
                                            }
                                            Text(priority)
                                        }
                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(priorityBgColor(for: priority, isSelected: isSelected))
                                                .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.black, lineWidth: isSelected ? 2.0 : 1.4)
                                        )
                                    }
                                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                                }
                            }
                        }

                        // 6. 🎨 Reusable Category Picker Grid
                        CartoonCategoryPicker(selectedCategory: $selectedCategory)
                            .padding(.top, HIGSpacing.xxs)

                        // 7. Tombol Simpan Perubahan
                        CartoonPrimaryButton(
                            title: a[16],
                            icon: a[17],
                            bgColor: Color.cartoonYellow,
                            fgColor: .black,
                            isEnabled: !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ) {
                            saveChanges()
                        }
                        .padding(.top, HIGSpacing.xs)
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
        var __e: [String: (AnyView) -> AnyView] = [:]
        __e["effa4998ea06286806d"] = { (content: AnyView) -> AnyView in AnyView(content.onAppear {
            taskTitle = item.title
            dueDate = item.timestamp
            taskDetails = item.notes
            selectedCategory = item.category.isEmpty ? "Belajar" : item.category
            selectedPriority = item.priority.isEmpty ? "Normal" : item.priority
            isCompleted = item.isCompleted
            isSchedulerEnabled = item.isRecurring
            selectedRecurrence = item.recurrence
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
