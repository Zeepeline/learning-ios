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

                // Sub-seksi Pengaturan Suara Notifikasi & Pengingat Berulang
                if isNotificationEnabled {
                    notificationSettingsSection
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // 5. 🔊 Toggle Efek Suara (Sound FX)
                CartoonToggleRow(
                    icon: "speaker.wave.2.fill",
                    iconColor: .black,
                    iconBgColor: Color.cartoonOrange,
                    title: "Efek Suara (Sound FX)",
                    subtitle: "Suara pop ceria saat centang tugas & timer",
                    isOn: Binding(
                        get: { soundManager.isSoundFXEnabled },
                        set: { soundManager.isSoundFXEnabled = $0 }
                    ),
                    activeColor: Color.cartoonOrange
                )

                // 6. 📳 Toggle Getaran Haptik Kartun
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

    // MARK: - Sub-seksi Pengaturan Suara & Pengingat Rutin Harian
    private var notificationSettingsSection: some View {
        VStack(spacing: HIGSpacing.sm) {
            // Pilihan Nada Suara Notifikasi
            notificationTonePickerCard

            // Pengingat Pagi
            CartoonToggleRow(
                icon: "sun.max.fill",
                iconColor: .black,
                iconBgColor: Color.cartoonYellow,
                title: "Pengingat Pagi (08:00)",
                subtitle: "Semangat rencana tugas hari ini",
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

            // Pengingat Malam
            CartoonToggleRow(
                icon: "moon.stars.fill",
                iconColor: .black,
                iconBgColor: Color.cartoonLavender,
                title: "Pengingat Malam (20:00)",
                subtitle: "Evaluasi & review capaian harian",
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

            // Tombol Uji Coba Notifikasi Cepat
            Button {
                HapticManager.shared.impact(style: .medium)
                isTestingNotification = true
                testNotificationNotice = "Notifikasi akan muncul dalam 3 detik dengan nada \(soundManager.selectedTone.title)!"
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
                    Image(systemName: "bell.and.waves.left.and.right.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(isTestingNotification ? "Mengirim Notifikasi..." : "Kirim Notifikasi Uji Coba (3 Detik)")
                        .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                .shadow(color: .black, radius: 0, x: 1, y: 1)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            .disabled(isTestingNotification)

            if let notice = testNotificationNotice {
                Text(notice)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(.leading, 12)
    }

    // MARK: - Kartu Pemilih Nada Notifikasi
    private var notificationTonePickerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "music.note")
                    .font(.system(size: 11, weight: .bold))
                Text("NADA SUARA NOTIFIKASI")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 6) {
                ForEach(NotificationTone.allCases) { tone in
                    let isSelected = soundManager.selectedTone == tone
                    HStack {
                        Image(systemName: tone.iconName)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(isSelected ? .black : .secondary)

                        Text(tone.title)
                            .font(.system(size: 12, weight: isSelected ? .heavy : .bold, design: .rounded))
                            .foregroundColor(.black)

                        Spacer()

                        // Tombol Dengar Nada (Preview)
                        Button {
                            soundManager.previewNotificationTone(tone)
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 8, weight: .black))
                                Text("Dengar")
                                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(Color.cartoonMint)
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.black, lineWidth: 0.9))
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))

                        // Radio check icon
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isSelected ? Color.cartoonCoral : .gray.opacity(0.5))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? Color.cartoonYellow.opacity(0.35) : Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: isSelected ? 1.3 : 0.8)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        soundManager.selectedTone = tone
                        soundManager.previewNotificationTone(tone)
                    }
                }
            }
        }
        .padding(HIGSpacing.sm)
        .cartoonCard()
    }
}
