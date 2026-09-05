//
//  CustomBottomNavBar.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI

struct CustomBottomNavBar: View {
    @Binding var selectedTab: Int

    private let tabs: [(icon: String, title: String, color: Color)] = [
        ("list.clipboard.fill", "Tugas", .cartoonYellow),
        ("sun.max.fill", "Hari Ini", .cartoonPink),
        ("bookmark.fill", "Penting", .cartoonBlue),
        ("hourglass.circle.fill", "Fokus", .cartoonLavender),
        ("person.crop.circle.fill", "Profil", .cartoonMint)
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<tabs.count, id: \.self) { index in
                let tab = tabs[index]
                CartoonTabButton(
                    icon: tab.icon,
                    title: tab.title,
                    index: index,
                    selectedTab: $selectedTab,
                    activeColor: tab.color
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(Color.white)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color.cartoonBorder, lineWidth: 2.2)
        )
        .shadow(color: .cartoonBorder, radius: 0, x: 3, y: 3)
        .padding(.horizontal, HIGSpacing.md)
        .padding(.bottom, 6)
    }
}

// Tombol Tab Kartun Interaktif Lebar & Proporsional (HIG Touch Compliant)
struct CartoonTabButton: View {
    let icon: String
    let title: String
    let index: Int
    @Binding var selectedTab: Int
    let activeColor: Color

    var isSelected: Bool { selectedTab == index }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                selectedTab = index
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: isSelected ? 15 : 14, weight: .black))

                if isSelected {
                    Text(title)
                        .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .foregroundColor(.cartoonTextPrimary)
            .padding(.vertical, 9)
            .padding(.horizontal, isSelected ? 14 : 10)
            .frame(maxWidth: isSelected ? .infinity : nil)
            .frame(minHeight: 42)
            .background(isSelected ? activeColor : Color.clear)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? Color.cartoonBorder : Color.clear, lineWidth: 1.8)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
    }
}

#Preview {
    CustomBottomNavBar(selectedTab: .constant(0))
        .padding()
        .background(Color.cartoonBg)
}
