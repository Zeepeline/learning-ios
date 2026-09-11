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

// MARK: - 🎨 Kumpulan Kategori Default (Sehari-hari, Belajar, Gaya Hidup & Produktivitas)
enum DefaultCategories {
    static let all: [CategoryItem] = [
        CategoryItem(id: "Belajar", name: "Belajar", icon: "book.fill", color: .cartoonYellow),
        CategoryItem(id: "Kesehatan", name: "Kesehatan", icon: "heart.fill", color: .cartoonPink),
        CategoryItem(id: "Pekerjaan", name: "Pekerjaan", icon: "briefcase.fill", color: .cartoonLavender),
        CategoryItem(id: "Pribadi", name: "Pribadi", icon: "person.fill", color: .cartoonMint),
        CategoryItem(id: "Keuangan", name: "Keuangan", icon: "creditcard.fill", color: .cartoonBlue),
        CategoryItem(id: "Ibadah", name: "Ibadah", icon: "sparkles", color: .cartoonOrange),
        CategoryItem(id: "Rumah", name: "Rumah", icon: "house.fill", color: .cartoonYellow),
        CategoryItem(id: "Sosial", name: "Sosial", icon: "person.2.fill", color: .cartoonPink),
        CategoryItem(id: "Belanja", name: "Belanja", icon: "cart.fill", color: .cartoonMint),
        CategoryItem(id: "Design", name: "Design", icon: "paintbrush.pointed.fill", color: .cartoonLavender),
        CategoryItem(id: "Coding", name: "Coding", icon: "curlybraces", color: .cartoonBlue),
        CategoryItem(id: "Meeting", name: "Meeting", icon: "bubble.left.and.bubble.right.fill", color: .cartoonOrange)
    ]
}

// MARK: - 🏷️ Reusable Chip Kategori Kartun Tunggal
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
            HStack(spacing: 5) {
                // Ikon Stiker Kartun Bulat Mini
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white : item.color.opacity(0.85))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: 1.4)
                        )
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 9.5, weight: .heavy))
                        .foregroundColor(.black)
                }

                // Teks Nama Kategori
                Text(item.name)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(isSelected ? item.color : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: isSelected ? 2.2 : 1.4)
            )
            .shadow(
                color: .black,
                radius: 0,
                x: isSelected ? 2.5 : 1.2,
                y: isSelected ? 2.5 : 1.2
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
    }
}

// MARK: - 🎨 Reusable Kategori Picker Grid
struct CartoonCategoryPicker: View {
    @Binding var selectedCategory: String
    var categories: [CategoryItem] = DefaultCategories.all

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            HStack(spacing: HIGSpacing.xs) {
                Text("CATEGORY")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, HIGSpacing.xxs)

                Spacer()

                if !selectedCategory.isEmpty {
                    Text(selectedCategory)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(selectedCategoryColor.opacity(0.4))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
                }
            }

            // Grid 3-Kolom Kategori
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(categories) { item in
                    CartoonCategoryChip(
                        item: item,
                        isSelected: selectedCategory == item.name,
                        onSelect: {
                            HapticManager.shared.selection()
                            selectedCategory = item.name
                        }
                    )
                }
            }
        }
    }

    private var selectedCategoryColor: Color {
        categories.first(where: { $0.name == selectedCategory })?.color ?? Color.cartoonYellow
    }
}

#Preview {
    CartoonCategoryPicker(selectedCategory: .constant("Belajar"))
        .padding()
        .background(Color.cartoonBg)
}
