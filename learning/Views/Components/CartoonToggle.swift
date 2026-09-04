//
//  CartoonToggle.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import SwiftUI

// MARK: - 🕹️ Reusable Cartoon Switch (Neo-Brutalist Toggle Switch)
struct CartoonToggleSwitch: View {
    @Binding var isOn: Bool
    var activeColor: Color = Color.cartoonMint
    var inactiveColor: Color = Color(red: 0.90, green: 0.90, blue: 0.92)

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) {
                isOn.toggle()
            }
            HapticManager.shared.selection()
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                // Background Pill Kartun
                Capsule()
                    .fill(isOn ? activeColor : inactiveColor)
                    .frame(width: 52, height: 30)
                    .overlay(
                        Capsule().stroke(Color.black, lineWidth: 2.0)
                    )
                    .shadow(color: .black, radius: 0, x: 2, y: 2)

                // Knob Bulat Kartun
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: 1.8)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 0, x: 1, y: 1)

                    // Ikon mini di dalam knob
                    if isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.black)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(width: 54, height: 44) // 44pt HIG Touch Target
            .contentShape(Rectangle())
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
    }
}

// MARK: - 🎛️ Reusable Cartoon Toggle Row (Card Container dengan Ikon & Label)
struct CartoonToggleRow: View {
    let icon: String
    var iconColor: Color = .black
    var iconBgColor: Color = Color.cartoonYellow
    let title: String
    var subtitle: String?
    @Binding var isOn: Bool
    var activeColor: Color = Color.cartoonMint

    var body: some View {
        HStack(spacing: HIGSpacing.sm) {
            // Icon Badge Kartun
            ZStack {
                Circle()
                    .fill(iconBgColor)
                    .frame(width: 34, height: 34)
                    .overlay(
                        Circle().stroke(Color.black, lineWidth: 1.8)
                    )
                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(iconColor)
            }

            // Teks Label & Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Toggle Switch Kartun
            CartoonToggleSwitch(isOn: $isOn, activeColor: activeColor)
        }
        .padding(.horizontal, HIGSpacing.md)
        .padding(.vertical, HIGSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: CartoonMetrics.cornerRadius)
                .fill(Color.white)
                .shadow(color: .black, radius: 0, x: 2, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        CartoonToggleRow(
            icon: "bell.badge.fill",
            iconColor: .black,
            iconBgColor: Color.cartoonPink,
            title: "Pengingat Notifikasi",
            subtitle: "Dapatkan alarm saat mendekati deadline",
            isOn: .constant(true),
            activeColor: Color.cartoonCoral
        )

        CartoonToggleRow(
            icon: "calendar.badge.plus",
            iconColor: .black,
            iconBgColor: Color.cartoonBlue,
            title: "Sync to Apple Calendar",
            subtitle: "Otomatis tambahkan jadwal ke kalender",
            isOn: .constant(false),
            activeColor: Color.cartoonMint
        )
    }
    .padding()
    .background(Color.cartoonBg)
}
