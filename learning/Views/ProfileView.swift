//
//  ProfileView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI

struct ProfileView: View {
    // Dummy Data Profil
    @State private var userName: String = "Herlambang"
    @State private var userEmail: String = "herlambang@example.com"
    @State private var userRole: String = "iOS Developer Apprentice"
    @State private var isNotificationEnabled: Bool = true
    @State private var isSoundEnabled: Bool = true

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // 1. Header Profil & Avatar Kartun
                VStack(spacing: 12) {
                    ZStack(alignment: .bottomTrailing) {
                        // Avatar Bulat Kartun
                        ZStack {
                            Circle()
                                .fill(Color.cartoonYellow)
                                .frame(width: 86, height: 86)
                                .overlay(
                                    Circle().stroke(Color.cartoonBorder, lineWidth: CartoonMetrics.thickBorderWidth)
                                )
                                .shadow(color: .cartoonBorder, radius: 0, x: 3, y: 3)
                            
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 54, height: 54)
                                .foregroundColor(.cartoonTextPrimary)
                        }

                        // Badge Edit Pensil Mini
                        Button {
                            // Aksi edit avatar
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.cartoonTextPrimary)
                                .padding(6)
                                .background(Color.cartoonMint)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.cartoonBorder, lineWidth: 1.5))
                                .shadow(color: .cartoonBorder, radius: 0, x: 1.5, y: 1.5)
                        }
                    }
                    .padding(.top, 10)

                    // Nama & Email
                    VStack(spacing: 4) {
                        Text(userName)
                            .font(.cartoonTitle)
                            .foregroundColor(.cartoonTextPrimary)

                        Text(userRole)
                            .font(.cartoonSubheadline)
                            .foregroundColor(.secondary)

                        Text(userEmail)
                            .font(.cartoonCaption)
                            .foregroundColor(.secondary.opacity(0.8))
                    }

                    // Badge XP & Level Gamifikasi
                    VStack(spacing: 6) {
                        HStack {
                            Text("⚡️ Level 5 Explorer")
                                .font(.cartoonBadge)
                                .foregroundColor(.cartoonTextPrimary)
                            Spacer()
                            Text("820 / 1000 XP")
                                .font(.cartoonBadge)
                                .foregroundColor(.secondary)
                        }

                        // Progress Bar Kartun
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white)
                                    .frame(height: 12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.cartoonBorder, lineWidth: 1.5)
                                    )

                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.cartoonMint)
                                    .frame(width: geometry.size.width * 0.82, height: 12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.cartoonBorder, lineWidth: 1.5)
                                    )
                            }
                        }
                        .frame(height: 12)
                    }
                    .padding(12)
                    .cartoonCard(bgColor: .white, cornerRadius: 12, borderWidth: 1.5, shadowOffset: 2.0)
                    .padding(.horizontal, 16)
                }

                // 2. Statistik Aktivitas Kartun (Grid 2 Kolom)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Statistik Produktivitas")
                        .font(.cartoonHeadline)
                        .foregroundColor(.cartoonTextPrimary)
                        .padding(.horizontal, 16)

                    HStack(spacing: 12) {
                        ProfileStatCard(
                            icon: "checklist.checked",
                            title: "Selesai",
                            value: "24",
                            bgColor: .cartoonMint
                        )
                        ProfileStatCard(
                            icon: "flame.fill",
                            title: "Streak Hari",
                            value: "7 Hari",
                            bgColor: .cartoonOrange,
                            iconColor: .red
                        )
                    }
                    .padding(.horizontal, 16)

                    HStack(spacing: 12) {
                        ProfileStatCard(
                            icon: "clock.badge.checkmark",
                            title: "Total Tugas",
                            value: "32",
                            bgColor: .cartoonYellow
                        )
                        ProfileStatCard(
                            icon: "star.fill",
                            title: "Penting Selesai",
                            value: "8",
                            bgColor: .cartoonBlue,
                            iconColor: .orange
                        )
                    }
                    .padding(.horizontal, 16)
                }

                // 3. Pengaturan & Preferensi
                VStack(alignment: .leading, spacing: 10) {
                    Text("Preferensi & Akun")
                        .font(.cartoonHeadline)
                        .foregroundColor(.cartoonTextPrimary)
                        .padding(.horizontal, 16)

                    VStack(spacing: 10) {
                        // Toggle Notifikasi
                        Toggle(isOn: $isNotificationEnabled) {
                            HStack(spacing: 10) {
                                Image(systemName: "bell.badge.fill")
                                    .foregroundColor(.orange)
                                Text("Pengingat Notifikasi")
                                    .font(.cartoonSubheadline)
                                    .foregroundColor(.cartoonTextPrimary)
                            }
                        }
                        .tint(.cartoonMint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .cartoonCard(bgColor: .white, cornerRadius: 12, borderWidth: 1.5, shadowOffset: 2.0)

                        // Toggle Suara
                        Toggle(isOn: $isSoundEnabled) {
                            HStack(spacing: 10) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundColor(.blue)
                                Text("Efek Suara Tombol")
                                    .font(.cartoonSubheadline)
                                    .foregroundColor(.cartoonTextPrimary)
                            }
                        }
                        .tint(.cartoonMint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .cartoonCard(bgColor: .white, cornerRadius: 12, borderWidth: 1.5, shadowOffset: 2.0)
                    }
                    .padding(.horizontal, 16)
                }

                // Versi App
                Text("Learning App v1.0.0 • Made with SwiftUI")
                    .font(.cartoonCaption)
                    .foregroundColor(.secondary)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
            }
            .padding(.top, 10)
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 75)
        }
        .background(Color.cartoonBg)
    }
}

// Komponen Kartu Statistik Mini
struct ProfileStatCard: View {
    let icon: String
    let title: String
    let value: String
    let bgColor: Color
    var iconColor: Color = .black

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color.cartoonBorder, lineWidth: 1.5))
                
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(.cartoonTextPrimary)
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .cartoonCard(bgColor: bgColor, cornerRadius: 12, borderWidth: 1.5, shadowOffset: 2.0)
    }
}

#Preview {
    ProfileView()
}
