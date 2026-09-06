//
//  SplashScreenView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI

struct SplashScreenView: View {
    @Binding var isSplashActive: Bool
    
    // Animation States
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0.0
    @State private var rotation: Double = -10.0
    @State private var textOffset: CGFloat = 20.0
    @State private var sparkleScale: CGFloat = 0.0

    var body: some View {
        ZStack {
            // Latar Belakang Kartun Retro Terang
            Color.cartoonBg
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // 1. Logo Kartun Membal & Berputar Halus
                ZStack {
                    // Lingkaran Luar Bayangan Stiker
                    Circle()
                        .fill(Color.cartoonYellow)
                        .frame(width: 110, height: 110)
                        .overlay(
                            Circle().stroke(Color.cartoonBorder, lineWidth: CartoonMetrics.thickBorderWidth)
                        )
                        .shadow(color: .cartoonBorder, radius: 0, x: 4, y: 4)

                    // Ikon Vektor Checklist Kartun
                    Image(systemName: "checklist.checked")
                        .font(.system(size: 54, weight: .black))
                        .foregroundColor(.cartoonTextPrimary)

                    // Stiker Bintang / Sparkle di Pojok Kanan Atas
                    Image(systemName: "sparkle")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                        .offset(x: 48, y: -45)
                        .scaleEffect(sparkleScale)
                }
                .rotationEffect(.degrees(rotation))
                .scaleEffect(scale)
                .opacity(opacity)

                // 2. Judul Aplikasi Bergaya Kartun Pop
                VStack(spacing: 6) {
                    Text("Activity Tracker")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.cartoonTextPrimary)

                    HStack(spacing: 4) {
                        Text("Plan • Focus • Accomplish")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.cartoonOrange)
                    }
                }
                .offset(y: textOffset)
                .opacity(opacity)
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            // Animasi Masuk: Logo membal (Spring Animation)
            withAnimation(.spring(response: 0.65, dampingFraction: 0.6, blendDuration: 0)) {
                scale = 1.0
                opacity = 1.0
                rotation = 0.0
                textOffset = 0.0
            }

            // Animasi Sparkle muncul dengan delay
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.3)) {
                sparkleScale = 1.2
            }

            // Durasi Splash Screen (1.8 detik), lalu transisi keluar ke layar utama
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isSplashActive = false
                }
            }
        }
    }
}

#Preview {
    SplashScreenView(isSplashActive: .constant(true))
}
