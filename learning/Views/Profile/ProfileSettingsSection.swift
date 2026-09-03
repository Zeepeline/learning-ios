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

    @State private var isTestingNotification: Bool = false
    @State private var testNotificationNotice: String?

    var body: some View {
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
                        // Sub-seksi Pengingat Berulang Harian
                        dailyRemindersSection
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
    }

    // MARK: - Sub-seksi Pengingat Berulang
    private var dailyRemindersSection: some View {
        VStack(spacing: HIGSpacing.xxs) {
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
                testNotificationNotice = "Notifikasi akan muncul dalam 3 detik! ⏱️"
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
}
