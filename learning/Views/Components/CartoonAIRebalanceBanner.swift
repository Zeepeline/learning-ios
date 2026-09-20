//
//  CartoonAIRebalanceBanner.swift
//  learning
//
//  Created by macbook on 9/20/26.
//

import SwiftUI
import SwiftData

struct CartoonAIRebalanceBanner: View {
    let items: [Item]
    let onOpenRebalanceSheet: () -> Void

    private var proposalsCount: Int {
        AIScheduleRebalancerService.shared.analyzeAndGenerateProposals(for: items).count
    }

    var body: some View {
        if proposalsCount > 0 {
            HStack(spacing: 12) {
                // Cartoon Robot Icon with Pulse
                ZStack {
                    Circle()
                        .fill(Color.cartoonYellow)
                        .frame(width: 40, height: 40)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.8))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)

                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 17, weight: .black))
                        .foregroundColor(.black)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Jadwal Perlu Dirapikan")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)

                    Text("\(proposalsCount) tugas terlewat / bentrok hari ini")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    HapticManager.shared.impact(style: .medium)
                    SoundManager.shared.playPop()
                    onOpenRebalanceSheet()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .black))
                        Text("Tata Ulang")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.cartoonMint)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.5))
                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
            .padding(12)
            .background(Color.cartoonCoral.opacity(0.18))
            .cornerRadius(CartoonMetrics.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
            )
            .shadow(color: .black, radius: 0, x: 2, y: 2)
        }
    }
}
