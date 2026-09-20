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
            // MARK: - Baris Utama: Checkbox Selesai + Ikon Kategori + Judul + Hapus
            HStack(alignment: .top, spacing: 10) {
                // 1. 🔘 Checkbox Selesai (Mint Checkmark)
                checkboxButton
                    .padding(.top, 2)

                // 2. 🏷️ Ikon Kategori dalam Lingkaran di Samping Kiri Judul
                categoryIconCircle
                    .padding(.top, 2)

                // 3. 📝 Judul Tugas & Waktu Selesai
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 14.5, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.black)
                        .strikethrough(true, color: Color.black.opacity(0.7))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    // Metadata Selesai
                    if let completedAt = item.completedAt {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text(completedAt, format: Date.FormatStyle(date: .omitted, time: .shortened))
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(Color.black.opacity(0.85))
                        .padding(.top, 1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap?()
                }

                // 4. 🛠️ Tombol Aksi (Expand & Delete)
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
                .shadow(color: .black, radius: 0, x: 1, y: 1)
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
                    .shadow(color: .black, radius: 0, x: 1, y: 1)

                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.black)
            }
            .frame(width: 30, height: 30)
            .contentShape(Rectangle())
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
    }

    // MARK: - 🏷️ Lingkaran Ikon Kategori
    private var categoryIconCircle: some View {
        let icon = categoryIcon(for: item.category)
        return ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(Color.black, lineWidth: 1.2))

            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.black)
        }
    }

    // MARK: - 🔽 Expand Button
    private var expandButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isExpanded.toggle()
                HapticManager.shared.selection()
            }
        } label: {
            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.5))
    }

    // MARK: - 🗑️ Delete Button
    private var deleteButton: some View {
        Button {
            HapticManager.shared.warning()
            onDelete()
        } label: {
            Image(systemName: "trash.circle.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.red)
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.5))
    }

    // MARK: - 📋 Subtasks & Catatan Tambahan (Expanded State)
    private var expandedDetailsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
                .overlay(Color.black.opacity(0.3))

            // Catatan
            if !item.notes.isEmpty {
                Text(item.notes)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.black.opacity(0.85))
                    .padding(.vertical, 2)
            }

            // Subtask items
            if !item.subtasks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(item.subtasks) { subtask in
                        HStack(spacing: 6) {
                            Image(systemName: subtask.isCompleted ? "checkmark.square.fill" : "square")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)

                            Text(subtask.title)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Color.black)
                                .strikethrough(subtask.isCompleted, color: Color.black.opacity(0.7))
                        }
                    }
                }
                .padding(6)
                .background(Color.white)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
            }
        }
    }

    private func categoryIcon(for category: String) -> String {
        let lower = category.lowercased()
        if lower.contains("belajar") || lower.contains("study") || lower.contains("learning") {
            return "book.closed.fill"
        } else if lower.contains("kerja") || lower.contains("work") || lower.contains("kantor") {
            return "briefcase.fill"
        } else if lower.contains("coding") || lower.contains("dev") || lower.contains("program") {
            return "chevron.left.forwardslash.chevron.right"
        } else if lower.contains("olahraga") || lower.contains("gym") || lower.contains("sehat") {
            return "figure.run"
        } else if lower.contains("pribadi") || lower.contains("personal") {
            return "person.fill"
        } else if lower.contains("keuangan") || lower.contains("finance") {
            return "banknote.fill"
        } else {
            return "star.fill"
        }
    }
}
