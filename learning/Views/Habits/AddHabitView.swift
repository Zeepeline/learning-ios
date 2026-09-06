//
//  AddHabitView.swift
//  learning
//
//  Created by macbook on 9/6/26.
//

import SwiftUI
import SwiftData
import WidgetKit

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var title: String = ""
    @State private var selectedCategory: String = "Kesehatan"
    @State private var selectedIcon: String = "flame.fill"
    @State private var selectedColorHex: String = "#FF6B6B"
    @State private var selectedFrequency: String = "Harian"
    
    // Preset Icon Pilihan Kartun
    private let availableIcons = [
        "flame.fill", "drop.fill", "book.fill", "figure.run",
        "bed.double.fill", "fork.knife", "brain.head.profile", "moon.stars.fill",
        "heart.fill", "bolt.fill", "pencil.and.outline", "leaf.fill"
    ]
    
    // Preset Warna Pastel Kartun
    private let availableColors = [
        ("#FF6B6B", "Merah Coral"),
        ("#FFD166", "Kuning"),
        ("#06D6A0", "Hijau Mint"),
        ("#118AB2", "Biru Langit"),
        ("#B388FF", "Ungu Lavender"),
        ("#FF9E79", "Oranye Pastel")
    ]
    
    private let categories = ["Kesehatan", "Belajar", "Olahraga", "Mindfulness", "Produktivitas"]
    private let frequencies = ["Harian", "Hari Kerja", "Akhir Pekan"]
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: HIGSpacing.md) {
                    // 1. Preview Kartun Interaktif
                    VStack(spacing: 8) {
                        Text("PREVIEW KEBIASAAN")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: selectedColorHex))
                                    .frame(width: 46, height: 46)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.8))
                                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                                
                                Image(systemName: selectedIcon)
                                    .font(.system(size: 20, weight: .black))
                                    .foregroundColor(.black)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(title.isEmpty ? "Nama Kebiasaan..." : title)
                                    .font(.system(size: 14.5, weight: .heavy, design: .rounded))
                                    .foregroundColor(title.isEmpty ? .secondary : .black)
                                    .lineLimit(1)
                                
                                HStack(spacing: 6) {
                                    Text(selectedCategory)
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.white)
                                        .cornerRadius(6)
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1))
                                    
                                    Text(selectedFrequency)
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 1.8))
                        .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    
                    // 2. Input Nama Kebiasaan
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NAMA KEBIASAAN")
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        TextField("Contoh: Minum 2L Air / Baca 15 Menit", text: $title)
                            .font(.system(size: 13.5, weight: .bold, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.5))
                            .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    
                    // 3. Pilihan Icon Kartun
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PILIH IKON")
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                            ForEach(availableIcons, id: \.self) { icon in
                                let isSelected = selectedIcon == icon
                                Button {
                                    HapticManager.shared.selection()
                                    selectedIcon = icon
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isSelected ? Color.cartoonYellow : Color.white)
                                            .frame(height: 44)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.black, lineWidth: isSelected ? 2.0 : 1.2)
                                            )
                                            .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                                        
                                        Image(systemName: icon)
                                            .font(.system(size: 16, weight: .black))
                                            .foregroundColor(.black)
                                    }
                                }
                                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                            }
                        }
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    
                    // 4. Pilihan Warna Tema
                    VStack(alignment: .leading, spacing: 6) {
                        Text("WARNA TEMA")
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 10) {
                            ForEach(availableColors, id: \.0) { hex, _ in
                                let isSelected = selectedColorHex == hex
                                Button {
                                    HapticManager.shared.selection()
                                    selectedColorHex = hex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black, lineWidth: isSelected ? 2.4 : 1.2)
                                        )
                                        .overlay(
                                            isSelected ?
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 13, weight: .black))
                                                .foregroundColor(.black)
                                            : nil
                                        )
                                        .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                                }
                                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                            }
                        }
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    
                    // 5. Pilihan Kategori
                    VStack(alignment: .leading, spacing: 6) {
                        Text("KATEGORI")
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { cat in
                                    let isSelected = selectedCategory == cat
                                    Button {
                                        HapticManager.shared.selection()
                                        selectedCategory = cat
                                    } label: {
                                        Text(cat)
                                            .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(isSelected ? Color.cartoonMint : Color.white)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.black, lineWidth: isSelected ? 1.8 : 1.1)
                                            )
                                            .shadow(color: .black, radius: 0, x: isSelected ? 1.5 : 1, y: isSelected ? 1.5 : 1)
                                    }
                                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                                }
                            }
                            .padding(.horizontal, HIGSpacing.md)
                        }
                        .padding(.horizontal, -HIGSpacing.md)
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    
                    // 6. Tombol Simpan Kebiasaan
                    Button {
                        saveHabit()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14, weight: .black))
                            Text("Buat Kebiasaan Baru")
                                .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(title.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.3) : Color.cartoonYellow)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.8))
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.horizontal, HIGSpacing.md)
                    .padding(.top, 6)
                }
                .padding(.vertical, HIGSpacing.md)
            }
            .background(Color.cartoonBg)
            .navigationTitle("Tambah Kebiasaan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Batal") {
                        dismiss()
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                }
            }
        }
    }
    
    private func saveHabit() {
        let cleanTitle = title.trimmingCharacters(in: .whitespaces)
        guard !cleanTitle.isEmpty else { return }
        
        let newHabit = Habit(
            title: cleanTitle,
            icon: selectedIcon,
            colorHex: selectedColorHex,
            category: selectedCategory,
            targetFrequency: selectedFrequency,
            completedDates: [],
            createdAt: Date()
        )
        
        modelContext.insert(newHabit)
        try? modelContext.save()
        
        HapticManager.shared.success()
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}

#Preview {
    AddHabitView()
}
