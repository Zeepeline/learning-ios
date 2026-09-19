//
//  ConfettiCelebrationView.swift
//  learning
//
//  Created by macbook on 9/18/26.
//

import SwiftUI

// MARK: - 🎊 Particle Model
struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var rotation: Double
    var opacity: Double
}

// MARK: - 🏆 Confetti & Streak Celebration Overlay View
struct ConfettiCelebrationView: View {
    let streakCount: Int
    let habitTitle: String
    let onDismiss: () -> Void

    @State private var particles: [ConfettiParticle] = []
    @State private var isCardVisible: Bool = false

    private let colors: [Color] = [.cartoonYellow, .cartoonPink, .cartoonMint, .cartoonCoral, .cartoonBlue, .cartoonLavender]

    dynamic var body: some View {
        ZStack {
            // Background Dim
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissCelebration()
                }

            // Confetti Particles
            TimelineView(.animation) { _ in
                Canvas { context, size in
                    for p in particles {
                        context.opacity = p.opacity
                        let rect = CGRect(x: p.x, y: p.y, width: p.size, height: p.size * 0.6)
                        let path = Path(roundedRect: rect, cornerRadius: 2)
                        context.fill(path, with: .color(p.color))
                    }
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Celebration Card
            if isCardVisible {
                VStack(spacing: HIGSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.cartoonYellow)
                            .frame(width: 88, height: 88)
                            .overlay(Circle().stroke(Color.black, lineWidth: 2.5))
                            .shadow(color: .black, radius: 0, x: 3, y: 3)

                        Image(systemName: "flame.fill")
                            .font(.system(size: 44, weight: .black))
                            .foregroundColor(.orange)
                    }
                    .padding(.top, HIGSpacing.xs)

                    VStack(spacing: 6) {
                        Text("LUAR BIASA! 🔥")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)

                        Text("Kamu berhasil mencapai **\(streakCount) Hari Streak** untuk kebiasaan:")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Text("\"\(habitTitle)\"")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.cartoonLavender)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                    }

                    Button {
                        dismissCelebration()
                    } label: {
                        Text("Lanjutkan Kebiasaan! 💪")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.cartoonMint)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.8))
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    .padding(.top, HIGSpacing.xs)
                }
                .padding(HIGSpacing.lg)
                .frame(maxWidth: 320)
                .background(Color.white)
                .cornerRadius(22)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.black, lineWidth: 2.2))
                .shadow(color: .black, radius: 0, x: 4, y: 4)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.7).combined(with: .opacity),
                    removal: .scale(scale: 0.85).combined(with: .opacity)
                ))
            }
        }
        .onAppear {
            spawnParticles()
            HapticManager.shared.success()
            SoundManager.shared.playSuccessChime()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isCardVisible = true
            }
        }
    }

    private func spawnParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        var list: [ConfettiParticle] = []

        for _ in 0..<45 {
            let p = ConfettiParticle(
                x: CGFloat.random(in: 20...(screenWidth - 20)),
                y: CGFloat.random(in: (screenHeight * 0.2)...(screenHeight * 0.7)),
                size: CGFloat.random(in: 8...14),
                color: colors.randomElement() ?? .cartoonYellow,
                rotation: Double.random(in: 0...360),
                opacity: 0.95
            )
            list.append(p)
        }
        particles = list
    }

    private func dismissCelebration() {
        HapticManager.shared.impact(style: .light)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isCardVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}
