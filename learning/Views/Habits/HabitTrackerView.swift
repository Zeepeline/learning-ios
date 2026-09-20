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
    @Query(sort: \Item.timestamp, order: .forward) private var tasks: [Item]
    
    @State private var isShowingAddHabit: Bool = false
    @State private var isShowingRecommendationSheet: Bool = false
    @State private var habitToEdit: Habit?
    @State private var selectedCategory: String = "Semua"
    @State private var isFilterPanelExpanded: Bool = false
    @State private var habitToDelete: Habit?
    @State private var isShowingDeleteDialog: Bool = false
    @State private var celebrationHabit: Habit? = nil
    
    private let categoryItems: [(name: String, icon: String)] = [
        ("Semua", "square.grid.2x2.fill"),
        ("Kesehatan", "heart.fill"),
        ("Belajar", "book.fill"),
        ("Olahraga", "figure.run"),
        ("Mindfulness", "leaf.fill"),
        ("Produktivitas", "bolt.fill")
    ]
    private var categories: [String] { categoryItems.map { $0.name } }
    
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
                VStack(spacing: HIGSpacing.sm) {
                    // 1. Kartu Dashboard Ringkasan Kebiasaan Hari Ini
                    HabitDashboardSummaryCard(
                        totalHabits: habits.count,
                        completedCount: completedTodayCount,
                        percentage: todayCompletionPercentage,
                        maxStreak: maxStreak
                    )

                    // 2. ⚠️ AI Streak Risk Radar Banner (Jika ada streak berisiko)
                    if !habits.isEmpty {
                        CartoonHabitStreakRiskBanner(habits: habits) {
                            isShowingRecommendationSheet = true
                        }
                    }
                    
                    // 3. 🎛️ Bar Tombol Tambah Penuh + Tombol AI & Filter Neo-Brutalist
                    if !habits.isEmpty {
                        actionAndFilterHeader
                        
                        // Drawer Kategori Filter
                        if isFilterPanelExpanded {
                            filterDrawerSection
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Badge Filter Aktif (Jika Panel Tertutup)
                        if selectedCategory != "Semua" && !isFilterPanelExpanded {
                            activeFilterBadgeView
                        }
                    }
                    
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

            // 🎉 Fullscreen Confetti & Streak Celebration Modal
            if let celebration = celebrationHabit {
                ConfettiCelebrationView(
                    streakCount: celebration.currentStreak,
                    habitTitle: celebration.title,
                    onDismiss: {
                        celebrationHabit = nil
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
        .sheet(isPresented: $isShowingRecommendationSheet) {
            AIHabitRecommendationSheetView(habits: habits, tasks: tasks)
                .environment(\.modelContext, modelContext)
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
            let previousCompleted = habit.isCompletedToday
            habit.toggleCompletion()
            try? modelContext.save()
            if habit.isCompletedToday {
                SoundManager.shared.playTaskCompletedSound()
                // 🎉 Trigger Confetti Milestone Celebration jika streak mencapai milestone penting (misal: 3, 7, 14, 21, 30, dst.)
                if habit.currentStreak >= 3 && !previousCompleted && (habit.currentStreak % 3 == 0 || habit.currentStreak == 7 || habit.currentStreak == 14 || habit.currentStreak == 30) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        celebrationHabit = habit
                    }
                }
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

    // MARK: - 2. Bar Aksi Tambah Kebiasaan + Tombol AI & Filter Neo-Brutalist
    private var actionAndFilterHeader: some View {
        HStack(spacing: HIGSpacing.xs) {
            // Tombol Buat Kebiasaan Baru Penuh Kartun
            Button {
                HapticManager.shared.impact(style: .medium)
                selectedCategory = "Semua"
                isShowingAddHabit = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .black))
                    Text("Buat Kebiasaan")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cartoonYellow)
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                )
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.6))
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

            // Tombol AI Rutinitas 🪄
            Button {
                HapticManager.shared.impact(style: .medium)
                SoundManager.shared.playPop()
                isShowingRecommendationSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 13, weight: .black))
                    Text("AI")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(height: 44)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cartoonLavender)
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                )
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.6))
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

            // Tombol Filter Icon Neo-Brutalist
            Button {
                HapticManager.shared.impact(style: .light)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isFilterPanelExpanded.toggle()
                }
            } label: {
                ZStack(alignment: .topTrailing) {
                    HStack {
                        Image(systemName: isFilterPanelExpanded ? "line.3.horizontal.decrease.circle.fill" : "slider.horizontal.3")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedCategory != "Semua" ? Color.cartoonMint : (isFilterPanelExpanded ? Color.cartoonLavender : Color.white))
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 1.6)
                    )

                    // Dot penanda filter aktif
                    if selectedCategory != "Semua" {
                        Circle()
                            .fill(Color.cartoonCoral)
                            .frame(width: 9, height: 9)
                            .overlay(Circle().stroke(Color.black, lineWidth: 1.2))
                            .offset(x: 2, y: -2)
                    }
                }
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
        }
    }

    // MARK: - Drawer Kategori Filter
    private var filterDrawerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("FILTER KATEGORI")
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .foregroundColor(.secondary)

                Spacer()

                if selectedCategory != "Semua" {
                    Button {
                        HapticManager.shared.impact(style: .light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedCategory = "Semua"
                        }
                    } label: {
                        Text("Reset Filter")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Color.cartoonPink.opacity(0.8))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 0.8))
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.6))
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(categoryItems, id: \.name) { item in
                        let isSelected = selectedCategory == item.name
                        Button {
                            HapticManager.shared.selection()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                selectedCategory = item.name
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 11, weight: .bold))
                                Text(item.name)
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(isSelected ? Color.cartoonMint : Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: isSelected ? 1.5 : 1.0)
                            )
                            .shadow(color: .black, radius: 0, x: isSelected ? 1.5 : 0.5, y: isSelected ? 1.5 : 0.5)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.2))
        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
    }

    // MARK: - Badge Filter Aktif Ringkas
    private var activeFilterBadgeView: some View {
        HStack(spacing: 6) {
            Text("Filter Aktif:")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                Text(selectedCategory)
                    .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Button {
                    HapticManager.shared.impact(style: .light)
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        selectedCategory = "Semua"
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.black.opacity(0.6))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.cartoonMint)
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))

            Spacer()
        }
    }
}

