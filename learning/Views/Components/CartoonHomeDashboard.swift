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

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            // Header Sapaan & Badge Streak
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Halo, \(userName)")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)

                    Text(motivationalSubtitle)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color.black.opacity(0.8))
                }

                Spacer()

                // Badge Streak Kartun
                HStack(spacing: 4) {
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
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
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
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }

    private var motivationalSubtitle: String {
        if totalCount == 0 {
            return "Mulai hari ini dengan membuat tugas baru!"
        } else if completedCount == totalCount {
            return "Luar biasa! Semua tugas selesai!"
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

    dynamic var body: some View {
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
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(Color.black.opacity(0.85))
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }
}

// MARK: - 🔍 3. Search & Filter Bar Kartun
struct CartoonSearchFilterBar: View {
    @Binding var searchText: String
    var onFilterTap: () -> Void

    dynamic var body: some View {
        HStack(spacing: HIGSpacing.xs) {
            HStack(spacing: HIGSpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)

                TextField("Cari aktivitas...", text: $searchText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.black)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        HapticManager.shared.selection()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
            )
            .shadow(color: .black, radius: 0, x: 2, y: 2)

            Button {
                onFilterTap()
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44)
                    .background(Color.cartoonYellow)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                    )
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
        }
    }
}

// MARK: - 🔍 4. Reusable Cartoon Search Bar
struct CartoonSearchBar: View {
    @Binding var searchText: String

    dynamic var body: some View {
        HStack(spacing: HIGSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.black)

            TextField("Cari tugas atau catatan...", text: $searchText)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.black)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    HapticManager.shared.impact(style: .light)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
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
