//
//  TodayTimelineView.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import SwiftUI
import SwiftData
import WidgetKit

struct TodayTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.timestamp, order: .forward) private var allItems: [Item]

    @State private var selectedDate: Date = Date()
    @State private var baseWeekDate: Date = Date()
    @State private var isMonthViewExpanded: Bool = false
    @State private var newSubtaskTitle: String = ""
    @State private var isShowingAddActivity: Bool = false
    @FocusState private var isQuickAddFocused: Bool

    // Callback untuk delete, toggle, & edit dari ContentView
    var onDeleteItem: (Item) -> Void
    var onToggleItem: (Item) -> Void
    var onEditItem: (Item) -> Void

    private let calendar = Calendar.current

    // Mendapatkan 7 hari dalam minggu dari baseWeekDate
    private var weekDays: [Date] {
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: baseWeekDate)?.start else {
            return [baseWeekDate]
        }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    // Cek apakah item aktif pada tanggal tertentu (mendukung tugas berulang / scheduler)
    @inline(__always)
    private func isItemActive(_ item: Item, on date: Date) -> Bool {
        if !item.isRecurring {
            return calendar.isDate(item.timestamp, inSameDayAs: date)
        }

        // Jangan tampilkan sebelum tanggal pertama kali dibuat
        let targetStart = calendar.startOfDay(for: date)
        let itemStart = calendar.startOfDay(for: item.timestamp)
        guard targetStart >= itemStart else {
            return false
        }

        let targetWeekday = calendar.component(.weekday, from: date)
        switch item.recurrence {
        case .daily:
            return true
        case .weekdays:
            return (2...6).contains(targetWeekday)
        case .weekends:
            return targetWeekday == 1 || targetWeekday == 7
        case .weekly:
            let itemWeekday = calendar.component(.weekday, from: item.timestamp)
            return targetWeekday == itemWeekday
        case .none:
            return calendar.isDate(item.timestamp, inSameDayAs: date)
        }
    }

    // Filter item yang sesuai dengan tanggal terpilih (100% Data Nyata dari SwiftData)
    private var filteredItems: [Item] {
        allItems.filter { isItemActive($0, on: selectedDate) }
    }

    // Statistik tugas pada tanggal terpilih
    private var completedTasksCount: Int {
        filteredItems.filter { $0.isCompleted }.count
    }

    private var totalTasksCount: Int {
        filteredItems.count
    }

    private var progressRatio: Double {
        guard totalTasksCount > 0 else { return 0 }
        return Double(completedTasksCount) / Double(totalTasksCount)
    }

    // ⚡ Optimized Fast Task Count per Date (Single-pass lookup)
    private func getTaskCount(for date: Date) -> (total: Int, completed: Int) {
        var total = 0
        var completed = 0
        for item in allItems {
            if isItemActive(item, on: date) {
                total += 1
                if item.isCompleted {
                    completed += 1
                }
            }
        }
        return (total: total, completed: completed)
    }

    // Cek apakah tanggal terpilih adalah hari ini
    private var isSelectedDateToday: Bool {
        calendar.isDateInToday(selectedDate)
    }

    dynamic var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: HIGSpacing.md) {
                    
                    // 1. 📅 Bar Navigasi Kalender (Bulan/Tahun, Hari Ini, < >, Mode Toggle)
                    calendarControlHeader
                        .padding(.horizontal, HIGSpacing.md)
                        .padding(.top, HIGSpacing.xs)

                    // 2. 🗓️ Tampilan Kalender (Mingguan Strip atau Bulanan Penuh)
                    if isMonthViewExpanded {
                        CartoonCalendarView(
                            selectedDate: $selectedDate,
                            showTimePicker: false,
                            taskCountForDate: { date in
                                getTaskCount(for: date)
                            }
                        )
                        .padding(.horizontal, HIGSpacing.md)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.96)),
                            removal: .opacity.combined(with: .scale(scale: 0.96))
                        ))
                    } else {
                        CartoonWeeklyStrip(
                            selectedDate: $selectedDate,
                            weekDays: weekDays,
                            taskCountForDate: { date in
                                getTaskCount(for: date)
                            }
                        )
                        .padding(.horizontal, HIGSpacing.md)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.96)),
                            removal: .opacity.combined(with: .scale(scale: 0.96))
                        ))
                    }

                    // 3. 🎯 Kartu Ringkasan Progress Harian
                    dailyProgressCard
                        .padding(.horizontal, HIGSpacing.md)

                    // 4. 🗂️ Garis Timeline Vertikal & Kartu Aktivitas (Menggunakan LazyVStack untuk 120fps)
                    VStack(spacing: HIGSpacing.md) {
                        if filteredItems.isEmpty {
                            emptyTimelineState
                        } else {
                            // ⚡ LazyVStack: Instansiasi on-demand kartu tugas untuk performa scroll mulus
                            LazyVStack(spacing: HIGSpacing.sm) {
                                ForEach(filteredItems) { item in
                                    HStack(alignment: .top, spacing: HIGSpacing.sm) {
                                        // Kolom Waktu di Kiri (Format: 09:00 AM)
                                        Text(item.timestamp.formatted(.dateTime.hour().minute()))
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(.secondary)
                                            .frame(width: 58, alignment: .leading)
                                            .padding(.top, HIGSpacing.xs)

                                        // Reusable Timeline Card Component dengan Dukungan Edit saat Diketuk
                                        CartoonTimelineCard(
                                            title: item.title,
                                            timeText: item.timestamp.formatted(date: .omitted, time: .shortened),
                                            category: item.category,
                                            notes: item.notes,
                                            isCompleted: item.isCompleted,
                                            isRecurring: item.isRecurring,
                                            recurrenceTitle: item.recurrence.shortTitle,
                                            onToggle: { onToggleItem(item) },
                                            onDelete: { onDeleteItem(item) },
                                            onTap: { onEditItem(item) }
                                        )
                                    }
                                }
                            }

                            // ➕ Reusable Baris Input Cepat "Add new subtask"
                            CartoonQuickAddBar(timeLabel: "Quick", text: $newSubtaskTitle) {
                                createQuickSubtask()
                            }
                            .focused($isQuickAddFocused)
                            .id("quickAddBar")
                        }
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    .padding(.top, HIGSpacing.xs)
                    .padding(.bottom, 100) // Ruang safe area bottom bar
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .onTapGesture {
                isQuickAddFocused = false
            }
            .sheet(isPresented: $isShowingAddActivity) {
                AddActivity()
            }
        }
    }

    // MARK: - 🎛️ Header Kontrol Kalender
    private var calendarControlHeader: some View {
        HStack {
            // Label Bulan & Tahun
            VStack(alignment: .leading, spacing: 2) {
                Text(monthYearText(from: selectedDate))
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Text(isSelectedDateToday ? "Hari Ini" : selectedDate.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "id_ID"))))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(isSelectedDateToday ? Color.cartoonCoral : .secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                // Tombol "Hari Ini"
                if !isSelectedDateToday {
                    Button {
                        HapticManager.shared.impact(style: .medium)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedDate = Date()
                            baseWeekDate = Date()
                        }
                    } label: {
                        Text("Hari Ini")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.cartoonYellow)
                                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                }

                // Navigasi Minggu Sebelumnya (<)
                Button {
                    changeWeek(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.5))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                // Navigasi Minggu Berikutnya (>)
                Button {
                    changeWeek(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.5))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                // Toggle Tampilan Bulan/Mingguan
                Button {
                    HapticManager.shared.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        isMonthViewExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isMonthViewExpanded ? "calendar.day.timeline.left" : "calendar")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .background(isMonthViewExpanded ? Color.cartoonLavender : Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.5))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
        }
    }

    // MARK: - 🎯 Kartu Ringkasan Progress Harian
    private var dailyProgressCard: some View {
        HStack(spacing: HIGSpacing.md) {
            // Icon Progress Kartun
            ZStack {
                Circle()
                    .fill(progressRatio >= 1.0 && totalTasksCount > 0 ? Color.cartoonMint : Color.cartoonYellow)
                    .frame(width: 46, height: 46)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))

                if progressRatio >= 1.0 && totalTasksCount > 0 {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                } else {
                    Text("\(Int(progressRatio * 100))%")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
            }

            // Info Teks Progress
            VStack(alignment: .leading, spacing: 3) {
                Text(progressTitle)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Text(progressSubtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)

                // Bar Progress Mini Kartun
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(red: 0.90, green: 0.90, blue: 0.92))
                            .frame(height: 8)
                            .overlay(Capsule().stroke(Color.black, lineWidth: 1.2))

                        Capsule()
                            .fill(progressRatio >= 1.0 ? Color.cartoonMint : Color.cartoonCoral)
                            .frame(width: max(0, geo.size.width * CGFloat(progressRatio)), height: 8)
                            .overlay(Capsule().stroke(Color.black, lineWidth: progressRatio > 0 ? 1.2 : 0))
                    }
                }
                .frame(height: 8)
                .padding(.top, 2)
            }

            Spacer()
        }
        .padding(HIGSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black, radius: 0, x: 2, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
    }

    private var progressTitle: String {
        if totalTasksCount == 0 {
            return "Tidak Ada Tugas"
        } else if completedTasksCount == totalTasksCount {
            return "Semua Tugas Tuntas! 🎉"
        } else {
            return "\(completedTasksCount) dari \(totalTasksCount) Selesai"
        }
    }

    private var progressSubtitle: String {
        if totalTasksCount == 0 {
            return "Jadwal kosong, istirahat atau buat tugas baru!"
        } else if completedTasksCount == totalTasksCount {
            return "Pencapaian luar biasa untuk hari ini!"
        } else {
            return "\(totalTasksCount - completedTasksCount) tugas lagi yang menunggu kamu."
        }
    }

    // MARK: - 📬 Tampilan Kosong untuk Tanggal Terpilih
    private var emptyTimelineState: some View {
        VStack(spacing: HIGSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.cartoonYellow)
                    .frame(width: 64, height: 64)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
            }
            .padding(.top, HIGSpacing.md)

            VStack(spacing: HIGSpacing.xxs) {
                Text("Tidak Ada Jadwal")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Text("Belum ada tugas terjadwal pada tanggal ini.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Tombol Tambah Tugas untuk Tanggal Ini
            Button {
                isShowingAddActivity = true
            } label: {
                HStack(spacing: HIGSpacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Buat Jadwal Baru")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black)
                .padding(.horizontal, HIGSpacing.lg)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cartoonMint)
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                )
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.8))
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            .padding(.top, HIGSpacing.xxs)

            // ➕ Reusable Input Tambah Cepat
            CartoonQuickAddBar(timeLabel: "Add", text: $newSubtaskTitle) {
                createQuickSubtask()
            }
            .padding(.top, HIGSpacing.sm)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HIGSpacing.md)
    }

    // MARK: - Helper Logika Navigasi & Aksi
    private func monthYearText(from date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "id_ID")))
    }

    private func changeWeek(by amount: Int) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            if let newBase = calendar.date(byAdding: .weekOfYear, value: amount, to: baseWeekDate) {
                baseWeekDate = newBase
                if let newSelected = calendar.date(byAdding: .weekOfYear, value: amount, to: selectedDate) {
                    selectedDate = newSelected
                }
            }
        }
        HapticManager.shared.selection()
    }

    private func createQuickSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            let newItem = Item(
                title: trimmed,
                notes: "",
                timestamp: selectedDate,
                isCompleted: false,
                priority: "Normal",
                category: "Subtask"
            )
            modelContext.insert(newItem)
            try? modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()

            newSubtaskTitle = ""
            isQuickAddFocused = false
            HapticManager.shared.success()
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
// TodayTimelineView: helper methods kept here — its body reads private member(s): calendarControlHeader, createQuickSubtask, dailyProgressCard, emptyTimelineState, filteredItems, getTaskCount, isMonthViewExpanded, isQuickAddFocused, isShowingAddActivity, newSubtaskTitle, selectedDate, weekDays.
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

