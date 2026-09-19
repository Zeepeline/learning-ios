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
        VStack(alignment: .leading, spacing: HIGSpacing.xs) {
            HStack(spacing: HIGSpacing.sm) {
                // 1. 🔘 Tombol Uncheck Kartun Neo-Brutalist (Mint Checkmark)
                checkboxButton

                // 2. 📝 Detail Konten Aktivitas Selesai
                taskContent

                Spacer()

                // Tombol Expand jika memiliki subtask atau catatan
                if !item.subtasks.isEmpty || !item.notes.isEmpty {
                    expandButton
                }

                // 3. 🗑️ Tombol Hapus Kartun
                deleteButton
            }

            // Expanded Subtasks / Catatan Tambahan
            if isExpanded {
                expandedDetailsView
            }
        }
        .padding(.horizontal, HIGSpacing.md)
        .padding(.vertical, HIGSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .fill(Color(red: 0.94, green: 0.96, blue: 0.95))
                .shadow(color: .black, radius: 0, x: 2.0, y: 2.0)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
    }

    // MARK: - Subviews

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
                    .frame(width: 30, height: 30)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2.0))
                    .shadow(color: .black, radius: 0, x: 1.8, y: 1.8)

                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.black)
            }
            .frame(width: HIGSpacing.touchTargetMin, height: HIGSpacing.touchTargetMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
    }

    private var taskContent: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(item.title)
                .font(.system(size: 14.5, weight: .heavy, design: .rounded))
                .foregroundColor(Color.black.opacity(0.75))
                .strikethrough(true, color: Color.black.opacity(0.6))
                .multilineTextAlignment(.leading)

            HStack(spacing: HIGSpacing.xs) {
                // Info Waktu Selesai / Timestamp
                HStack(spacing: 3) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(Color.black.opacity(0.55))
                    Text(displayDateText)
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundColor(Color.black.opacity(0.6))
                }

                // Badge Kategori
                if !item.category.isEmpty {
                    categoryBadge
                }

                // Badge Subtask Progress
                if !item.subtasks.isEmpty {
                    subtaskBadge
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }

    private var categoryBadge: some View {
        Text(item.category)
            .font(.system(size: 9.5, weight: .heavy, design: .rounded))
            .foregroundColor(.black)
            .padding(.horizontal, 6.5)
            .padding(.vertical, 2.5)
            .background(Color.cartoonMint.opacity(0.5))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.black, lineWidth: 1.0)
            )
    }

    private var subtaskBadge: some View {
        let done = item.subtasks.filter { $0.isCompleted }.count
        return HStack(spacing: 3) {
            Image(systemName: "checklist")
                .font(.system(size: 9, weight: .bold))
            Text("\(done)/\(item.subtasks.count)")
                .font(.system(size: 9.5, weight: .heavy, design: .rounded))
        }
        .foregroundColor(.black)
        .padding(.horizontal, 6)
        .padding(.vertical, 2.5)
        .background(Color.cartoonYellow.opacity(0.5))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.black, lineWidth: 1.0)
        )
    }

    private var expandButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
                HapticManager.shared.selection()
            }
        } label: {
            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black.opacity(0.55))
        }
        .buttonStyle(.plain)
    }

    private var deleteButton: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                SoundManager.shared.playDeleteSound()
                onDelete()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.cartoonPink.opacity(0.85))
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1.2))
                    .shadow(color: .black, radius: 0, x: 1.2, y: 1.2)

                Image(systemName: "trash.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
            }
            .frame(width: HIGSpacing.touchTargetMin, height: HIGSpacing.touchTargetMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))
    }

    private var expandedDetailsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
                .background(Color.black.opacity(0.2))

            if !item.notes.isEmpty {
                Text(item.notes)
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }

            if !item.subtasks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(item.subtasks) { subtask in
                        HStack(spacing: 6) {
                            Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(subtask.isCompleted ? .cartoonMint : .secondary)

                            Text(subtask.title)
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                .foregroundColor(subtask.isCompleted ? .secondary : .black)
                                .strikethrough(subtask.isCompleted)
                        }
                    }
                }
            }
        }
        .padding(.top, 2)
    }

    private var displayDateText: String {
        let date = item.completedAt ?? item.timestamp
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
            return "Hari ini, \(formatter.string(from: date))"
        } else if Calendar.current.isDateInYesterday(date) {
            formatter.dateFormat = "HH:mm"
            return "Kemarin, \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "dd MMM, HH:mm"
            return formatter.string(from: date)
        }
    }
}
