//
//  CartoonHabitStreakRiskBanner.swift
//  learning
//
//  Created by macbook on 9/20/26.
//

import SwiftUI
import SwiftData

struct CartoonHabitStreakRiskBanner: View {
    let habits: [Habit]
    let onOpenRescueSheet: () -> Void

    private var criticalOrHighRisks: [HabitStreakRiskItem] {
        let risks = AIHabitRecommenderService.shared.assessStreakRisks(for: habits)
        return risks.filter { $0.riskLevel == .critical || $0.riskLevel == .high }
    }

    var body: some View {
        if let topRisk = criticalOrHighRisks.first {
            HStack(spacing: 12) {
                // Pulsing Flame Icon
                ZStack {
                    Circle()
                        .fill(topRisk.riskLevel == .critical ? Color.cartoonCoral : Color.cartoonYellow)
                        .frame(width: 40, height: 40)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.8))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.black)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Streak Terancam Putus! 🔥")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)

                        Text("\(topRisk.currentStreak) Hari")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.white)
                            .cornerRadius(4)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black, lineWidth: 0.8))
                    }

                    Text("'\((topRisk.title))' belum diceklis hari ini. Jaga apimu!")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    HapticManager.shared.impact(style: .medium)
                    SoundManager.shared.playPop()
                    onOpenRescueSheet()
                } label: {
                    Text("Rescue ⚡")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.5))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
            .padding(12)
            .background(
                topRisk.riskLevel == .critical
                    ? Color.cartoonCoral.opacity(0.22)
                    : Color.cartoonYellow.opacity(0.25)
            )
            .cornerRadius(CartoonMetrics.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
            )
            .shadow(color: .black, radius: 0, x: 2, y: 2)
            .transition(.scale(scale: 0.96).combined(with: .opacity))
        }
    }
}
