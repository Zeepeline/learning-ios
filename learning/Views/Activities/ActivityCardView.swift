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
    var onToggle: () -> Void
    var onDelete: () -> Void
    var onTap: (() -> Void)?

    @State private var isExpanded: Bool = false
    @State private var isShowingFullImage: Bool = false

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: - Baris Utama: Checkbox + Konten Teks Multiline + Aksi
            HStack(alignment: .top, spacing: 12) {
                // 1. 🔘 Checkbox Kartun
                checkboxButton
                    .padding(.top, 2)

                // 2. 📝 Judul Tugas & Metadata Vertikal (Multiline Rapi)
                VStack(alignment: .leading, spacing: 6) {
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
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Color.black.opacity(0.65))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Baris Metadata (Waktu, Kategori, Subtask Progress, Lampiran)
                    metadataChipsRow
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
                .shadow(color: .black, radius: 0, x: item.isCompleted ? 1.5 : 2.5, y: item.isCompleted ? 1.5 : 2.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .sheet(isPresented: $isShowingFullImage) {
            fullscreenImageSheet
        }
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
                    .fill(item.isCompleted ? Color.cartoonMint : Color.white)
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2.0))
                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)

                if item.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.black)
                }
            }
            .frame(width: 32, height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
    }

    // MARK: - 🏷️ Metadata Chips Row (Waktu, Kategori, Subtask, Lampiran)
    private var metadataChipsRow: some View {
        HStack(spacing: 6) {
            // Waktu / Jam
            HStack(spacing: 3) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(Color.black.opacity(0.6))
                Text(item.timestamp, format: Date.FormatStyle(date: .omitted, time: .shortened))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color.black.opacity(0.75))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.6))
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black.opacity(0.15), lineWidth: 0.8))

            // Kategori Chip
            if !item.category.isEmpty {
                HStack(spacing: 3) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text(item.category)
                        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black.opacity(0.8))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.75))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black.opacity(0.15), lineWidth: 0.8))
            }

            // Subtask Progress Badge
            if !item.subtasks.isEmpty {
                let completedCount = item.subtasks.filter { $0.isCompleted }.count
                HStack(spacing: 3) {
                    Image(systemName: completedCount == item.subtasks.count ? "checkmark.circle.fill" : "list.bullet")
                        .font(.system(size: 9, weight: .bold))
                    Text("\(completedCount)/\(item.subtasks.count)")
                        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(completedCount == item.subtasks.count ? Color.cartoonMint : Color.cartoonYellow.opacity(0.7))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
            }

            // Recurring Badge
            if item.isRecurring {
                HStack(spacing: 3) {
                    Image(systemName: item.recurrence.icon)
                        .font(.system(size: 9, weight: .bold))
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
                    .background(Color.cartoonPink.opacity(0.7))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
            }

            Spacer(minLength: 0)
        }
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
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black.opacity(0.75))
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
                    .fill(Color.cartoonPink)
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
        VStack(alignment: .leading, spacing: 6) {
            Divider()
                .background(Color.black.opacity(0.15))
                .padding(.vertical, 2)

            // Subtasks Checklist
            if !item.subtasks.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(item.subtasks.indices, id: \.self) { index in
                        let subtask = item.subtasks[index]
                        Button {
                            toggleSubtask(at: index)
                        } label: {
                            HStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(subtask.isCompleted ? Color.cartoonMint : Color.white)
                                        .frame(width: 18, height: 18)
                                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black, lineWidth: 1.2))

                                    if subtask.isCompleted {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .black))
                                            .foregroundColor(.black)
                                    }
                                }

                                Text(subtask.title)
                                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                    .strikethrough(subtask.isCompleted, color: .black.opacity(0.6))
                                    .multilineTextAlignment(.leading)

                                Spacer()
                            }
                            .padding(.vertical, 3)
                            .padding(.horizontal, 4)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))
                    }
                }
            }

            // Thumbnail Foto Terlampir
            if let imgData = item.imageAttachmentData,
               let uiImg = ImageCacheManager.shared.thumbnail(for: imgData, key: "\(item.id)", targetSize: CGSize(width: 100, height: 100)) {
                HStack(spacing: 8) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipped()
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.2))
                        .shadow(color: .black.opacity(0.1), radius: 0, x: 1, y: 1)
                        .onTapGesture {
                            isShowingFullImage = true
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Foto Lampiran")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                        Text("Ketuk untuk perbesar")
                            .font(.system(size: 9.5, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(6)
                .background(Color.white.opacity(0.7))
                .cornerRadius(8)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    @ViewBuilder
    private var fullscreenImageSheet: some View {
        if let imgData = item.imageAttachmentData, let uiImg = UIImage(data: imgData) {
            NavigationStack {
                ZStack {
                    Color.black.ignoresSafeArea()
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFit()
                        .padding()
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Tutup") {
                            isShowingFullImage = false
                        }
                        .font(.system(.body, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                    }
                }
            }
        }
    }

    private func toggleSubtask(at index: Int) {
        guard index < item.subtasks.count else { return }
        HapticManager.shared.impact(style: .light)
        SoundManager.shared.playPop()
        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            var updated = item.subtasks
            updated[index].isCompleted.toggle()
            item.subtasks = updated
            try? modelContext.save()
        }
    }

    // MARK: - Warna Background Kartu Mewakili Prioritas
    private func cardBgColor(for priority: String) -> Color {
        switch priority {
        case "Tinggi": return Color(red: 1.0, green: 0.88, blue: 0.88)      // Pastel Coral / Red
        case "Normal", "Sedang": return Color(red: 1.0, green: 0.95, blue: 0.82) // Pastel Yellow / Orange
        case "Rendah": return Color(red: 0.88, green: 0.95, blue: 1.0)     // Pastel Sky Blue
        default: return .white
        }
    }
}
