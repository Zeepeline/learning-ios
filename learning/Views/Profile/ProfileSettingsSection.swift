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
    var healthManager = HealthKitManager.shared
    var soundManager = SoundManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            Text("Pengaturan & Preferensi")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, HIGSpacing.md)

            VStack(spacing: HIGSpacing.md) {
                // MARK: - GRUP 1: Keamanan & Data
                settingsGroup(title: "KEAMANAN & DATA") {
                    VStack(spacing: HIGSpacing.xs) {
                        // 1. ☁️ Toggle Sinkronisasi iCloud
                        CartoonToggleRow(
                            icon: "icloud.fill",
                            iconColor: .black,
                            iconBgColor: Color.cartoonBlue,
                            title: "Sinkronisasi iCloud",
                            subtitle: "Cadangkan tugas & kebiasaan otomatis",
                            isOn: $isICloudSyncEnabled,
                            activeColor: Color.cartoonBlue
                        )

                        // 2. 🔐 Toggle Face ID / Biometrik
                        if BiometricAuthManager.shared.canEvaluateBiometrics() {
                            CartoonToggleRow(
                                icon: "faceid",
                                iconColor: .black,
                                iconBgColor: Color.cartoonLavender,
                                title: "Kunci \(BiometricAuthManager.shared.biometricType())",
                                subtitle: "Autentikasi keamanan saat membuka aplikasi",
                                isOn: $useBiometrics,
                                activeColor: Color.cartoonMint
                            )
                        }

                        // 3. 🏃 Integrasi Apple Health & Smartwatch
                        healthKitIntegrationRow
                    }
                }

                // MARK: - GRUP 2: Pengingat & Notifikasi
                settingsGroup(title: "PENGINGAT & NOTIFIKASI") {
                    VStack(spacing: HIGSpacing.xs) {
                        // 1. 🔔 Toggle Master Notifikasi Tugas
                        CartoonToggleRow(
                            icon: "bell.badge.fill",
                            iconColor: .black,
                            iconBgColor: Color.cartoonYellow,
                            title: "Pengingat Jadwal Tugas",
                            subtitle: "Notifikasi otomatis sebelum tenggat waktu",
                            isOn: $isNotificationEnabled,
                            activeColor: Color.cartoonCoral
                        )

                        if isNotificationEnabled {
                            // 2. ☀️ Pengingat Pagi
                            CartoonToggleRow(
                                icon: "sun.max.fill",
                                iconColor: .black,
                                iconBgColor: Color.cartoonYellow,
                                title: "Pengingat Pagi (08:00)",
                                subtitle: "Rencana & agenda tugas hari ini",
                                isOn: $isMorningReminderEnabled,
                                activeColor: Color.cartoonYellow
                            )
                            .onChange(of: isMorningReminderEnabled) { _, isEnabled in
                                handleMorningReminder(isEnabled)
                            }

                            // 3. 🌙 Pengingat Malam
                            CartoonToggleRow(
                                icon: "moon.stars.fill",
                                iconColor: .black,
                                iconBgColor: Color.cartoonLavender,
                                title: "Evaluasi Malam (20:00)",
                                subtitle: "Review capaian & ringkasan harian",
                                isOn: $isEveningReminderEnabled,
                                activeColor: Color.cartoonLavender
                            )
                            .onChange(of: isEveningReminderEnabled) { _, isEnabled in
                                handleEveningReminder(isEnabled)
                            }
                        }
                    }
                }

                // MARK: - GRUP 3: Audio & Umpan Balik
                settingsGroup(title: "FEEDBACK & SUARA") {
                    VStack(spacing: HIGSpacing.xs) {
                        // 1. 🔊 Toggle Efek Suara (Sound FX)
                        CartoonToggleRow(
                            icon: "speaker.wave.2.fill",
                            iconColor: .black,
                            iconBgColor: Color.cartoonOrange,
                            title: "Efek Suara (Sound FX)",
                            subtitle: "Suara pop ceria saat menyelesaikan tugas & timer",
                            isOn: Binding(
                                get: { soundManager.isSoundFXEnabled },
                                set: { soundManager.isSoundFXEnabled = $0 }
                            ),
                            activeColor: Color.cartoonOrange
                        )

                        // 2. 📳 Toggle Getaran Haptik
                        CartoonToggleRow(
                            icon: "hand.tap.fill",
                            iconColor: .black,
                            iconBgColor: Color.cartoonPink,
                            title: "Sensasi Getaran Haptik",
                            subtitle: "Umpan balik sentuhan responsif di setiap tombol",
                            isOn: $isHapticEnabled,
                            activeColor: Color.cartoonMint
                        )
                    }
                }
            }
            .padding(.horizontal, HIGSpacing.md)
        }
    }

    // MARK: - Helper Group Container dengan Header Kategori
    private func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            content()
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

    private func handleMorningReminder(_ isEnabled: Bool) {
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

    private func handleEveningReminder(_ isEnabled: Bool) {
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
