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
    var leadingAction: (() -> Void)? = nil
    var leadingIcon: String = "person.crop.circle.fill"
    var leadingBgColor: Color = Color.cartoonYellow
    
    var trailingAction: (() -> Void)? = nil
    var trailingTitle: String = "Tambah"
    var trailingIcon: String = "plus"
    var trailingBgColor: Color = Color.cartoonYellow

    dynamic var body: some View {
        HStack(spacing: HIGSpacing.md) {
            // Tombol Kiri (Quick Action / Profil Avatar)
            if let leadingAction = leadingAction {
                Button {
                    leadingAction()
                } label: {
                    Image(systemName: leadingIcon)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: HIGSpacing.touchTargetMin, height: HIGSpacing.touchTargetMin)
                        .background(leadingBgColor)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 1.8)
                        )
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
            } else {
                Color.clear
                    .frame(width: HIGSpacing.touchTargetMin, height: HIGSpacing.touchTargetMin)
            }

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
        leadingAction: {},
        trailingAction: {}
    )
    .padding()
}
