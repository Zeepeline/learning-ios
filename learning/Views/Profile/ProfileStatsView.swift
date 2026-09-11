//
//  ProfileStatsView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI

struct ProfileStatsView: View {
    let completedTasksCount: Int
    let allItemsCount: Int
    let importantCompletedCount: Int
    var maxHabitStreak: Int = 0

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.xs) {
            Text("Statistik Produktivitas")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, HIGSpacing.md)

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
        }
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
