//
//  CartoonButtons.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import SwiftUI

// MARK: - 🔘 Reusable Cartoon Primary CTA Button
struct CartoonPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var bgColor: Color = Color.cartoonCoral
    var fgColor: Color = .white
    var height: CGFloat = 54
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: HIGSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
            }
            .foregroundColor(fgColor)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(bgColor)
            .cornerRadius(CartoonMetrics.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
            )
            .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.5))
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

// MARK: - 🔘 Reusable Cartoon Icon Button (44x44 Touch Target)
struct CartoonIconButton: View {
    let icon: String
    var iconColor: Color = .black
    var bgColor: Color = .white
    var size: CGFloat = HIGSpacing.touchTargetMin
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .black))
                .foregroundColor(iconColor)
                .frame(width: size, height: size)
                .background(bgColor)
                .cornerRadius(CartoonMetrics.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: CartoonMetrics.cornerRadius)
                        .stroke(Color.black, lineWidth: 1.8)
                )
                .shadow(color: .black, radius: 0, x: 2, y: 2)
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
    }
}

#Preview {
    VStack(spacing: 20) {
        CartoonPrimaryButton(title: "Create Task", action: {})
        CartoonIconButton(icon: "xmark", action: {})
    }
    .padding()
}
