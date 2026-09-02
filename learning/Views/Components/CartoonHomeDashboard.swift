//
//  CartoonHomeDashboard.swift
//  learning
//
//  Created by macbook on 9/1/26.
//

import SwiftUI

// MARK: - 🌟 1. Banner Progress & Sapaan Kartun (HIG Glanceability)
struct CartoonProgressBanner: View {
    let userName: String
    let completedCount: Int
    let totalCount: Int

    private var progressRatio: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    private var progressPercentage: Int {
        Int(progressRatio * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            // Header Sapaan & Badge Streak
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Halo, \(userName)")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)

                    Text(motivationalSubtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Badge Streak Kartun
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 14))
                    Text("3 Hari")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.cartoonYellow)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 1.6)
                )
                .shadow(color: .black, radius: 0, x: 2, y: 2)
            }

            // Progress Bar Kartun Neo-Brutalist
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Progres Tugas")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.black)

                    Spacer()

                    Text("\(completedCount)/\(totalCount) Selesai (\(progressPercentage)%)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.cartoonCoral)
                }

                // Bar Fisik
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(red: 0.93, green: 0.93, blue: 0.95))
                            .frame(height: 14)
                            .overlay(Capsule().stroke(Color.black, lineWidth: 1.6))

                        Capsule()
                            .fill(Color.cartoonMint)
                            .frame(width: max(geo.size.width * CGFloat(progressRatio), (progressRatio > 0 ? 14 : 0)), height: 14)
                            .overlay(Capsule().stroke(Color.black, lineWidth: 1.6))
                            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: progressRatio)
                    }
                }
                .frame(height: 14)
            }
            .padding(.top, HIGSpacing.xxs)
        }
        .padding(HIGSpacing.md)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
    }

    private var motivationalSubtitle: String {
        if totalCount == 0 {
            return "Mulai hari ini dengan membuat tugas baru!"
        } else if completedCount == totalCount {
            return "Luar biasa! Semua tugas selesai! 🎉"
        } else {
            return "Yuk selesaikan \(totalCount - completedCount) tugas lagi hari ini!"
        }
    }
}

// MARK: - 📊 2. Kartu Mini Statistik Ringkasan (3 Kolom Horisontal)
struct CartoonStatCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 26, height: 26)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.4))

                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.black)
                }

                Spacer()

                Text("\(count)")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
            }

            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black, lineWidth: 1.6)
        )
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }
}

// MARK: - 🔍 3. Search Bar Kartun Neo-Brutalist (HIG Search Standards)
struct CartoonSearchBar: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: HIGSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.black)

            TextField("Cari tugas atau catatan...", text: $searchText)
                .font(.system(size: 13, weight: .medium, design: .rounded))

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    HapticManager.shared.impact(style: .light)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, HIGSpacing.md)
        .frame(height: 44)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black, lineWidth: 1.6)
        )
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }
}

// MARK: - 🏷️ 4. Horizontal Filter Segment Chips (HIG Filtering)
struct CartoonFilterStrip: View {
    @Binding var selectedFilter: String
    let filters: [(id: String, label: String, icon: String)]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: HIGSpacing.xs) {
                ForEach(filters, id: \.id) { filter in
                    let isSelected = selectedFilter == filter.id

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedFilter = filter.id
                            HapticManager.shared.selection()
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: filter.icon)
                                .font(.system(size: 10, weight: .bold))

                            Text(filter.label)
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.cartoonCoral : Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: isSelected ? 2.0 : 1.4)
                        )
                        .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                        .scaleEffect(isSelected ? 1.03 : 1.0)
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
    }
}

// MARK: - ✨ 5. Template Cepat untuk Zero-State (HIG Onboarding)
struct CartoonQuickTemplateCard: View {
    let title: String
    let category: String
    let icon: String
    let color: Color
    let onAdd: () -> Void

    var body: some View {
        Button {
            onAdd()
        } label: {
            HStack(spacing: HIGSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.6))

                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(.black)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)

                    Text(category)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(Color.cartoonCoral)
            }
            .padding(HIGSpacing.sm)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: 1.5)
            )
            .shadow(color: .black, radius: 0, x: 2, y: 2)
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
    }
}
