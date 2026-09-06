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
    let onDelete: () -> Void
    
    private let calendar = Calendar.current
    
    // 7 hari terakhir (dari 6 hari lalu sampai hari ini)
    private var last7Days: [Date] {
        (0..<7).compactMap { i in
            calendar.date(byAdding: .day, value: -(6 - i), to: Date())
        }
    }
    
    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header: Icon + Info + Current Streak Badge + Tombol Checklist Hari Ini
            HStack(spacing: 10) {
                // Icon Bulat Kartun dengan Warna Habit
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
                
                // Judul & Kategori
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.title)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text(habit.category)
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
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
        onDelete: {}
    )
}
