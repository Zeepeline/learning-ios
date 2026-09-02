//
//  CustomBottomNavBar.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI

struct CustomBottomNavBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: HIGSpacing.xs) {
            CartoonTabButton(
                icon: "list.clipboard.fill",
                title: "Tugas",
                index: 0,
                selectedTab: $selectedTab,
                activeColor: .cartoonYellow
            )
            
            CartoonTabButton(
                icon: "sun.max.fill",
                title: "Hari Ini",
                index: 1,
                selectedTab: $selectedTab,
                activeColor: .cartoonPink
            )
            
            CartoonTabButton(
                icon: "bookmark.fill",
                title: "Penting",
                index: 2,
                selectedTab: $selectedTab,
                activeColor: .cartoonBlue
            )
            
            CartoonTabButton(
                icon: "person.crop.circle.fill",
                title: "Profil",
                index: 3,
                selectedTab: $selectedTab,
                activeColor: .cartoonMint
            )
        }
        .padding(.horizontal, HIGSpacing.xs)
        .padding(.vertical, HIGSpacing.xs)
        .background(Color.white)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color.cartoonBorder, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .cartoonBorder, radius: 0, x: 2.5, y: 2.5)
        .fixedSize(horizontal: true, vertical: false) // Membungkus rapi kontennya tanpa ada gap kosong di tengah
        .padding(.bottom, 6)
    }
}

// Tombol Tab Kartun Interaktif Ramping & Proporsional (HIG Touch Compliant)
struct CartoonTabButton: View {
    let icon: String
    let title: String
    let index: Int
    @Binding var selectedTab: Int
    let activeColor: Color

    var isSelected: Bool { selectedTab == index }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = index
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .black))
                
                if isSelected {
                    Text(title)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
            }
            .foregroundColor(.cartoonTextPrimary)
            .padding(.vertical, HIGSpacing.xs)
            .padding(.horizontal, isSelected ? 14 : 10)
            .frame(minHeight: 38)
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
