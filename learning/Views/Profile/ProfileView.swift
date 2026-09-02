//
//  ProfileView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var allItems: [Item]
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = true
    @AppStorage("userName") private var userName: String = "Bruce Wayne"
    @AppStorage("userEmail") private var userEmail: String = "brucewayne27@suarasa.com"
    @AppStorage("useBiometrics") private var useBiometrics: Bool = true
    @AppStorage("isNotificationEnabled") private var isNotificationEnabled: Bool = true
    @AppStorage("isMorningReminderEnabled") private var isMorningReminderEnabled: Bool = false
    @AppStorage("isEveningReminderEnabled") private var isEveningReminderEnabled: Bool = false
    @AppStorage("isHapticEnabled") private var isHapticEnabled: Bool = true

    @State private var isShowingLogoutDialog: Bool = false
    @State private var isTestingNotification: Bool = false
    @State private var testNotificationNotice: String? = nil

    // Perhitungan Statistik Real-Time dari SwiftData
    private var completedTasksCount: Int {
        allItems.filter { $0.isCompleted }.count
    }

    private var importantCompletedCount: Int {
        allItems.filter { $0.priority == "Tinggi" && $0.isCompleted }.count
    }

    private var totalXP: Int {
        completedTasksCount * 50
    }

    private var userLevel: Int {
        max(1, (totalXP / 200) + 1)
    }

    private var xpProgressInCurrentLevel: Double {
        let remainder = Double(totalXP % 200)
        return remainder / 200.0
    }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: HIGSpacing.lg) {
                    
                    // 1. Header Profil & Avatar Kartun
                    VStack(spacing: HIGSpacing.sm) {
                        ZStack(alignment: .bottomTrailing) {
                            // Avatar Bulat Kartun
                            ZStack {
                                Circle()
                                    .fill(Color.cartoonYellow)
                                    .frame(width: 88, height: 88)
                                    .overlay(
                                        Circle().stroke(Color.black, lineWidth: CartoonMetrics.thickBorderWidth)
                                    )
                                    .shadow(color: .black, radius: 0, x: 3, y: 3)
                                
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 56, height: 56)
                                    .foregroundColor(.black)
                            }

                            // Badge Edit Pensil Mini (Touch target 44pt)
                            Button {
                                HapticManager.shared.impact(style: .light)
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(.black)
                                    .padding(8)
                                    .background(Color.cartoonMint)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.black, lineWidth: 1.6))
                                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                            }
                            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                        }
                        .padding(.top, HIGSpacing.xs)

                        // Nama & Email
                        VStack(spacing: HIGSpacing.xxs) {
                            Text(userName)
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)

                            Text("Productivity Master")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)

                            Text(userEmail)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary.opacity(0.8))
                        }

                        // Badge XP & Level Gamifikasi Real-Time
                        VStack(spacing: 6) {
                            HStack {
                                Text("⚡️ Level \(userLevel) Explorer")
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                                    .foregroundColor(.black)

                                Spacer()

                                Text("\(totalXP) XP Total")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.secondary)
                            }

                            // Progress Bar Kartun
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(red: 0.93, green: 0.93, blue: 0.95))
                                        .frame(height: 12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.black, lineWidth: 1.5)
                                        )

                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.cartoonMint)
                                        .frame(width: max(geometry.size.width * CGFloat(xpProgressInCurrentLevel), (totalXP > 0 ? 12 : 0)), height: 12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.black, lineWidth: 1.5)
                                        )
                                        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: xpProgressInCurrentLevel)
                                }
                            }
                            .frame(height: 12)
                        }
                        .padding(HIGSpacing.md)
                        .background(Color.white)
                        .cornerRadius(CartoonMetrics.cardCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                        )
                        .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
                        .padding(.horizontal, HIGSpacing.md)
                    }

                    // 2. Statistik Aktivitas Kartun (Grid 2 Kolom Real-Time)
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
                                title: "Streak Hari",
                                value: "3 Hari",
                                bgColor: .cartoonOrange,
                                iconColor: .red
                            )
                        }
                        .padding(.horizontal, HIGSpacing.md)

                        HStack(spacing: HIGSpacing.sm) {
                            ProfileStatCard(
                                icon: "list.clipboard.fill",
                                title: "Total Tugas",
                                value: "\(allItems.count)",
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

                    // 3. Pengaturan & Preferensi
                    VStack(alignment: .leading, spacing: HIGSpacing.xs) {
                        Text("Pengaturan & Keamanan")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, HIGSpacing.md)

                        VStack(spacing: HIGSpacing.xs) {
                            // Toggle Face ID / Biometrik
                            if BiometricAuthManager.shared.canEvaluateBiometrics() {
                                Toggle(isOn: $useBiometrics) {
                                    HStack(spacing: HIGSpacing.xs) {
                                        Image(systemName: "faceid")
                                            .foregroundColor(.purple)
                                        Text("Kunci dengan \(BiometricAuthManager.shared.biometricType())")
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundColor(.black)
                                    }
                                }
                                .tint(Color.cartoonCoral)
                                .padding(.horizontal, HIGSpacing.md)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(CartoonMetrics.cardCornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                        .stroke(Color.black, lineWidth: 1.6)
                                )
                                .shadow(color: .black, radius: 0, x: 2, y: 2)
                            }

                            // Toggle Notifikasi
                            VStack(spacing: HIGSpacing.xxs) {
                                Toggle(isOn: $isNotificationEnabled) {
                                    HStack(spacing: HIGSpacing.xs) {
                                        Image(systemName: "bell.badge.fill")
                                            .foregroundColor(.orange)
                                        Text("Pengingat Notifikasi Tugas")
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundColor(.black)
                                    }
                                }
                                .tint(Color.cartoonCoral)
                                .padding(.horizontal, HIGSpacing.md)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(CartoonMetrics.cardCornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                        .stroke(Color.black, lineWidth: 1.6)
                                )
                                .shadow(color: .black, radius: 0, x: 2, y: 2)

                                if isNotificationEnabled {
                                    // Sub-seksi Pengingat Berulang Harian (Background Trigger)
                                    VStack(alignment: .leading, spacing: HIGSpacing.xs) {
                                        Text("JADWAL PENGINGAT RUTIN (BACKGROUND)")
                                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 4)
                                            .padding(.top, 2)

                                        // Pengingat Pagi (08:00)
                                        Toggle(isOn: $isMorningReminderEnabled) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "sun.max.fill")
                                                    .foregroundColor(.orange)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("Pengingat Pagi (08:00)")
                                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                                        .foregroundColor(.black)
                                                    Text("Cek target & tugas hari ini")
                                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                        .tint(Color.cartoonCoral)
                                        .onChange(of: isMorningReminderEnabled) { _, isEnabled in
                                            HapticManager.shared.selection()
                                            if isEnabled {
                                                NotificationManager.shared.scheduleDailyReminder(
                                                    hour: 8,
                                                    minute: 0,
                                                    title: "☀️ Semangat Pagi! Saatnya Mulai Hari",
                                                    body: "Buka aplikasi untuk melihat daftar tugas yang perlu diselesaikan hari ini! 🚀",
                                                    identifier: NotificationManager.morningReminderId
                                                )
                                            } else {
                                                NotificationManager.shared.cancelReminder(identifier: NotificationManager.morningReminderId)
                                            }
                                        }

                                        Divider()

                                        // Pengingat Malam (20:00)
                                        Toggle(isOn: $isEveningReminderEnabled) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "moon.stars.fill")
                                                    .foregroundColor(.indigo)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("Pengingat Malam (20:00)")
                                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                                        .foregroundColor(.black)
                                                    Text("Evaluasi pencapaian tugas")
                                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                        .tint(Color.cartoonCoral)
                                        .onChange(of: isEveningReminderEnabled) { _, isEnabled in
                                            HapticManager.shared.selection()
                                            if isEnabled {
                                                NotificationManager.shared.scheduleDailyReminder(
                                                    hour: 20,
                                                    minute: 0,
                                                    title: "🌙 Evaluasi Malam",
                                                    body: "Hebat! Cek berapa banyak tugas yang telah berhasil kamu selesaikan hari ini ⭐️",
                                                    identifier: NotificationManager.eveningReminderId
                                                )
                                            } else {
                                                NotificationManager.shared.cancelReminder(identifier: NotificationManager.eveningReminderId)
                                            }
                                        }
                                    }
                                    .padding(HIGSpacing.sm)
                                    .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                                    .cornerRadius(CartoonMetrics.cardCornerRadius)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                            .stroke(Color.black, lineWidth: 1.2)
                                    )

                                    Button {
                                        HapticManager.shared.impact(style: .medium)
                                        isTestingNotification = true
                                        testNotificationNotice = "Notifikasi akan muncul dalam 3 detik! ⏰"
                                        NotificationManager.shared.sendTestNotification(seconds: 3) { success in
                                            isTestingNotification = false
                                            if !success {
                                                testNotificationNotice = "Izin notifikasi belum diaktifkan di Pengaturan iOS."
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "paperplane.fill")
                                                .font(.system(size: 11, weight: .bold))
                                            Text(isTestingNotification ? "Menjadwalkan Tes..." : "Tes Notifikasi Lokal (3 Detik)")
                                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        }
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color.cartoonYellow)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.black, lineWidth: 1.4)
                                        )
                                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                                    }
                                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                                    .padding(.top, 2)

                                    if let notice = testNotificationNotice {
                                        Text(notice)
                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 4)
                                            .transition(.opacity)
                                    }
                                }
                            }

                            // Toggle Getaran Haptik
                            Toggle(isOn: $isHapticEnabled) {
                                HStack(spacing: HIGSpacing.xs) {
                                    Image(systemName: "hand.tap.fill")
                                        .foregroundColor(.blue)
                                    Text("Sensasi Getaran Haptik")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(.black)
                                }
                            }
                            .tint(Color.cartoonCoral)
                            .padding(.horizontal, HIGSpacing.md)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(CartoonMetrics.cardCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: 1.6)
                            )
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                        }
                        .padding(.horizontal, HIGSpacing.md)
                    }

                    // 4. Tombol Logout / Keluar Akun
                    Button {
                        HapticManager.shared.warning()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isShowingLogoutDialog = true
                        }
                    } label: {
                        HStack(spacing: HIGSpacing.xs) {
                            Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                                .font(.system(size: 14, weight: .black))
                            Text("Keluar dari Akun")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.cartoonCoral)
                        .cornerRadius(CartoonMetrics.cardCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                        )
                        .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
                    .padding(.horizontal, HIGSpacing.md)
                    .padding(.top, HIGSpacing.xxs)

                    // Versi App
                    Text("Learning App v1.0.0 • Made with SwiftUI & SwiftData")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.top, HIGSpacing.xxs)
                        .padding(.bottom, 80)
                }
                .padding(.top, HIGSpacing.xs)
            }

            // Pop-up Konfirmasi Logout Kartun
            if isShowingLogoutDialog {
                CartoonConfirmDialog(
                    title: "Keluar Akun?",
                    message: "Apakah kamu yakin ingin keluar dari akun ini?",
                    icon: "rectangle.portrait.and.arrow.right.fill",
                    iconBgColor: Color(red: 1.0, green: 0.92, blue: 0.92),
                    iconFgColor: Color.cartoonCoral,
                    cancelTitle: "Batal",
                    confirmTitle: "Ya, Keluar",
                    confirmColor: Color.cartoonCoral,
                    onCancel: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            isShowingLogoutDialog = false
                        }
                    },
                    onConfirm: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isShowingLogoutDialog = false
                            isLoggedIn = false // Kembali ke halaman Login
                        }
                    }
                )
            }
        }
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

#Preview {
    ProfileView()
        .modelContainer(for: Item.self, inMemory: true)
}
