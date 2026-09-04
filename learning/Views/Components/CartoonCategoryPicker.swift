//
//  CartoonCategoryPicker.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import SwiftUI

// MARK: - 🏷️ Model Kategori Kartun
struct CategoryItem: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    let color: Color
}

// MARK: - 🎨 Kumpulan Kategori Default
enum DefaultCategories {
    static let all: [CategoryItem] = [
        CategoryItem(id: "Design", name: "Design", icon: "paintbrush.pointed.fill", color: .cartoonYellow),
        CategoryItem(id: "Development", name: "Development", icon: "hammer.fill", color: .cartoonMint),
        CategoryItem(id: "Coding", name: "Coding", icon: "chevron.left.forwardslash.chevron.right", color: .cartoonBlue),
        CategoryItem(id: "Meeting", name: "Meeting", icon: "person.2.fill", color: .cartoonPink),
        CategoryItem(id: "Office Time", name: "Office Time", icon: "building.2.fill", color: .cartoonLavender),
        CategoryItem(id: "User Experience", name: "User Experience", icon: "sparkles", color: .cartoonOrange)
    ]
}

// MARK: - 🎨 Reusable Chip Kategori Kartun Tunggal
struct CartoonCategoryChip: View {
    let item: CategoryItem
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                onSelect()
            }
        } label: {
            HStack(spacing: 6) {
                // Ikon Stiker Kartun Bulat Mini
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white : item.color.opacity(0.85))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: 1.4)
                        )
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.black)
                }

                // Teks Nama Kategori
                Text(item.name)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? item.color : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: isSelected ? 2.2 : 1.6)
            )
            .shadow(
                color: .black,
                radius: 0,
                x: isSelected ? 2.5 : 1.5,
                y: isSelected ? 2.5 : 1.5
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
    }
}

// MARK: - 🎨 Reusable Kategori Picker Grid
struct CartoonCategoryPicker: View {
    @Binding var selectedCategory: String
    var categories: [CategoryItem] = DefaultCategories.all

    var body: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            HStack(spacing: HIGSpacing.xs) {
                Text("Category")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
            }

            // Baris 1 Kategori
            HStack(spacing: HIGSpacing.xs) {
                ForEach(categories.prefix(3)) { item in
                    CartoonCategoryChip(
                        item: item,
                        isSelected: selectedCategory == item.name,
                        onSelect: { selectedCategory = item.name }
                    )
                }
            }

            // Baris 2 Kategori
            HStack(spacing: HIGSpacing.xs) {
                ForEach(categories.suffix(3)) { item in
                    CartoonCategoryChip(
                        item: item,
                        isSelected: selectedCategory == item.name,
                        onSelect: { selectedCategory = item.name }
                    )
                }
            }
        }
    }
}

#Preview {
    CartoonCategoryPicker(selectedCategory: .constant("Design"))
        .padding()
}
