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
    
    var body: some View {
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
                                ForEach(categories, id: \.self) { cat in
                                    let isSelected = selectedCategory == cat
                                    Button {
                                        HapticManager.shared.selection()
                                        selectedCategory = cat
                                    } label: {
                                        Text(cat)
                                            .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6.5)
                                            .background(isSelected ? Color.cartoonYellow : Color.white)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.black, lineWidth: isSelected ? 1.8 : 1.1)
                                            )
                                            .shadow(color: .black, radius: 0, x: isSelected ? 1.5 : 1, y: isSelected ? 1.5 : 1)
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
                        .background(Color.cartoonYellow)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.6))
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
                    
                    // 4. Daftar Kartu Kebiasaan (Habits List)
                    if filteredHabits.isEmpty {
                        HabitEmptyStateView {
                            isShowingAddHabit = true
                        }
                    } else {
                        VStack(spacing: HIGSpacing.sm) {
                            ForEach(filteredHabits) { habit in
                                HabitCardView(
                                    habit: habit,
                                    onToggleToday: {
                                        toggleHabit(habit)
                                    },
                                    onToggleDate: { date in
                                        toggleHabitDate(habit, date: date)
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
                .presentationDetents([.fraction(0.88), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(22)
        }
    }
    
    private func toggleHabit(_ habit: Habit) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
            habit.toggleCompletion()
            try? modelContext.save()
            if habit.isCompletedToday {
                HapticManager.shared.success()
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
    
    var body: some View {
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
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("KEBIASAAN HARI INI")
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .foregroundColor(.secondary)
                
                Text("\(completedCount) dari \(totalHabits) Selesai")
                    .font(.system(size: 14.5, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                
                // Max Streak Badge
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.orange)
                    
                    Text("Streak Tertinggi: \(maxStreak) Hari berturut-turut")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.black.opacity(0.8))
                }
            }
            
            Spacer()
        }
        .padding(HIGSpacing.md)
        .cartoonCard()
    }
}

// MARK: - 2. Empty State View
struct HabitEmptyStateView: View {
    let onAddTap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.cartoonPink.opacity(0.4))
                    .frame(width: 60, height: 60)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
            }
            
            VStack(spacing: 3) {
                Text("Belum Ada Kebiasaan")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                
                Text("Bangun kebiasaan positif setiap hari untuk tingkatkan produktivitas!")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            Button {
                onAddTap()
            } label: {
                Text("Mulai Buat Kebiasaan")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.cartoonYellow)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.3))
                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .cartoonCard()
    }
}

#Preview {
    HabitTrackerView()
        .modelContainer(for: Habit.self, inMemory: true)
}
