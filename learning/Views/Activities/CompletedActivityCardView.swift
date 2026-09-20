//
//  CompletedActivityCardView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI
import SwiftData

struct CompletedActivityCardView: View {
    @Environment(\.modelContext) private var modelContext
    let item: Item
    var onToggle: () -> Void
    var onDelete: () -> Void

    @State private var isExpanded: Bool = false

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // MARK: - Baris Utama: Checkbox + Judul Strikethrough + Tanggal Selesai + Tombol
            HStack(alignment: .top, spacing: 10) {
                // 1. Checkbox Lingkaran Hijau (Bisa di-uncheck)
                completedCheckbox

                // 2. Ikon Kategori
                categoryIconCircle

                // 3. Judul & Waktu Selesai (Multiline)
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 14.5, weight: .bold, design: .rounded))
                        .foregroundColor(Color.black.opacity(0.85))
                        .strikethrough(true, color: Color.black.opacity(0.7))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    // Waktu Selesai & Tanggal
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.cartoonMint)

                        Text("Selesai: \(formattedCompletionDate(item.completedAt ?? item.timestamp))")
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.black.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 4. Tombol Aksi (Expand jika ada detail, & Delete)
                HStack(spacing: 6) {
                    if !item.subtasks.isEmpty || !item.notes.isEmpty {
                        expandButton
                    }
                    deleteButton
                }
                .padding(.top, 2)
            }

            // MARK: - Detail Tambahan (Jika Di-expand)
            if isExpanded {
                expandedDetailsView
            }
        }
        .padding(.horizontal, HIGSpacing.md)
        .padding(.vertical, HIGSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .fill(Color(red: 0.94, green: 0.94, blue: 0.94))
                .shadow(color: .black, radius: 0, x: 1, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: 1.2)
        )
    }

    // MARK: - Checkbox Lingkaran Mint Selesai
    private var completedCheckbox: some View {
        Button {
            HapticManager.shared.impact(style: .medium)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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

    // MARK: - Lingkaran Ikon Kategori
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

    // MARK: - Expand Button (Cartoonish Circle Badge)
    private var expandButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isExpanded.toggle()
                HapticManager.shared.selection()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 26, height: 26)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1.3))
                    .shadow(color: .black, radius: 0, x: 1, y: 1)

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.black)
            }
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))
    }

    // MARK: - Delete Button (Cartoonish Coral Badge with Heavy Trash Icon)
    private var deleteButton: some View {
        Button {
            HapticManager.shared.warning()
            onDelete()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.cartoonCoral)
                    .frame(width: 26, height: 26)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1.3))
                    .shadow(color: .black, radius: 0, x: 1, y: 1)

                Image(systemName: "trash.fill")
                    .font(.system(size: 11.5, weight: .black))
                    .foregroundColor(.black)
            }
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))
    }

    // MARK: - Subtasks & Catatan Tambahan (Expanded State)
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

                            Spacer()
                        }
                    }
                }
                .padding(6)
                .background(Color.white)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 0.8))
            }
        }
    }

    // MARK: - Formatter Tanggal Selesai
    private func formattedCompletionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Hari ini, \(date.formatted(date: .omitted, time: .shortened))"
        } else if calendar.isDateInYesterday(date) {
            return "Kemarin, \(date.formatted(date: .omitted, time: .shortened))"
        } else {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
    }

    // MARK: - Helper Ikon Kategori
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Belajar": return "book.fill"
        case "Kerja": return "briefcase.fill"
        case "Olahraga": return "figure.run"
        case "Kesehatan": return "heart.fill"
        case "Ibadah": return "moon.stars.fill"
        case "Keuangan": return "dollarsign.circle.fill"
        default: return "checkmark.circle.fill"
        }
    }
}