extension TodayTimelineView {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_921beea8f3de0173"] = { (a: [String]) in a.count >= 1 ? AnyView(ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: HIGSpacing.md) {
                    
                    // 1. 📅 Bar Navigasi Kalender (Bulan/Tahun, Hari Ini, < >, Mode Toggle)
                    calendarControlHeader
                        .padding(.horizontal, HIGSpacing.md)
                        .padding(.top, HIGSpacing.xs)

                    // 2. 🗓️ Tampilan Kalender (Mingguan Strip atau Bulanan Penuh)
                    if isMonthViewExpanded {
                        CartoonCalendarView(
                            selectedDate: $selectedDate,
                            showTimePicker: false,
                            taskCountForDate: { date in
                                getTaskCount(for: date)
                            }
                        )
                        .padding(.horizontal, HIGSpacing.md)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.96)),
                            removal: .opacity.combined(with: .scale(scale: 0.96))
                        ))
                    } else {
                        CartoonWeeklyStrip(
                            selectedDate: $selectedDate,
                            weekDays: weekDays,
                            taskCountForDate: { date in
                                getTaskCount(for: date)
                            }
                        )
                        .padding(.horizontal, HIGSpacing.md)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.96)),
                            removal: .opacity.combined(with: .scale(scale: 0.96))
                        ))
                    }

                    // 3. 🎯 Kartu Ringkasan Progress Harian
                    dailyProgressCard
                        .padding(.horizontal, HIGSpacing.md)

                    // 4. 🗂️ Garis Timeline Vertikal & Kartu Aktivitas (Menggunakan LazyVStack untuk 120fps)
                    VStack(spacing: HIGSpacing.md) {
                        if filteredItems.isEmpty {
                            emptyTimelineState
                        } else {
                            // ⚡ LazyVStack: Instansiasi on-demand kartu tugas untuk performa scroll mulus
                            LazyVStack(spacing: HIGSpacing.sm) {
                                ForEach(filteredItems) { item in
                                    HStack(alignment: .top, spacing: HIGSpacing.sm) {
                                        // Kolom Waktu di Kiri (Format: 09:00 AM)
                                        Text(item.timestamp.formatted(.dateTime.hour().minute()))
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(.secondary)
                                            .frame(width: 58, alignment: .leading)
                                            .padding(.top, HIGSpacing.xs)

                                        // Reusable Timeline Card Component dengan Dukungan Edit saat Diketuk
                                        CartoonTimelineCard(
                                            title: item.title,
                                            timeText: item.timestamp.formatted(date: .omitted, time: .shortened),
                                            category: item.category,
                                            notes: item.notes,
                                            isCompleted: item.isCompleted,
                                            isRecurring: item.isRecurring,
                                            recurrenceTitle: item.recurrence.shortTitle,
                                            onToggle: { onToggleItem(item) },
                                            onDelete: { onDeleteItem(item) },
                                            onTap: { onEditItem(item) }
                                        )
                                    }
                                }
                            }

                            // ➕ Reusable Baris Input Cepat "Add new subtask"
                            CartoonQuickAddBar(timeLabel: a[0], text: $newSubtaskTitle) {
                                createQuickSubtask()
                            }
                            .focused($isQuickAddFocused)
                            .id("quickAddBar")
                        }
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    .padding(.top, HIGSpacing.xs)
                    .padding(.bottom, 100) // Ruang safe area bottom bar
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .onTapGesture {
                isQuickAddFocused = false
            }
            .sheet(isPresented: $isShowingAddActivity) {
                AddActivity()
            }
        }) : AnyView(EmptyView()) }
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
