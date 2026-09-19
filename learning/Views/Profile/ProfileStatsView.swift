//
//  ProfileStatsView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI
import Charts

// MARK: - Model Data Mingguan
struct DailyCompletionStat: Identifiable {
    let id = UUID()
    let dayName: String
    let completedCount: Int
    let isToday: Bool
}

struct ProfileStatsView: View {
    let completedTasksCount: Int
    let allItemsCount: Int
    let importantCompletedCount: Int
    var maxHabitStreak: Int = 0
    var weeklyStats: [DailyCompletionStat] = []

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            Text("Statistik Produktivitas")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, HIGSpacing.md)

            // 1. Grid 2x2 Mini Stat Cards
            HStack(spacing: HIGSpacing.sm) {
                ProfileStatCard(
                    icon: "checkmark.circle.fill",
                    title: "Selesai",
                    value: "\(completedTasksCount)",
                    bgColor: .cartoonMint
                )
                ProfileStatCard(
                    icon: "flame.fill",
                    title: "Streak Kebiasaan",
                    value: "\(maxHabitStreak) Hari",
                    bgColor: .cartoonOrange,
                    iconColor: .red
                )
            }
            .padding(.horizontal, HIGSpacing.md)

            HStack(spacing: HIGSpacing.sm) {
                ProfileStatCard(
                    icon: "list.clipboard.fill",
                    title: "Total Tugas",
                    value: "\(allItemsCount)",
                    bgColor: .cartoonYellow
                )
                ProfileStatCard(
                    icon: "star.fill",
                    title: "Penting Selesai",
                    value: "\(importantCompletedCount)",
                    bgColor: .cartoonBlue,
                    iconColor: .orange
                )
            }
            .padding(.horizontal, HIGSpacing.md)

            // 2. 📊 Weekly Productivity Bar Chart (Apple Charts Neo-Brutalist)
            weeklyActivityChartCard
                .padding(.horizontal, HIGSpacing.md)
                .padding(.top, HIGSpacing.xxs)
        }
    }

    // MARK: - 📊 Weekly Productivity Chart Component
    private var weeklyActivityChartCard: some View {
        let maxCount = weeklyStats.map { $0.completedCount }.max() ?? 0
        let totalDone = weeklyStats.map { $0.completedCount }.reduce(0, +)
        let yDomainMax = max(maxCount + 1, 4)

        return VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                    Text("Aktivitas 7 Hari Terakhir")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }

                Spacer()

                Text("\(totalDone) Selesai")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.cartoonMint)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
            }

            if #available(iOS 16.0, *) {
                Chart(weeklyStats) { stat in
                    BarMark(
                        x: .value("Hari", stat.dayName),
                        y: .value("Jumlah Selesai", stat.completedCount)
                    )
                    .foregroundStyle(stat.isToday ? Color.cartoonCoral : Color.cartoonMint)
                    .cornerRadius(6)
                    .annotation(position: .top, spacing: 3) {
                        if stat.completedCount > 0 {
                            Text("\(stat.completedCount)")
                                .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                        }
                    }
                }
                .frame(height: 130)
                .chartYScale(domain: 0...yDomainMax)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(Color.black.opacity(0.12))
                        AxisValueLabel {
                            if let intVal = value.as(Int.self) {
                                Text("\(intVal)")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.black.opacity(0.6))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.black)
                    }
                }
            } else {
                Text("Chart membutuhkan iOS 16+")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(HIGSpacing.md)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }
}

// MARK: - Komponen Kartu Statistik Mini
struct ProfileStatCard: View {
    let icon: String
    let title: String
    let value: String
    let bgColor: Color
    var iconColor: Color = .black

    dynamic var body: some View {
        HStack(spacing: HIGSpacing.xs) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, HIGSpacing.md)
        .padding(.vertical, 10)
        .background(bgColor)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }
}
