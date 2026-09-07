//
//  CartoonHealthCard.swift
//  learning
//
//  Created by macbook on 9/6/26.
//

import SwiftUI
import HealthKit

// MARK: - 🏃 Kartu Ringkasan Kebugaran & Olahraga Kartun Neo-Brutalist
struct CartoonHealthCard: View {
    var healthManager = HealthKitManager.shared
    @State private var isShowingAuthAlert: Bool = false
    
    var body: some View {
        VStack(spacing: HIGSpacing.sm) {
            if !healthManager.isAuthorized {
                // Banner Ajakan Koneksi Apple Health & Smartwatch
                healthAuthBanner
            } else {
                // 1. Kartu Statistik Kebugaran Terintegrasi (Langkah, Kalori, Olahraga, Tidur)
                healthMetricsCard
                
                // 2. Banner Workout Terakhir (misal: Sesi Lari dari Zepp) jika ada
                if let lastWorkout = healthManager.todaySummary.recentWorkouts.first {
                    workoutRecordCard(workout: lastWorkout)
                }
            }
        }
        .task {
            if healthManager.isAuthorized {
                await healthManager.fetchAllTodayHealthData()
            }
        }
    }
    
    // MARK: - 1. Kartu Metrik Kebugaran Hari Ini
    private var healthMetricsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Judul & Tombol Sync Cepat
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(Color.cartoonCoral)
                    
                    Text("KEBUGARAN & AKTIVITAS")
                        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Button {
                    HapticManager.shared.selection()
                    Task {
                        await healthManager.fetchAllTodayHealthData()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10, weight: .bold))
                            .rotationEffect(.degrees(healthManager.isLoading ? 360 : 0))
                            .animation(healthManager.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: healthManager.isLoading)
                        
                        Text("Sync")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.cartoonMint)
                            .shadow(color: .black, radius: 0, x: 1, y: 1)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
            
            // Grid 4 Metrik Utama: Langkah, Kalori, Olahraga, Tidur
            HStack(spacing: 8) {
                // A. Langkah Kaki (Steps)
                healthStatPill(
                    icon: "figure.walk",
                    iconColor: Color.cartoonYellow,
                    value: "\(healthManager.todaySummary.steps)",
                    unit: "langkah",
                    progress: healthManager.todaySummary.stepsProgress,
                    progressColor: Color.cartoonYellow
                )
                
                // B. Kalori Terbakar (kCal)
                healthStatPill(
                    icon: "flame.fill",
                    iconColor: Color.cartoonOrange,
                    value: "\(Int(healthManager.todaySummary.activeCalories))",
                    unit: "kkal aktif",
                    progress: healthManager.todaySummary.caloriesProgress,
                    progressColor: Color.cartoonOrange
                )
                
                // C. Waktu Olahraga (Exercise)
                healthStatPill(
                    icon: "bolt.fill",
                    iconColor: Color.cartoonMint,
                    value: "\(Int(healthManager.todaySummary.exerciseMinutes))",
                    unit: "menit",
                    progress: healthManager.todaySummary.exerciseProgress,
                    progressColor: Color.cartoonMint
                )
                
                // D. Waktu Tidur Semalam (Sleep)
                healthStatPill(
                    icon: "moon.stars.fill",
                    iconColor: Color.cartoonLavender,
                    value: healthManager.todaySummary.sleepFormatted,
                    unit: "tidur",
                    progress: min(1.0, healthManager.todaySummary.sleepDurationHours / 8.0),
                    progressColor: Color.cartoonLavender
                )
            }
        }
        .padding(HIGSpacing.md)
        .cartoonCard()
    }
    
    // Helper Stat Pill Individual
    private func healthStatPill(
        icon: String,
        iconColor: Color,
        value: String,
        unit: String,
        progress: Double,
        progressColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(iconColor)
                    .frame(width: 24, height: 24)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
                
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(unit)
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Progress Bar Mini
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 3.5)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(progressColor)
                        .frame(width: geo.size.width * CGFloat(progress), height: 3.5)
                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.black, lineWidth: 0.5))
                }
            }
            .frame(height: 3.5)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
        )
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.1))
    }
    
    // MARK: - 2. Kartu Sesi Olahraga Terakhir (Misal: Lari dari Zepp)
    private func workoutRecordCard(workout: HealthWorkoutItem) -> some View {
        HStack(spacing: 12) {
            // Icon Olahraga Kartun
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.cartoonCoral)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                    .frame(width: 44, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.6))
                
                Image(systemName: workout.icon)
                    .font(.system(size: 19, weight: .black))
                    .foregroundColor(.white)
            }
            
            // Info Olahraga
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(workout.title)
                        .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                    
                    // Badge Sumber (misal: "Zepp")
                    Text(workout.sourceName)
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Color.cartoonYellow)
                        .cornerRadius(4)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black, lineWidth: 0.8))
                    
                    Spacer()
                    
                    Text(workout.timeFormatted)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                // Ringkasan Jarak, Durasi, dan Kalori
                HStack(spacing: 10) {
                    if workout.distanceKm > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text(String(format: "%.2f km", workout.distanceKm))
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                        }
                    }
                    
                    HStack(spacing: 3) {
                        Image(systemName: "stopwatch.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text(workout.durationFormatted)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                    }
                    
                    if workout.calories > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text("\(Int(workout.calories)) kkal")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                        }
                    }
                }
                .foregroundColor(.black.opacity(0.8))
            }
        }
        .padding(HIGSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .fill(Color(red: 0.99, green: 0.94, blue: 0.88))
                .shadow(color: .black, radius: 0, x: 2, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
    }
    
    // MARK: - 3. Banner Ajakan Menghubungkan HealthKit
    private var healthAuthBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.cartoonPink)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                    .frame(width: 44, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.6))
                
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Sinkronkan Apple Health & Zepp")
                    .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                
                Text("Baca otomatis sesi lari, langkah kaki, dan durasi tidur.")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button {
                HapticManager.shared.impact(style: .medium)
                Task {
                    let success = await healthManager.requestAuthorization()
                    if success {
                        HapticManager.shared.success()
                    }
                }
            } label: {
                Text("Hubungkan")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.cartoonMint)
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.4))
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
        }
        .padding(HIGSpacing.md)
        .cartoonCard()
    }
}

#Preview {
    CartoonHealthCard()
        .padding()
        .background(Color.cartoonBg)
}
