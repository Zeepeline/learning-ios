//
//  ProfileSettingsSection.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI

struct ProfileSettingsSection: View {
    @Binding var useBiometrics: Bool
    @Binding var isNotificationEnabled: Bool
    @Binding var isMorningReminderEnabled: Bool
    @Binding var isEveningReminderEnabled: Bool
    @Binding var isHapticEnabled: Bool
    @AppStorage("isICloudSyncEnabled") private var isICloudSyncEnabled: Bool = true
    @ObservedObject private var healthManager = HealthKitManager.shared

    @State private var isTestingNotification: Bool = false
    @State private var testNotificationNotice: String?

    var body: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            Text("Pengaturan & Keamanan")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, HIGSpacing.md)

            VStack(spacing: HIGSpacing.sm) {
                // 1. ☁️ Toggle Sinkronisasi iCloud Kartun
                CartoonToggleRow(
                    icon: "icloud.fill",
                    iconColor: .black,
                    iconBgColor: Color.cartoonBlue,
                    title: "Sinkronisasi iCloud",
                    subtitle: "Cadangkan tugas & kebiasaan otomatis",
                    isOn: $isICloudSyncEnabled,
                    activeColor: Color.cartoonBlue
                )

                // 2. 🏃 Integrasi Apple Health & Smartwatch (Zepp/Amazfit)
                healthKitIntegrationRow

                // 3. 🔐 Toggle Face ID / Biometrik Kartun
                if BiometricAuthManager.shared.canEvaluateBiometrics() {
                    CartoonToggleRow(
                        icon: "faceid",
                        iconColor: .black,
                        iconBgColor: Color.cartoonLavender,
                        title: "Kunci dengan \(BiometricAuthManager.shared.biometricType())",
                        subtitle: "Autentikasi biometrik saat buka app",
                        isOn: $useBiometrics,
                        activeColor: Color.cartoonMint
                    )
                }

                // 4. 🔔 Toggle Master Notifikasi Tugas Kartun
                CartoonToggleRow(
                    icon: "bell.badge.fill",
                    iconColor: .black,
                    iconBgColor: Color.cartoonYellow,
                    title: "Pengingat Notifikasi Tugas",
                    subtitle: "Alarm lokal sebelum tenggat waktu",
                    isOn: $isNotificationEnabled,
                    activeColor: Color.cartoonCoral
                )

                // Sub-seksi Pengingat Berulang Harian
                if isNotificationEnabled {
                    dailyRemindersSection
                        .transition(.opacity.combined(with: .move(edge: .top)) )
                }

                // 5. 📳 Toggle Getaran Haptik Kartun
                CartoonToggleRow(
                    icon: "hand.tap.fill",
                    iconColor: .black,
                    iconBgColor: Color.cartoonPink,
                    title: "Sensasi Getaran Haptik",
                    subtitle: "Umpan balik sentuhan responsif",
                    isOn: $isHapticEnabled,
                    activeColor: Color.cartoonMint
                )
            }
            .padding(.horizontal, HIGSpacing.md)
        }
    }

    // MARK: - Baris Integrasi Apple Health & Zepp
    private var healthKitIntegrationRow: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.cartoonPink)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                    .frame(width: 44, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.6))

                Image(systemName: "heart.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Apple Health & Smartwatch")
                    .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Text(healthManager.isAuthorized ? "Terhubung (Auto-sync Zepp & Watch)" : "Sinkronkan lari, langkah & tidur")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(healthManager.isAuthorized ? Color(red: 0.1, green: 0.6, blue: 0.3) : .secondary)
            }

            Spacer()

            if healthManager.isAuthorized {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                    Text("Aktif")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.cartoonMint.opacity(0.4))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
            } else {
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
                        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.cartoonYellow)
                                .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
        }
        .padding(HIGSpacing.md)
        .cartoonCard()
    }

    // MARK: - Sub-seksi Pengingat Rutin Harian Kartun
    private var dailyRemindersSection: some View {
        VStack(spacing: HIGSpacing.sm) {
            VStack(alignment: .leading, spacing: HIGSpacing.xs) {
                Text("JADWAL PENGINGAT RUTIN (BACKGROUND)")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.top, 2)

                // Pengingat Pagi (08:00)
                CartoonToggleRow(
                    icon: "sun.max.fill",
                    iconColor: .black,
                    iconBgColor: Color.cartoonYellow,
                    title: "Pengingat Pagi (08:00)",
                    subtitle: "Cek target & tugas hari ini",
                    isOn: $isMorningReminderEnabled,
                    activeColor: Color.cartoonYellow
                )
                .onChange(of: isMorningReminderEnabled) { _, isEnabled in
                    HapticManager.shared.selection()
                    if isEnabled {
                        Task {
                            await NotificationManager.shared.scheduleDailyReminder(
                                hour: 8,
                                minute: 0,
                                title: "Semangat Pagi! Saatnya Mulai Hari",
                                body: "Buka aplikasi untuk melihat daftar tugas yang perlu diselesaikan hari ini!",
                                identifier: NotificationManager.morningReminderId
                            )
                        }
                    } else {
                        NotificationManager.shared.cancelReminder(identifier: NotificationManager.morningReminderId)
                    }
                }

                // Pengingat Malam (20:00)
                CartoonToggleRow(
                    icon: "moon.stars.fill",
                    iconColor: .black,
                    iconBgColor: Color.cartoonLavender,
                    title: "Pengingat Malam (20:00)",
                    subtitle: "Evaluasi pencapaian tugas",
                    isOn: $isEveningReminderEnabled,
                    activeColor: Color.cartoonLavender
                )
                .onChange(of: isEveningReminderEnabled) { _, isEnabled in
                    HapticManager.shared.selection()
                    if isEnabled {
                        Task {
                            await NotificationManager.shared.scheduleDailyReminder(
                                hour: 20,
                                minute: 0,
                                title: "Evaluasi Malam",
                                body: "Hebat! Cek berapa banyak tugas yang telah berhasil kamu selesaikan hari ini.",
                                identifier: NotificationManager.eveningReminderId
                            )
                        }
                    } else {
                        NotificationManager.shared.cancelReminder(identifier: NotificationManager.eveningReminderId)
                    }
                }
            }

            // Tombol Tes Notifikasi Lokal
            Button {
                HapticManager.shared.impact(style: .medium)
                isTestingNotification = true
                testNotificationNotice = "Notifikasi akan muncul dalam 3 detik!"
                Task {
                    do {
                        try await NotificationManager.shared.sendTestNotification(seconds: 3)
                        isTestingNotification = false
                    } catch {
                        isTestingNotification = false
                        testNotificationNotice = "Izin notifikasi belum diaktifkan di Pengaturan iOS."
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 11, weight: .black))
                    Text(isTestingNotification ? "Menjadwalkan Tes..." : "Tes Notifikasi Lokal (3 Detik)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.cartoonMint)
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black, lineWidth: 1.6)
                )
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

            if let notice = testNotificationNotice {
                Text(notice)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .transition(.opacity)
            }
        }
        .padding(HIGSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .fill(Color(red: 0.95, green: 0.93, blue: 0.89))
                .shadow(color: .black, radius: 0, x: 2, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
    }
}
