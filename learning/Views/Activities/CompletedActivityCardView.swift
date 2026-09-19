//
//  CompletedActivityCardView.swift
//  learning
//
//  Created by macbook on 9/18/26.
//

import SwiftUI
import SwiftData

struct CompletedActivityCardView: View {
    let item: Item
    var onToggle: () -> Void
    var onDelete: () -> Void
    var onTap: (() -> Void)?

    @State private var isExpanded: Bool = false

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: - Baris Utama: Checkbox + Konten Selesai + Tombol Hapus
            HStack(alignment: .top, spacing: 12) {
                // 1. 🔘 Checkbox Selesai (Mint Checkmark)
                checkboxButton
                    .padding(.top, 2)

                // 2. 📝 Judul Tugas & Metadata Selesai
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title)
                        .font(.system(size: 14.5, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.black.opacity(0.7))
                        .strikethrough(true, color: Color.black.opacity(0.6))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    // Metadata Chips (Kategori & Waktu Selesai)
                    HStack(spacing: 6) {
                        if !item.category.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 9, weight: .bold))
                                Text(item.category)
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.black.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(Color.white.opacity(0.6))
                            .cornerRadius(5)
                        }

                        if let completedAt = item.completedAt {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 9, weight: .bold))
                                Text(completedAt, format: Date.FormatStyle(date: .omitted, time: .shortened))
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(Color.black.opacity(0.6))
                        }

                        Spacer(minLength: 0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap?()
                }

                // 3. 🛠️ Tombol Aksi (Expand & Delete)
                HStack(spacing: 6) {
                    if !item.subtasks.isEmpty || !item.notes.isEmpty {
                        expandButton
                    }
                    deleteButton
                }
                .padding(.top, 2)
            }

            // MARK: - Subtasks / Catatan Tambahan (Jika Di-expand)
            if isExpanded {
                expandedDetailsView
            }
        }
        .padding(.horizontal, HIGSpacing.md)
        .padding(.vertical, HIGSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .fill(Color(red: 0.94, green: 0.96, blue: 0.95))
                .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
    }

    // MARK: - 🔘 Checkbox Button
    private var checkboxButton: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) {
                SoundManager.shared.playPop()
                onToggle()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.cartoonMint)
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2.0))
                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)

                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.black)
            }
            .frame(width: 32, height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
    }

    // MARK: - 🔼 Expand Button
    private var expandButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isExpanded.toggle()
                HapticManager.shared.selection()
            }
        } label: {
            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black.opacity(0.6))
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
    }

    // MARK: - 🗑️ Delete Button
    private var deleteButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                SoundManager.shared.playDeleteSound()
                onDelete()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.cartoonPink.opacity(0.85))
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1.8))
                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)

                Image(systemName: "trash.fill")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.black)
            }
            .frame(width: 32, height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
    }

    // MARK: - 📋 Expanded Details View
    private var expandedDetailsView: some View {
        VStack(alignment: .leading, spacing: 5) {
            Divider()
                .background(Color.black.opacity(0.12))
                .padding(.vertical, 2)

            if !item.notes.isEmpty {
                Text(item.notes)
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundColor(.black.opacity(0.6))
                    .padding(.bottom, 2)
            }

            if !item.subtasks.isEmpty {
                ForEach(item.subtasks) { subtask in
                    HStack(spacing: 6) {
                        Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(subtask.isCompleted ? Color.cartoonMint : Color.secondary)

                        Text(subtask.title)
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .foregroundColor(.black.opacity(0.6))
                            .strikethrough(subtask.isCompleted)

                        Spacer()
                    }
                }
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }
}
