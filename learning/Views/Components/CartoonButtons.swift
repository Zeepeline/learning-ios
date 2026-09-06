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
    var icon: String?
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
            .background(
                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                    .fill(bgColor)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
            )
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
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
                .background(
                    RoundedRectangle(cornerRadius: CartoonMetrics.cornerRadius)
                        .fill(bgColor)
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CartoonMetrics.cornerRadius)
                        .stroke(Color.black, lineWidth: 1.8)
                )
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
    }
}

// MARK: - 🌐 Google 4-Color Vector Logo
struct GoogleLogoView: View {
    var size: CGFloat = 20

    var body: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let s = min(w, h)
            let scale = s / 24.0
            let cx = w / 2.0
            let cy = h / 2.0

            context.translateBy(x: cx - 12.0 * scale, y: cy - 12.0 * scale)
            context.scaleBy(x: scale, y: scale)

            // Red segment (top)
            var redPath = Path()
            redPath.move(to: CGPoint(x: 12, y: 5))
            redPath.addCurve(to: CGPoint(x: 17.0, y: 7.0), control1: CGPoint(x: 13.9, y: 5), control2: CGPoint(x: 15.6, y: 5.7))
            redPath.addLine(to: CGPoint(x: 20.6, y: 3.4))
            redPath.addCurve(to: CGPoint(x: 12, y: 0), control1: CGPoint(x: 18.3, y: 1.2), control2: CGPoint(x: 15.3, y: 0))
            redPath.addCurve(to: CGPoint(x: 1.3, y: 6.6), control1: CGPoint(x: 7.3, y: 0), control2: CGPoint(x: 3.3, y: 2.6))
            redPath.addLine(to: CGPoint(x: 5.3, y: 9.7))
            redPath.addCurve(to: CGPoint(x: 12, y: 5), control1: CGPoint(x: 6.3, y: 6.9), control2: CGPoint(x: 8.9, y: 5))
            redPath.closeSubpath()
            context.fill(redPath, with: .color(Color(red: 234/255, green: 67/255, blue: 53/255)))

            // Yellow segment (left)
            var yellowPath = Path()
            yellowPath.move(to: CGPoint(x: 5.3, y: 9.7))
            yellowPath.addCurve(to: CGPoint(x: 4.8, y: 12), control1: CGPoint(x: 5.0, y: 10.4), control2: CGPoint(x: 4.8, y: 11.2))
            yellowPath.addCurve(to: CGPoint(x: 5.3, y: 14.3), control1: CGPoint(x: 4.8, y: 12.8), control2: CGPoint(x: 5.0, y: 13.6))
            yellowPath.addLine(to: CGPoint(x: 1.3, y: 17.4))
            yellowPath.addCurve(to: CGPoint(x: 0, y: 12), control1: CGPoint(x: 0.5, y: 15.8), control2: CGPoint(x: 0, y: 14.0))
            yellowPath.addCurve(to: CGPoint(x: 1.3, y: 6.6), control1: CGPoint(x: 0, y: 10.0), control2: CGPoint(x: 0.5, y: 8.2))
            yellowPath.addLine(to: CGPoint(x: 5.3, y: 9.7))
            yellowPath.closeSubpath()
            context.fill(yellowPath, with: .color(Color(red: 251/255, green: 188/255, blue: 5/255)))

            // Green segment (bottom)
            var greenPath = Path()
            greenPath.move(to: CGPoint(x: 12, y: 19))
            greenPath.addCurve(to: CGPoint(x: 5.3, y: 14.3), control1: CGPoint(x: 8.9, y: 19), control2: CGPoint(x: 6.3, y: 17.1))
            greenPath.addLine(to: CGPoint(x: 1.3, y: 17.4))
            greenPath.addCurve(to: CGPoint(x: 12, y: 24), control1: CGPoint(x: 3.3, y: 21.4), control2: CGPoint(x: 7.3, y: 24))
            greenPath.addCurve(to: CGPoint(x: 20.0, y: 20.9), control1: CGPoint(x: 15.2, y: 24), control2: CGPoint(x: 18.0, y: 22.8))
            greenPath.addLine(to: CGPoint(x: 16.1, y: 17.8))
            greenPath.addCurve(to: CGPoint(x: 12, y: 19), control1: CGPoint(x: 14.9, y: 18.6), control2: CGPoint(x: 13.5, y: 19))
            greenPath.closeSubpath()
            context.fill(greenPath, with: .color(Color(red: 52/255, green: 168/255, blue: 83/255)))

            // Blue segment (right)
            var bluePath = Path()
            bluePath.move(to: CGPoint(x: 23.5, y: 12.3))
            bluePath.addCurve(to: CGPoint(x: 23.3, y: 10.0), control1: CGPoint(x: 23.5, y: 11.5), control2: CGPoint(x: 23.4, y: 10.7))
            bluePath.addLine(to: CGPoint(x: 12, y: 10.0))
            bluePath.addLine(to: CGPoint(x: 12, y: 14.5))
            bluePath.addLine(to: CGPoint(x: 18.5, y: 14.5))
            bluePath.addCurve(to: CGPoint(x: 16.1, y: 17.8), control1: CGPoint(x: 18.2, y: 15.9), control2: CGPoint(x: 17.3, y: 17.0))
            bluePath.addLine(to: CGPoint(x: 20.0, y: 20.9))
            bluePath.addCurve(to: CGPoint(x: 23.5, y: 12.3), control1: CGPoint(x: 22.3, y: 18.8), control2: CGPoint(x: 23.5, y: 15.7))
            bluePath.closeSubpath()
            context.fill(bluePath, with: .color(Color(red: 66/255, green: 133/255, blue: 244/255)))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 🔘 Reusable Cartoon Google Sign-In Button
struct CartoonGoogleSignInButton: View {
    var title: String = "Continue with Google"
    var height: CGFloat = 50
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: HIGSpacing.sm) {
                GoogleLogoView(size: 20)

                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                    .fill(Color.white)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
            )
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
    }
}

#Preview {
    VStack(spacing: 20) {
        CartoonPrimaryButton(title: "Create Task", action: {})
        CartoonGoogleSignInButton(title: "Continue with Google", action: {})
        CartoonIconButton(icon: "xmark", action: {})
    }
    .padding()
}
