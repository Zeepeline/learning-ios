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
    var onWeeklyReportTap: (() -> Void)? = nil

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            HStack {
                Text("Statistik Produktivitas")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Spacer()

                if let onWeeklyReportTap = onWeeklyReportTap {
                    Button {
                        HapticManager.shared.impact(style: .medium)
                        SoundManager.shared.playPop()
                        onWeeklyReportTap()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11, weight: .bold))
                            Text("Laporan AI")
                                .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.cartoonYellow)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))
                }
            }
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

            // Tombol Detail Laporan Mingguan
            if let onWeeklyReportTap = onWeeklyReportTap {
                Button {
                    HapticManager.shared.impact(style: .medium)
                    onWeeklyReportTap()
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                        Text("Lihat Infografik Laporan Mingguan AI")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.cartoonLavender)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))
                .padding(.top, 4)
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
                    .fill(bgColor)
                    .frame(width: 36, height: 36)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1.2))
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
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
}
