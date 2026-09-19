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
    
    @State private var isMonthlyHeatmapExpanded: Bool = false
    private let calendar = Calendar.current
    
    // 7 hari terakhir (dari 6 hari lalu sampai hari ini)
    private var last7Days: [Date] {
        (0..<7).compactMap { i in
            calendar.date(byAdding: .day, value: -(6 - i), to: Date())
        }
    }

    // Hari dalam bulan berjalan
    private var daysInCurrentMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: Date()),
              let monthRange = calendar.range(of: .day, in: .month, for: Date()) else { return [] }
        return monthRange.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start)
        }
    }

    private var currentMonthName: String {
        Date().formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "id_ID")))
    }

    private var monthlyCompletedCount: Int {
        daysInCurrentMonth.filter { habit.isCompleted(on: $0) }.count
    }
    
    private func dayName(for date: Date) -> String {
        let weekday = calendar.component(.weekday, from: date)
        switch weekday {
        case 1: return "Min"
        case 2: return "Sen"
        case 3: return "Sel"
        case 4: return "Rab"
        case 5: return "Kam"
        case 6: return "Jum"
        case 7: return "Sab"
        default: return ""
        }
    }
    
    dynamic var body: some View {
        VStack(spacing: HIGSpacing.sm) {
            // MARK: - 1. Header Bar: Icon + Title/Category/Streak + Big Checkmark Button
            HStack(spacing: HIGSpacing.sm) {
                // Icon Bulat Kartun
                Button {
                    HapticManager.shared.impact(style: .light)
                    onEdit()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(habit.color)
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                            .frame(width: 42, height: 42)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.6))
                        
                        Image(systemName: habit.icon)
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.black)
                    }
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                
                // Judul & Kategori & Streak
                Button {
                    HapticManager.shared.impact(style: .light)
                    onEdit()
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(habit.title)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                            .lineLimit(1)
                        
                        HStack(spacing: 6) {
                            // Category Badge
                            Text(habit.category)
                                .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.cartoonBg)
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 0.9))
                            
                            // Streak Counter Badge
                            HStack(spacing: 3) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.orange)
                                
                                Text("\(habit.currentStreak) Hari")
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .foregroundColor(.black)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.cartoonYellow.opacity(0.35))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 0.9))
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Tombol Checklist Hari Ini (Ukuran Standar HIG Touch Target)
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
                                .fill(Color.gray.opacity(0.25))
                                .frame(width: 10, height: 10)
                        }
                    }
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
            
            // MARK: - 2. Clean & Minimalist 7-Day Mini Tracker
            mini7DayTrackerSection
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

    // MARK: - Clean 7-Day Mini Tracker Subview
    private var mini7DayTrackerSection: some View {
        VStack(spacing: 8) {
            // Header Mini Tracker
            HStack {
                Text("7 HARI TERAKHIR")
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .foregroundColor(.secondary)
                
                // Consistency Rate Pill
                let rate = Int(habit.weeklyCompletionRate * 100)
                Text("\(rate)%")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 5.5)
                    .padding(.vertical, 1.5)
                    .background(rate >= 70 ? Color.cartoonMint : Color.cartoonYellow)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.black, lineWidth: 0.8))

                Spacer()
                
                // Tombol Heatmap Bulanan Minimalis
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        isMonthlyHeatmapExpanded.toggle()
                        HapticManager.shared.selection()
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: isMonthlyHeatmapExpanded ? "chevron.up" : "calendar")
                            .font(.system(size: 9, weight: .bold))
                        Text(isMonthlyHeatmapExpanded ? "Tutup" : "Heatmap")
                            .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.white)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 0.9))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.6))
            }
            
            // 7 Clean Day Capsules Bar
            HStack(spacing: 0) {
                ForEach(last7Days, id: \.self) { date in
                    let isCompleted = habit.isCompleted(on: date)
                    let isToday = calendar.isDateInToday(date)
                    
                    Button {
                        onToggleDate(date)
                    } label: {
                        VStack(spacing: 4) {
                            Text(dayName(for: date))
                                .font(.system(size: 9, weight: isToday ? .heavy : .semibold, design: .rounded))
                                .foregroundColor(isToday ? .black : .secondary)
                            
                            ZStack {
                                Circle()
                                    .fill(isCompleted ? habit.color : (isToday ? Color.white : Color(red: 0.94, green: 0.94, blue: 0.96)))
                                    .frame(width: 26, height: 26)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black, lineWidth: isToday ? 1.6 : (isCompleted ? 1.2 : 0.6))
                                    )
                                    .shadow(color: isToday ? .black.opacity(0.15) : .clear, radius: 0, x: 1, y: 1)
                                
                                if isCompleted {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(.black)
                                } else if isToday {
                                    Circle()
                                        .fill(Color.black.opacity(0.3))
                                        .frame(width: 5, height: 5)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))
                }
            }

            // Expanded Monthly Heatmap
            if isMonthlyHeatmapExpanded {
                monthlyHeatmapMatrix
            }
        }
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.98, green: 0.98, blue: 0.99))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.25), lineWidth: 1.0)
        )
    }

    // MARK: - Monthly Heatmap Matrix Subview
    private var monthlyHeatmapMatrix: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
                .background(Color.black.opacity(0.15))
                .padding(.vertical, 2)

            HStack {
                Text("Heatmap \(currentMonthName)")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Spacer()

                Text("\(monthlyCompletedCount) Hari Selesai")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(daysInCurrentMonth, id: \.self) { date in
                    let isCompleted = habit.isCompleted(on: date)
                    let dayNumber = calendar.component(.day, from: date)
                    let isToday = calendar.isDateInToday(date)

                    Button {
                        onToggleDate(date)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(isCompleted ? habit.color : Color.white)
                                .frame(height: 22)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.black, lineWidth: isToday ? 1.4 : 0.6)
                                )

                            Text("\(dayNumber)")
                                .font(.system(size: 8.5, weight: isCompleted || isToday ? .heavy : .medium, design: .rounded))
                                .foregroundColor(.black)
                        }
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.6))
                }
            }
        }
        .padding(6)
        .background(Color.white.opacity(0.9))
        .cornerRadius(8)
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }
}
