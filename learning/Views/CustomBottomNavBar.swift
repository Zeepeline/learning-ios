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
        HStack(spacing: 8) {
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
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .cartoonCard(bgColor: .white, cornerRadius: 24, borderWidth: 2.0, shadowOffset: 3.0)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}

// Tombol Tab Kartun Interaktif
struct CartoonTabButton: View {
    let icon: String
    let title: String
    let index: Int
    @Binding var selectedTab: Int
    let activeColor: Color

    var isSelected: Bool { selectedTab == index }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedTab = index
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                
                if isSelected {
                    Text(title)
                        .font(.cartoonBadge)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .foregroundColor(.cartoonTextPrimary)
            .padding(.vertical, 8)
            .padding(.horizontal, isSelected ? 12 : 10)
            .background(isSelected ? activeColor : Color.clear)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.cartoonBorder : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(CartoonPressButtonStyle())
        .frame(maxWidth: isSelected ? .infinity : nil)
    }
}

#Preview {
    CustomBottomNavBar(selectedTab: .constant(0))
        .padding()
        .background(Color.cartoonBg)
}
