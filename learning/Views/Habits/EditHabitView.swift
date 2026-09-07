//
//  EditHabitView.swift
//  learning
//
//  Created by macbook on 9/7/26.
//

import SwiftUI
import SwiftData
import WidgetKit

struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var habit: Habit
    var onDelete: (() -> Void)?
    
    @State private var title: String = ""
    @State private var selectedCategory: String = "Kesehatan"
    @State private var selectedIcon: String = "flame.fill"
    @State private var selectedColorHex: String = "#FF6B6B"
    @State private var selectedFrequency: String = "Harian"
    @State private var errorMessage: String?
    
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
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
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
                                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                                    .frame(width: 46, height: 46)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.8))
                                
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
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white)
                                .shadow(color: .black, radius: 0, x: 2, y: 2)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 1.8))
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
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                            )
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.5))
                            .submitLabel(.done)
                            .onSubmit {
                                if isFormValid {
                                    saveChanges()
                                }
                            }
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
                                            .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                                            .frame(height: 44)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.black, lineWidth: isSelected ? 2.0 : 1.2)
                                            )
                                        
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
                                        .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
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
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(isSelected ? Color.cartoonMint : Color.white)
                                                    .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.black, lineWidth: isSelected ? 1.8 : 1.1)
                                            )
                                    }
                                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                                }
                            }
                            .padding(.horizontal, HIGSpacing.md)
                        }
                        .padding(.horizontal, -HIGSpacing.md)
                    }
                    .padding(.horizontal, HIGSpacing.md)

                    // 6. Pilihan Frekuensi Target
                    VStack(alignment: .leading, spacing: 6) {
                        Text("FREKUENSI TARGET")
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            ForEach(frequencies, id: \.self) { freq in
                                let isSelected = selectedFrequency == freq
                                Button {
                                    HapticManager.shared.selection()
                                    selectedFrequency = freq
                                } label: {
                                    Text(freq)
                                        .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(isSelected ? Color.cartoonYellow : Color.white)
                                                .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.black, lineWidth: isSelected ? 1.8 : 1.1)
                                        )
                                }
                                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                            }
                        }
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                            .padding(.horizontal, HIGSpacing.md)
                    }
                    
                    // 7. Tombol Simpan Perubahan
                    Button {
                        saveChanges()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .black))
                            Text("Simpan Perubahan")
                                .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isFormValid ? Color.cartoonYellow : Color.gray.opacity(0.3))
                                .shadow(color: .black, radius: 0, x: isFormValid ? 2 : 0, y: isFormValid ? 2 : 0)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.8))
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    .disabled(!isFormValid)
                    .padding(.horizontal, HIGSpacing.md)
                    .padding(.top, 6)

                    // 8. Tombol Hapus Kebiasaan
                    Button {
                        HapticManager.shared.warning()
                        dismiss()
                        onDelete?()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("Hapus Kebiasaan Ini")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: .black, radius: 0, x: 1, y: 1)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.6), lineWidth: 1.4))
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    .padding(.horizontal, HIGSpacing.md)
                    .padding(.bottom, HIGSpacing.xl)
                }
                .padding(.vertical, HIGSpacing.md)
            }
            .background(Color.cartoonBg)
            .navigationTitle("Edit Kebiasaan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Batal") {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundColor(.black)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Simpan") {
                        saveChanges()
                    }
                    .font(.system(.body, design: .rounded).weight(.black))
                    .foregroundColor(isFormValid ? .black : .gray.opacity(0.5))
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
            title = habit.title
            selectedCategory = habit.category
            selectedIcon = habit.icon
            selectedColorHex = habit.colorHex
            selectedFrequency = habit.targetFrequency
        }
    }
    
    private func saveChanges() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            habit.title = trimmedTitle
            habit.icon = selectedIcon
            habit.colorHex = selectedColorHex
            habit.category = selectedCategory
            habit.targetFrequency = selectedFrequency
            
            do {
                try modelContext.save()
                WidgetCenter.shared.reloadAllTimelines()
                HapticManager.shared.success()
                dismiss()
            } catch {
                print("⚠️ Gagal menyimpan perubahan kebiasaan: \(error.localizedDescription)")
                self.errorMessage = "Gagal menyimpan: \(error.localizedDescription)"
            }
        }
    }
}