// MARK: - 📊 Reusable Cartoon Habit Dashboard Summary Card
struct HabitDashboardSummaryCard: View {
    let totalHabits: Int
    let completedCount: Int
    let percentage: Int
    let maxStreak: Int

    var body: some View {
        HStack(spacing: 12) {
            // Circle Progress Meter
            ZStack {
                Circle()
                    .stroke(Color.black.opacity(0.12), lineWidth: 6)
                    .frame(width: 54, height: 54)

                Circle()
                    .trim(from: 0, to: totalHabits > 0 ? CGFloat(completedCount) / CGFloat(totalHabits) : 0)
                    .stroke(
                        Color.cartoonMint,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 54, height: 54)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: completedCount)

                VStack(spacing: 0) {
                    Text("\(percentage)%")
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundColor(.black)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Progres Kebiasaan Hari Ini")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Text("\(completedCount) dari \(totalHabits) selesai diceklis")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Streak Badge
            VStack(spacing: 1) {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                    Text("\(maxStreak)")
                        .font(.system(size: 15, weight: .heavy, design: .monospaced))
                        .foregroundColor(.black)
                }
                Text("Max Streak")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.cartoonYellow)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
            .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }
}

// MARK: - 📭 Reusable Cartoon Habit Empty State View
struct HabitEmptyStateView: View {
    let onAddHabit: () -> Void

    var body: some View {
        VStack(spacing: HIGSpacing.sm) {
            Image(systemName: "flame.circle.fill")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.cartoonYellow)
                .padding(.top, HIGSpacing.lg)

            Text("Belum Ada Kebiasaan")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.black)

            Text("Mulai bangun rutinitas positif harianmu dengan menambahkan kebiasaan baru atau manfaatkan rekomendasi AI!")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, HIGSpacing.xl)

            Button {
                HapticManager.shared.impact(style: .medium)
                onAddHabit()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Tambah Kebiasaan Pertama")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.cartoonYellow)
                .cornerRadius(CartoonMetrics.cardCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                        .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                )
                .shadow(color: .black, radius: 0, x: 2, y: 2)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            .padding(.top, HIGSpacing.xs)
            .padding(.bottom, HIGSpacing.lg)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }
}
