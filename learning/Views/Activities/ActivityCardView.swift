//
//  ActivityCardView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI
import SwiftData

struct ActivityCardView: View {
    @Environment(\.modelContext) private var modelContext
    let item: Item
    var onToggle: (() -> Void)? = nil
    var onDelete: () -> Void
    var onTap: (() -> Void)?

    @State private var isExpanded: Bool = false
    @State private var isShowingFullImage: Bool = false

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: - Baris Utama: Ikon Kategori Bulat + Judul Multiline + Aksi
            HStack(alignment: .top, spacing: 12) {
                // 1. 🏷️ Ikon Kategori dalam Lingkaran di Samping Kiri Judul (1-Tap Checkbox)
                categoryIconCircle
                    .padding(.top, 2)

                // 2. 📝 Judul Tugas & Metadata Bawah (Multiline Rapi)
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.black)
                        .strikethrough(item.isCompleted, color: Color.black.opacity(0.7))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)

                    // Catatan Singkat (Jika Ada)
                    if !item.notes.isEmpty {
                        Text(item.notes)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.black.opacity(0.85))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Baris Metadata Bawah (Waktu, Subtask Progress, Recurring, Foto)
                    bottomMetadataRow
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap?()
                }

                // 3. 🛠️ Tombol Aksi (Expand & Delete)
                HStack(spacing: 6) {
                    if !item.subtasks.isEmpty || item.imageAttachmentData != nil {
                        expandButton
                    }
                    deleteButton
                }
                .padding(.top, 2)
            }

            // MARK: - Subtasks & Foto Lampiran (Jika Di-expand)
            if isExpanded {
                expandedDetailsView
            }
        }
        .padding(.horizontal, HIGSpacing.md)
        .padding(.vertical, HIGSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .fill(item.isCompleted ? Color(red: 0.94, green: 0.94, blue: 0.94) : cardBgColor(for: item.priority))
                .shadow(color: .black, radius: 0, x: item.isCompleted ? 1 : 2, y: item.isCompleted ? 1 : 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .sheet(isPresented: $isShowingFullImage) {
            fullscreenImageSheet
        }
    }

    // MARK: - 🏷️ Lingkaran Ikon Kategori & Checkbox 1-Tap
    private var categoryIconCircle: some View {
        let (icon, color) = categoryIconAndColor(for: item.category)
        return Button {
            HapticManager.shared.success()
            SoundManager.shared.playPop()
            onToggle?()
        } label: {
            ZStack {
                Circle()
                    .fill(item.isCompleted ? Color.cartoonMint : color)
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1.6))
                    .shadow(color: .black, radius: 0, x: 1, y: 1)

                if item.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.black)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(.black)
                }
            }
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
    }

    // MARK: - 🏷️ Metadata Bawah (Waktu, Subtask, Lampiran, Recurring)
    private var bottomMetadataRow: some View {
        HStack(spacing: 6) {
            // Waktu / Jam
            HStack(spacing: 3) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(Color.black)
                Text(item.timestamp, format: Date.FormatStyle(date: .omitted, time: .shortened))
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.black)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
            .background(Color.white)
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))

            // Subtask Progress Badge
            if !item.subtasks.isEmpty {
                let completedCount = item.subtasks.filter { $0.isCompleted }.count
                HStack(spacing: 3) {
                    Image(systemName: completedCount == item.subtasks.count ? "checkmark.circle.fill" : "list.bullet")
                        .font(.system(size: 9, weight: .black))
                    Text("\(completedCount)/\(item.subtasks.count)")
                        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(completedCount == item.subtasks.count ? Color.cartoonMint : Color.cartoonYellow)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
            }

            // Recurring Badge
            if item.isRecurring {
                HStack(spacing: 3) {
                    Image(systemName: item.recurrence.icon)
                        .font(.system(size: 9, weight: .black))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(Color.cartoonLavender)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
            }

            // Photo Attachment Icon
            if item.imageAttachmentData != nil {
                Image(systemName: "paperclip")
                    .font(.system(size: 9.5, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(Color.cartoonPink)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
            }

            Spacer(minLength: 0)
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

    // MARK: - 📋 Subtasks & Foto Details (Expanded State)
    private var expandedDetailsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .overlay(Color.black.opacity(0.3))

            // Subtask items
            if !item.subtasks.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(item.subtasks.indices, id: \.self) { index in
                        let subtask = item.subtasks[index]
                        Button {
                            toggleSubtask(at: index)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: subtask.isCompleted ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(subtask.isCompleted ? .black : .black)

                                Text(subtask.title)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.black)
                                    .strikethrough(subtask.isCompleted, color: Color.black.opacity(0.7))

                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.0))
            }

            // Image Thumbnail
            if let imgData = item.imageAttachmentData, let uiImage = UIImage(data: imgData) {
                Button {
                    isShowingFullImage = true
                } label: {
                    HStack(spacing: 6) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Lampiran Gambar")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                            Text("Ketuk untuk melihat ukuran penuh")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(Color.black.opacity(0.8))
                        }
                    }
                    .padding(6)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.0))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.5))
            }
        }
    }

    // MARK: - 🖼️ Fullscreen Image Sheet
    private var fullscreenImageSheet: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let imgData = item.imageAttachmentData, let uiImage = UIImage(data: imgData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tutup") {
                        isShowingFullImage = false
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - ⚙️ Helper Methods
    private func toggleSubtask(at index: Int) {
        HapticManager.shared.selection()
        item.subtasks[index].isCompleted.toggle()
        try? modelContext.save()
    }

    private func cardBgColor(for priority: String) -> Color {
        switch priority {
        case "Tinggi": return Color.cartoonPink
        case "Sedang": return Color.cartoonYellow
        case "Rendah": return Color.cartoonMint
        default: return Color.white
        }
    }

    private func categoryIconAndColor(for category: String) -> (String, Color) {
        let lower = category.lowercased()
        if lower.contains("belajar") || lower.contains("study") || lower.contains("learning") {
            return ("book.closed.fill", .cartoonYellow)
        } else if lower.contains("kerja") || lower.contains("work") || lower.contains("kantor") {
            return ("briefcase.fill", .cartoonBlue)
        } else if lower.contains("coding") || lower.contains("dev") || lower.contains("program") {
            return ("chevron.left.forwardslash.chevron.right", .cartoonMint)
        } else if lower.contains("olahraga") || lower.contains("gym") || lower.contains("sehat") {
            return ("figure.run", .cartoonMint)
        } else if lower.contains("pribadi") || lower.contains("personal") {
            return ("person.fill", .cartoonPink)
        } else if lower.contains("keuangan") || lower.contains("finance") {
            return ("banknote.fill", .cartoonYellow)
        } else {
            return ("star.fill", .cartoonYellow)
        }
    }
}
