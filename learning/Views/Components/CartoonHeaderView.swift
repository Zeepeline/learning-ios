//
//  CartoonHeaderView.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import SwiftUI

// MARK: - 🎨 Reusable Cartoon Top Header Bar
struct CartoonHeaderView: View {
    let title: String
    let onLeadingTap: () -> Void
    var trailingAction: (() -> Void)?
    var trailingTitle: String = "Tambah"
    var trailingIcon: String = "plus"
    var trailingBgColor: Color = Color.cartoonYellow

    var body: some View {
        HStack(spacing: HIGSpacing.md) {
            // 🍔 Tombol Hamburger Menu Kartun Pop (Min 44x44 Touch Target)
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    onLeadingTap()
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.cartoonTextPrimary)
                    .frame(width: HIGSpacing.touchTargetMin, height: HIGSpacing.touchTargetMin)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1.8)
                    )
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))

            Spacer()

            // Judul Header
            Text(title)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.cartoonTextPrimary)

            Spacer()

            // Tombol Aksi Kanan (Opsional)
            if let trailingAction = trailingAction {
                Button {
                    trailingAction()
                } label: {
                    HStack(spacing: HIGSpacing.xxs) {
                        Image(systemName: trailingIcon)
                            .font(.system(size: 13, weight: .black))
                        Text(trailingTitle)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.cartoonTextPrimary)
                    .padding(.horizontal, HIGSpacing.sm)
                    .frame(height: HIGSpacing.touchTargetMin)
                    .background(trailingBgColor)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1.8)
                    )
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
            } else {
                // Penyeimbang layout simetris (44x44)
                Color.clear
                    .frame(width: HIGSpacing.touchTargetMin, height: HIGSpacing.touchTargetMin)
            }
        }
        .padding(.horizontal, HIGSpacing.md)
        .padding(.vertical, HIGSpacing.xs)
    }
}

#Preview {
    CartoonHeaderView(
        title: "Aktivitas",
        onLeadingTap: {},
        trailingAction: {}
    )
    .padding()
}
