//
//  Theme.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI

// MARK: - 🎨 Design System: Palet Warna Kartun & Neo-Brutalist
extension Color {
    /// Warna latar belakang dasar bertema retro cream/off-white
    static let cartoonBg = Color(red: 0.98, green: 0.96, blue: 0.92)
    
    /// Warna kartu & aksen pop pastel
    static let cartoonYellow = Color(red: 0.99, green: 0.88, blue: 0.55)
    static let cartoonPink = Color(red: 1.0, green: 0.78, blue: 0.78)
    static let cartoonBlue = Color(red: 0.78, green: 0.92, blue: 1.0)
    static let cartoonMint = Color(red: 0.84, green: 0.95, blue: 0.84)
    static let cartoonLavender = Color(red: 0.93, green: 0.87, blue: 1.0)
    static let cartoonOrange = Color(red: 1.0, green: 0.72, blue: 0.45)
    
    /// Warna batas border & teks tegas
    static let cartoonBorder = Color.black
    static let cartoonTextPrimary = Color.black
}

// MARK: - 🔤 Design System: Tipografi (SF Pro Rounded Modern)
extension Font {
    /// Judul Halaman / Layar Utama
    static let cartoonTitle = Font.system(.title2, design: .rounded).weight(.heavy)
    
    /// Judul Sub/Header Card
    static let cartoonHeadline = Font.system(.headline, design: .rounded).weight(.bold)
    
    /// Teks Menu & Item List
    static let cartoonSubheadline = Font.system(.subheadline, design: .rounded).weight(.bold)
    
    /// Teks Konten Biasa
    static let cartoonBody = Font.system(.body, design: .rounded).weight(.medium)
    
    /// Teks Badge, Tag, dan Keterangan Kecil
    static let cartoonBadge = Font.system(size: 11, weight: .bold, design: .rounded)
    static let cartoonCaption = Font.system(.caption, design: .rounded).weight(.bold)
}

// MARK: - 📐 Design System: Ukuran & Ketebalan
enum CartoonMetrics {
    static let borderWidth: CGFloat = 2.0
    static let thickBorderWidth: CGFloat = 2.5
    static let cornerRadius: CGFloat = 12.0
    static let cardCornerRadius: CGFloat = 14.0
    static let shadowOffset: CGFloat = 2.0
    static let hardShadowRadius: CGFloat = 0.0
}

// MARK: - 🛠️ Reusable View Modifiers (Gaya Kartun Otomatis)
struct CartoonCardModifier: ViewModifier {
    var bgColor: Color = .white
    var cornerRadius: CGFloat = CartoonMetrics.cardCornerRadius
    var borderWidth: CGFloat = CartoonMetrics.borderWidth
    var shadowOffset: CGFloat = CartoonMetrics.shadowOffset

    func body(content: Content) -> some View {
        content
            .background(bgColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.cartoonBorder, lineWidth: borderWidth)
            )
            .shadow(
                color: Color.cartoonBorder,
                radius: CartoonMetrics.hardShadowRadius,
                x: shadowOffset,
                y: shadowOffset
            )
    }
}

extension View {
    /// Mengubah view menjadi kartu bergaya kartun neo-brutalist dengan border dan hard shadow
    func cartoonCard(
        bgColor: Color = .white,
        cornerRadius: CGFloat = CartoonMetrics.cardCornerRadius,
        borderWidth: CGFloat = CartoonMetrics.borderWidth,
        shadowOffset: CGFloat = CartoonMetrics.shadowOffset
    ) -> some View {
        self.modifier(CartoonCardModifier(
            bgColor: bgColor,
            cornerRadius: cornerRadius,
            borderWidth: borderWidth,
            shadowOffset: shadowOffset
        ))
    }
}

// MARK: - 🔘 Reusable Button Style (Bouncy Press)
struct CartoonPressButtonStyle: ButtonStyle {
    var pressOffset: CGFloat = 1.5

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(x: configuration.isPressed ? pressOffset : 0, y: configuration.isPressed ? pressOffset : 0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
