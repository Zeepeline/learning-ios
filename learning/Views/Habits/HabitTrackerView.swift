//
//  HabitTrackerView.swift
//  learning
//
//  Created by macbook on 9/6/26.
//

import SwiftUI
import SwiftData
import WidgetKit

struct HabitTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    
    @State private var isShowingAddHabit: Bool = false
    @State private var habitToEdit: Habit?
    @State private var selectedCategory: String = "Semua"
    @State private var habitToDelete: Habit?
    @State private var isShowingDeleteDialog: Bool = false
    
    private let categories: [String] = ["Semua", "Kesehatan", "Belajar", "Olahraga", "Mindfulness", "Produktivitas"]
    
    private var filteredHabits: [Habit] {
        if selectedCategory == "Semua" {
            return habits
        }
        return habits.filter { $0.category == selectedCategory }
    }
    
    // Live Stats
    private var completedTodayCount: Int {
        habits.filter { $0.isCompletedToday }.count
    }
    
    private var todayCompletionPercentage: Int {
        guard !habits.isEmpty else { return 0 }
        return Int((Double(completedTodayCount) / Double(habits.count)) * 100)
    }
    
    private var maxStreak: Int {
        habits.map { $0.currentStreak }.max() ?? 0
    }
    
    dynamic var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: HIGSpacing.md) {
                    // 1. Kartu Dashboard Ringkasan Kebiasaan Hari Ini
                    HabitDashboardSummaryCard(
                        totalHabits: habits.count,
                        completedCount: completedTodayCount,
                        percentage: todayCompletionPercentage,
                        maxStreak: maxStreak
                    )
                    
                    // 2. Filter Kategori Kartun
                    if !habits.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { category in
                                    let isSelected = selectedCategory == category
                                    Button {
                                        HapticManager.shared.selection()
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                            selectedCategory = category
                                        }
                                    } label: {
                                        Text(category)
                                            .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(isSelected ? Color.cartoonYellow : Color.white)
                                                    .shadow(color: .black, radius: 0, x: isSelected ? 1.5 : 1, y: isSelected ? 1.5 : 1)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.black, lineWidth: isSelected ? 1.5 : 1.0)
                                            )
                                    }
                                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                                }
                            }
                            .padding(.horizontal, HIGSpacing.md)
                        }
                        .padding(.horizontal, -HIGSpacing.md)
                    }
                    
                    // 3. Tombol Tambah Kebiasaan Cepat
                    Button {
                        HapticManager.shared.impact(style: .medium)
                        selectedCategory = "Semua"
                        isShowingAddHabit = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14, weight: .black))
                            Text("Buat Kebiasaan Baru")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.cartoonYellow)
                                .shadow(color: .black, radius: 0, x: 2, y: 2)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.6))
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    
                    // 4. Daftar Kartu Kebiasaan (Habits List dengan LazyVStack untuk 120fps)
                    if filteredHabits.isEmpty {
                        HabitEmptyStateView {
                            selectedCategory = "Semua"
                            isShowingAddHabit = true
                        }
                    } else {
                        LazyVStack(spacing: HIGSpacing.sm) {
                            ForEach(filteredHabits) { habit in
                                HabitCardView(
                                    habit: habit,
                                    onToggleToday: {
                                        toggleHabit(habit)
                                    },
                                    onToggleDate: { date in
                                        toggleHabitDate(habit, date: date)
                                    },
                                    onEdit: {
                                        habitToEdit = habit
                                    },
                                    onDelete: {
                                        habitToDelete = habit
                                        isShowingDeleteDialog = true
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, HIGSpacing.md)
                .padding(.top, HIGSpacing.xxs)
                .padding(.bottom, 110)
            }
            
            // Dialog Konfirmasi Hapus Kebiasaan
            if isShowingDeleteDialog, let habit = habitToDelete {
                CartoonConfirmDialog(
                    title: "Hapus Kebiasaan?",
                    message: "Apakah kamu yakin ingin menghapus kebiasaan\n\"\(habit.title)\"?",
                    onCancel: {
                        HapticManager.shared.impact(style: .light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            isShowingDeleteDialog = false
                            habitToDelete = nil
                        }
                    },
                    onConfirm: {
                        deleteHabit(habit)
                    }
                )
            }
        }
        .sheet(isPresented: $isShowingAddHabit) {
            AddHabitView()
                .environment(\.modelContext, modelContext)
                .presentationDetents([.fraction(0.88), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(22)
        }
        .sheet(item: $habitToEdit) { habit in
            EditHabitView(
                habit: habit,
                onDelete: {
                    habitToDelete = habit
                    isShowingDeleteDialog = true
                }
            )
            .environment(\.modelContext, modelContext)
            .presentationDetents([.fraction(0.88), .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(22)
        }
        .task {
            // Sinkronisasi otomatis kebiasaan berdasarkan data Apple Health / Zepp
            if HealthKitManager.shared.isAuthorized {
                await HealthKitManager.shared.fetchAllTodayHealthData()
                autoSyncHealthHabits()
            }
        }
    }
    
    // MARK: - 🔄 Auto-Sync Kebiasaan dengan Data Apple Health / Smartwatch
    private func autoSyncHealthHabits() {
        let summary = HealthKitManager.shared.todaySummary
        var didChange = false
        
        for habit in habits {
            let lowerTitle = habit.title.lowercased()
            let lowerCategory = habit.category.lowercased()
            
            // 1. Cek Sesi Workout / Lari (misal dari Zepp / Apple Watch)
            if !summary.recentWorkouts.isEmpty {
                if lowerTitle.contains("lari") || lowerTitle.contains("jogging") || lowerTitle.contains("olahraga") || lowerTitle.contains("workout") || lowerCategory.contains("olahraga") {
                    if !habit.isCompletedToday {
                        habit.toggleCompletion(on: Date())
                        didChange = true
                    }
                }
            }
            
            // 2. Cek Langkah Harian (Steps >= 5000)
            if summary.steps >= 5000 {
                if lowerTitle.contains("langkah") || lowerTitle.contains("jalan") || lowerTitle.contains("step") {
                    if !habit.isCompletedToday {
                        habit.toggleCompletion(on: Date())
                        didChange = true
                    }
                }
            }
            
            // 3. Cek Tidur Nyenyak (Sleep >= 6 jam)
            if summary.sleepDurationHours >= 6.0 {
                if lowerTitle.contains("tidur") || lowerTitle.contains("sleep") || lowerTitle.contains("istirahat") {
                    if !habit.isCompletedToday {
                        habit.toggleCompletion(on: Date())
                        didChange = true
                    }
                }
            }
        }
        
        if didChange {
            try? modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    private func toggleHabit(_ habit: Habit) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
            habit.toggleCompletion()
            try? modelContext.save()
            if habit.isCompletedToday {
                SoundManager.shared.playTaskCompletedSound()
            } else {
                HapticManager.shared.impact(style: .medium)
            }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    private func toggleHabitDate(_ habit: Habit, date: Date) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
            habit.toggleCompletion(on: date)
            try? modelContext.save()
            HapticManager.shared.impact(style: .light)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    private func deleteHabit(_ habit: Habit) {
        HapticManager.shared.warning()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            modelContext.delete(habit)
            try? modelContext.save()
            isShowingDeleteDialog = false
            habitToDelete = nil
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

// MARK: - 1. Dashboard Ringkasan Kebiasaan
struct HabitDashboardSummaryCard: View {
    let totalHabits: Int
    let completedCount: Int
    let percentage: Int
    let maxStreak: Int
    
    dynamic var body: some View {
        HStack(spacing: 12) {
            // Lingkaran Progress Persentase
            ZStack {
                Circle()
                    .stroke(Color.black, lineWidth: 7)
                    .frame(width: 58, height: 58)
                
                Circle()
                    .stroke(Color(red: 0.90, green: 0.90, blue: 0.92), lineWidth: 4.5)
                    .frame(width: 58, height: 58)
                
                Circle()
                    .trim(from: 0, to: CGFloat(percentage) / 100.0)
                    .stroke(
                        Color.cartoonMint,
                        style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 58, height: 58)
                
                Text("\(percentage)%")
                    .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Target Kebiasaan Hari Ini")
                    .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                
                Text("\(completedCount) dari \(totalHabits) kebiasaan telah selesai")
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Streak Terpanjang
            VStack(spacing: 2) {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(Color.cartoonOrange)
                    Text("\(maxStreak)")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
                
                Text("Hari Streak")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.98, green: 0.94, blue: 0.88))
            )
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.1))
        }
        .padding(HIGSpacing.md)
        .cartoonCard()
    }
}

// MARK: - 2. Tampilan Empty State Kebiasaan
struct HabitEmptyStateView: View {
    var onAddHabit: () -> Void
    
    dynamic var body: some View {
        VStack(spacing: HIGSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.cartoonYellow)
                    .frame(width: 64, height: 64)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
            }
            .padding(.top, HIGSpacing.md)
            
            VStack(spacing: HIGSpacing.xxs) {
                Text("Belum Ada Kebiasaan")
                    .font(.system(size: 16.5, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                
                Text("Mulai bangun rutinitas positif harianmu sekarang!")
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                HapticManager.shared.impact(style: .medium)
                onAddHabit()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("Buat Kebiasaan Pertama")
                        .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black)
                .padding(.horizontal, HIGSpacing.lg)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cartoonMint)
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                )
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.8))
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HIGSpacing.lg)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = (try? ModelContainer(for: Habit.self, configurations: config)) ?? {
        fatalError("Failed to create preview container")
    }()
    
    let sampleHabits = [
        Habit(title: "Lari Pagi 20 Menit", icon: "figure.run", colorHex: "#FF6B6B", category: "Olahraga", targetFrequency: "Harian", completedDates: [Date()]),
        Habit(title: "Minum Air 2 Liter", icon: "drop.fill", colorHex: "#4ECDC4", category: "Kesehatan", targetFrequency: "Harian", completedDates: []),
        Habit(title: "Belajar Swift 30 Menit", icon: "swift", colorHex: "#FFD166", category: "Belajar", targetFrequency: "Hari Kerja", completedDates: [])
    ]
    for habit in sampleHabits {
        container.mainContext.insert(habit)
    }
    
    return HabitTrackerView()
        .modelContainer(container)
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
// HabitTrackerView: helper methods kept here — its body reads private member(s): autoSyncHealthHabits, categories, completedTodayCount, deleteHabit, filteredHabits, habitToDelete, habitToEdit, habits, isShowingAddHabit, isShowingDeleteDialog, maxStreak, modelContext, selectedCategory, todayCompletionPercentage, toggleHabit, toggleHabitDate.
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

extension HabitTrackerView {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_45e5c968f26461f6"] = { (a: [String]) in a.count >= 3 ? AnyView(ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: HIGSpacing.md) {
                    // 1. Kartu Dashboard Ringkasan Kebiasaan Hari Ini
                    HabitDashboardSummaryCard(
                        totalHabits: habits.count,
                        completedCount: completedTodayCount,
                        percentage: todayCompletionPercentage,
                        maxStreak: maxStreak
                    )
                    
                    // 2. Filter Kategori Kartun
                    if !habits.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { category in
                                    let isSelected = selectedCategory == category
                                    Button {
                                        HapticManager.shared.selection()
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                            selectedCategory = category
                                        }
                                    } label: {
                                        Text(category)
                                            .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(isSelected ? Color.cartoonYellow : Color.white)
                                                    .shadow(color: .black, radius: 0, x: isSelected ? 1.5 : 1, y: isSelected ? 1.5 : 1)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.black, lineWidth: isSelected ? 1.5 : 1.0)
                                            )
                                    }
                                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                                }
                            }
                            .padding(.horizontal, HIGSpacing.md)
                        }
                        .padding(.horizontal, -HIGSpacing.md)
                    }
                    
                    // 3. Tombol Tambah Kebiasaan Cepat
                    Button {
                        HapticManager.shared.impact(style: .medium)
                        selectedCategory = "Semua"
                        isShowingAddHabit = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: a[0])
                                .font(.system(size: 14, weight: .black))
                            Text(LocalizedStringKey(a[1]))
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.cartoonYellow)
                                .shadow(color: .black, radius: 0, x: 2, y: 2)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.6))
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    
                    // 4. Daftar Kartu Kebiasaan (Habits List dengan LazyVStack untuk 120fps)
                    if filteredHabits.isEmpty {
                        HabitEmptyStateView {
                            selectedCategory = "Semua"
                            isShowingAddHabit = true
                        }
                    } else {
                        LazyVStack(spacing: HIGSpacing.sm) {
                            ForEach(filteredHabits) { habit in
                                HabitCardView(
                                    habit: habit,
                                    onToggleToday: {
                                        toggleHabit(habit)
                                    },
                                    onToggleDate: { date in
                                        toggleHabitDate(habit, date: date)
                                    },
                                    onEdit: {
                                        habitToEdit = habit
                                    },
                                    onDelete: {
                                        habitToDelete = habit
                                        isShowingDeleteDialog = true
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, HIGSpacing.md)
                .padding(.top, HIGSpacing.xxs)
                .padding(.bottom, 110)
            }
            
            // Dialog Konfirmasi Hapus Kebiasaan
            if isShowingDeleteDialog, let habit = habitToDelete {
                CartoonConfirmDialog(
                    title: a[2],
                    message: "Apakah kamu yakin ingin menghapus kebiasaan\n\"\(habit.title)\"?",
                    onCancel: {
                        HapticManager.shared.impact(style: .light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            isShowingDeleteDialog = false
                            habitToDelete = nil
                        }
                    },
                    onConfirm: {
                        deleteHabit(habit)
                    }
                )
            }
        }
        .sheet(isPresented: $isShowingAddHabit) {
            AddHabitView()
                .environment(\.modelContext, modelContext)
                .presentationDetents([.fraction(0.88), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(22)
        }
        .sheet(item: $habitToEdit) { habit in
            EditHabitView(
                habit: habit,
                onDelete: {
                    habitToDelete = habit
                    isShowingDeleteDialog = true
                }
            )
            .environment(\.modelContext, modelContext)
            .presentationDetents([.fraction(0.88), .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(22)
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
        var __r: [String: PatchRowSlot] = [:]
        __r["rf_fd588088231721e5"] = { () -> PatchRowSlot in
            let __coll = filteredHabits
            return PatchRowSlot(count: __coll.count) { (__i: Int) in
                guard __i >= 0, __i < __coll.count else { return AnyView(EmptyView()) }
                let habit = __coll[__coll.index(__coll.startIndex, offsetBy: __i)]
                return AnyView(HabitCardView(
                                    habit: habit,
                                    onToggleToday: {
                                        toggleHabit(habit)
                                    },
                                    onToggleDate: { date in
                                        toggleHabitDate(habit, date: date)
                                    },
                                    onEdit: {
                                        habitToEdit = habit
                                    },
                                    onDelete: {
                                        habitToDelete = habit
                                        isShowingDeleteDialog = true
                                    }
                                ))
            }
        }()
        return __r
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
        __e["eff940a4732c0269e5e"] = { (content: AnyView) -> AnyView in AnyView(content.task {
            // Sinkronisasi otomatis kebiasaan berdasarkan data Apple Health / Zepp
            if HealthKitManager.shared.isAuthorized {
                await HealthKitManager.shared.fetchAllTodayHealthData()
                autoSyncHealthHabits()
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
