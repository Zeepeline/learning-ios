//
//  AIHabitRecommendationSheetView.swift
//  learning
//
//  Created by macbook on 9/20/26.
//

import SwiftUI
import SwiftData
import WidgetKit

struct AIHabitRecommendationSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let habits: [Habit]
    let tasks: [Item]

    @State private var recommendations: [AIHabitRecommendation] = []
    @State private var streakRisks: [HabitStreakRiskItem] = []
    @State private var adoptedHabitsCount: Int = 0
    @State private var selectedTab: Int = 0 // 0: Rekomendasi Baru, 1: Streak Risk Radar

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cartoonBg
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: HIGSpacing.md) {
                        // 1. Header Hero Card
                        heroHeaderCard

                        // 2. Segmented Mode Selector
                        segmentedTabSelector

                        // 3. Dynamic Section Content
                        if selectedTab == 0 {
                            recommendationsSection
                        } else {
                            streakRisksSection
                        }
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    .padding(.top, HIGSpacing.xs)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("AI Habit Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CartoonIconButton(icon: "xmark") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadData()
            }
        }
    }

    // MARK: - Header Hero Card
    private var heroHeaderCard: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.cartoonYellow)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1.8))
                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)

                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.black)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("AI Routine & Streak Coach")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Text("AI memprediksi risiko streak kebiasaanmu dan merekomendasikan rutinitas positif untuk melengkapi harimu.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
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

    // MARK: - Segmented Tab Selector
    private var segmentedTabSelector: some View {
        HStack(spacing: 8) {
            Button {
                HapticManager.shared.selection()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                    selectedTab = 0
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 12, weight: .bold))
                    Text("Rekomendasi (\(recommendations.count))")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedTab == 0 ? Color.cartoonLavender : Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: selectedTab == 0 ? 1.6 : 1.0))
                .shadow(color: .black, radius: 0, x: selectedTab == 0 ? 1.5 : 0.5, y: selectedTab == 0 ? 1.5 : 0.5)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))

            Button {
                HapticManager.shared.selection()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                    selectedTab = 1
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("Radar Streak (\(streakRisks.count))")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedTab == 1 ? Color.cartoonCoral : Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: selectedTab == 1 ? 1.6 : 1.0))
                .shadow(color: .black, radius: 0, x: selectedTab == 1 ? 1.5 : 0.5, y: selectedTab == 1 ? 1.5 : 0.5)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))
        }
    }

    // MARK: - Section: Rekomendasi Rutinitas Baru
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            if recommendations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.cartoonMint)

                    Text("Koleksi Kebiasaanmu Sudah Sangat Lengkap! 🌟")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.white)
                .cornerRadius(CartoonMetrics.cardCornerRadius)
                .overlay(RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius).stroke(Color.black, lineWidth: 1.2))
            } else {
                ForEach(recommendations) { rec in
                    recommendationCard(rec: rec)
                }
            }
        }
    }

    private func recommendationCard(rec: AIHabitRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: rec.colorHex))
                        .frame(width: 36, height: 36)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.4))

                    Image(systemName: rec.icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(rec.title)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)

                    HStack(spacing: 6) {
                        Text(rec.category.rawValue)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white)
                            .cornerRadius(4)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black, lineWidth: 0.8))

                        Text("⏱️ \(rec.timeOfDay)")
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button {
                    adoptHabit(rec)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .black))
                        Text("Adopsi")
                            .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.cartoonMint)
                    .cornerRadius(7)
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.black, lineWidth: 1.2))
                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }

            Text(rec.benefit)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }

    // MARK: - Section: Streak Risk Radar
    private var streakRisksSection: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            if streakRisks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "shield.checkmark.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.cartoonMint)

                    Text("Semua Streak Kebiasaanmu Aman! 🛡️")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)

                    Text("Seluruh kebiasaan aktif hari ini telah diceklis atau berada dalam ritme yang aman.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.white)
                .cornerRadius(CartoonMetrics.cardCornerRadius)
                .overlay(RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius).stroke(Color.black, lineWidth: 1.2))
            } else {
                ForEach(streakRisks) { risk in
                    streakRiskCard(risk: risk)
                }
            }
        }
    }

    private func streakRiskCard(risk: HabitStreakRiskItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(risk.riskLevel.badgeColor)
                        .frame(width: 36, height: 36)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.4))

                    Image(systemName: risk.icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(risk.title)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)

                    HStack(spacing: 6) {
                        Text("🔥 Streak \(risk.currentStreak) Hari")
                            .font(.system(size: 10.5, weight: .black, design: .monospaced))
                            .foregroundColor(.black)

                        Text("• \(risk.riskLevel.rawValue)")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(risk.riskLevel.badgeColor)
                    }
                }

                Spacer()

                // Quick Check-in Button
                if let targetHabit = habits.first(where: { $0.id == risk.id }) {
                    Button {
                        HapticManager.shared.success()
                        SoundManager.shared.playSuccessChime()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            targetHabit.toggleCompletion(on: Date())
                            try? modelContext.save()
                            WidgetCenter.shared.reloadAllTimelines()
                            loadData()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .black))
                            Text("Ceklis")
                                .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.cartoonYellow)
                        .cornerRadius(7)
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.black, lineWidth: 1.2))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(risk.reason)
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)

                Text(risk.motivationalTip)
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
            }
            .padding(8)
            .background(Color.black.opacity(0.04))
            .cornerRadius(6)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }

    // MARK: - Logic
    private func loadData() {
        recommendations = AIHabitRecommenderService.shared.generateRecommendations(existingHabits: habits, existingTasks: tasks)
        streakRisks = AIHabitRecommenderService.shared.assessStreakRisks(for: habits)
    }

    private func adoptHabit(_ rec: AIHabitRecommendation) {
        HapticManager.shared.success()
        SoundManager.shared.playSuccessChime()
        AIHabitRecommenderService.shared.adoptHabit(recommendation: rec, in: modelContext)
        WidgetCenter.shared.reloadAllTimelines()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            recommendations.removeAll { $0.id == rec.id }
            adoptedHabitsCount += 1
        }
    }
}
