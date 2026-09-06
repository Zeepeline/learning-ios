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
    @Query private var allHabits: [Habit]
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = true
    @AppStorage("userName") private var userName: String = "Bruce Wayne"
    @AppStorage("userEmail") private var userEmail: String = "brucewayne27@suarasa.com"
    @AppStorage("userBio") private var userBio: String = "Productivity Master"
    @AppStorage("userAvatarIcon") private var userAvatarIcon: String = "person.crop.circle.fill"
    @AppStorage("userAvatarColor") private var userAvatarColor: String = "#FFD166"
    @AppStorage("useBiometrics") private var useBiometrics: Bool = true
    @AppStorage("isNotificationEnabled") private var isNotificationEnabled: Bool = true
    @AppStorage("isMorningReminderEnabled") private var isMorningReminderEnabled: Bool = false
    @AppStorage("isEveningReminderEnabled") private var isEveningReminderEnabled: Bool = false
    @AppStorage("isHapticEnabled") private var isHapticEnabled: Bool = true

    @State private var isShowingLogoutDialog: Bool = false
    @State private var isShowingEditProfileSheet: Bool = false

    // Perhitungan Statistik Real-Time dari SwiftData
    private var completedTasksCount: Int {
        allItems.filter { $0.isCompleted }.count
    }

    private var importantCompletedCount: Int {
        allItems.filter { $0.priority == "Tinggi" && $0.isCompleted }.count
    }

    private var maxHabitStreak: Int {
        allHabits.map { $0.currentStreak }.max() ?? 0
    }

    private var totalXP: Int {
        (completedTasksCount * 50) + (maxHabitStreak * 25)
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
                VStack(spacing: HIGSpacing.xl) {
                    // 1. Header Profil & Avatar Kartun
                    ProfileHeaderView(
                        userName: userName,
                        userEmail: userEmail,
                        userBio: userBio,
                        avatarIcon: userAvatarIcon,
                        avatarColorHex: userAvatarColor,
                        totalXP: totalXP,
                        userLevel: userLevel,
                        xpProgressInCurrentLevel: xpProgressInCurrentLevel,
                        onEditTap: {
                            isShowingEditProfileSheet = true
                        }
                    )

                    // 2. Statistik Aktivitas Kartun (Grid 2 Kolom Real-Time)
                    ProfileStatsView(
                        completedTasksCount: completedTasksCount,
                        allItemsCount: allItems.count,
                        importantCompletedCount: importantCompletedCount,
                        maxHabitStreak: maxHabitStreak
                    )

                    // 3. Pengaturan & Preferensi
                    ProfileSettingsSection(
                        useBiometrics: $useBiometrics,
                        isNotificationEnabled: $isNotificationEnabled,
                        isMorningReminderEnabled: $isMorningReminderEnabled,
                        isEveningReminderEnabled: $isEveningReminderEnabled,
                        isHapticEnabled: $isHapticEnabled
                    )

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
        .sheet(isPresented: $isShowingEditProfileSheet) {
            EditProfileView()
                .presentationDetents([.fraction(0.88), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: Item.self, inMemory: true)
}
