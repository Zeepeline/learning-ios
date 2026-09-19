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
        VStack(alignment: .leading, spacing: HIGSpacing.xs) {
            HStack(spacing: HIGSpacing.sm) {
                // 1. 🔘 Tombol Checkbox Kartun
                checkboxButton

                // 2. 📝 Detail Konten Aktivitas
                taskContent

                Spacer()

                // Tombol Expand jika memiliki subtask atau foto
                if !item.subtasks.isEmpty || item.imageAttachmentData != nil {
                    expandButton
                }

                // 3. 🗑️ Tombol Hapus
                deleteButton
            }

            // Expanded Subtasks & Photo
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
                    .fill(item.isCompleted ? Color.cartoonMint : Color.white)
                    .frame(width: 30, height: 30)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2.0))
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                
                if item.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.black)
                }
            }
            .frame(width: HIGSpacing.touchTargetMin, height: HIGSpacing.touchTargetMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
    }

    private var taskContent: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(item.title)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(Color.black)
                .strikethrough(item.isCompleted, color: Color.black.opacity(0.8))
                .multilineTextAlignment(.leading)

            HStack(spacing: HIGSpacing.xs) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.black.opacity(0.65))
                    Text(item.timestamp, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.black.opacity(0.65))
                }

                // Badge Prioritas Kartun
                priorityBadge(for: item.priority)

                // Badge Jadwal Rutin (Scheduler)
                if item.isRecurring {
                    recurrenceBadge(for: item.recurrence)
                }

                // Badge Subtask Progress
                if !item.subtasks.isEmpty {
                    subtaskBadge(for: item)
                }

                // Badge Foto Terlampir
                if item.imageAttachmentData != nil {
                    attachmentBadge
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }

    private var expandButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isExpanded.toggle()
                HapticManager.shared.selection()
            }
        } label: {
            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black.opacity(0.7))
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
    }

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
                    .frame(width: 30, height: 30)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1.8))
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                
                Image(systemName: "trash.fill")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.black)
            }
            .frame(width: 36, height: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
    }

    private var expandedDetailsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
                .background(Color.black.opacity(0.15))
                .padding(.vertical, 2)

            // Subtasks Checklist
            if !item.subtasks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(item.subtasks.indices, id: \.self) { index in
                        let subtask = item.subtasks[index]
                        Button {
                            toggleSubtask(at: index)
                        } label: {
                            HStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(subtask.isCompleted ? Color.cartoonMint : Color.white)
                                        .frame(width: 17, height: 17)
                                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black, lineWidth: 1.2))

                                    if subtask.isCompleted {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 9, weight: .black))
                                            .foregroundColor(.black)
                                    }
                                }

                                Text(subtask.title)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                    .strikethrough(subtask.isCompleted, color: .black.opacity(0.6))

                                Spacer()
                            }
                            .padding(.vertical, 2)
                            .padding(.horizontal, 4)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))
                    }
                }
            }

            // Thumbnail Foto Terlampir (Cached & Downsampled)
            if let imgData = item.imageAttachmentData,
               let uiImg = ImageCacheManager.shared.thumbnail(for: imgData, key: "\(item.id)", targetSize: CGSize(width: 100, height: 100)) {
                HStack(spacing: 8) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipped()
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.2))
                        .shadow(color: .black.opacity(0.1), radius: 0, x: 1, y: 1)
                        .onTapGesture {
                            isShowingFullImage = true
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Foto Lampiran Referensi")
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

    // MARK: - Warna Background Kartu Terang Solid
    private func cardBgColor(for priority: String) -> Color {
        switch priority {
        case "Tinggi": return Color(red: 1.0, green: 0.88, blue: 0.88)
        case "Normal": return Color(red: 1.0, green: 0.95, blue: 0.82)
        case "Rendah": return Color(red: 0.88, green: 0.95, blue: 1.0)
        default: return .white
        }
    }

    // MARK: - Badge Prioritas Bergaya Kartun
    @ViewBuilder
    private func priorityBadge(for priority: String) -> some View {
        let (color, text) = badgeData(for: priority)
        Text(text)
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .foregroundColor(.black)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(color)
            )
            .overlay(
                Capsule().stroke(Color.black, lineWidth: 1.2)
            )
            .shadow(color: .black, radius: 0, x: 1, y: 1)
    }

    // MARK: - Badge Jadwal Rutin (Scheduler)
    @ViewBuilder
    private func recurrenceBadge(for rule: RecurrenceRule) -> some View {
        HStack(spacing: 3) {
            Image(systemName: rule.icon)
                .font(.system(size: 8, weight: .bold))
            Text(rule.shortTitle)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
        }
        .foregroundColor(.black)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule().fill(rule.badgeColor)
        )
        .overlay(
            Capsule().stroke(Color.black, lineWidth: 1.2)
        )
        .shadow(color: .black, radius: 0, x: 1, y: 1)
    }

    // MARK: - Badge Subtask Checklist
    @ViewBuilder
    private func subtaskBadge(for item: Item) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "checklist")
                .font(.system(size: 8, weight: .bold))
            Text("\(item.completedSubtasksCount)/\(item.totalSubtasksCount)")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
        }
        .foregroundColor(.black)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule().fill(item.subtaskProgress == 1.0 ? Color.cartoonMint : Color.cartoonLavender)
        )
        .overlay(
            Capsule().stroke(Color.black, lineWidth: 1.2)
        )
        .shadow(color: .black, radius: 0, x: 1, y: 1)
    }

    // MARK: - Badge Foto Terlampir
    @ViewBuilder
    private var attachmentBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "photo.fill")
                .font(.system(size: 8, weight: .bold))
        }
        .foregroundColor(.black)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(
            Capsule().fill(Color.cartoonPink)
        )
        .overlay(
            Capsule().stroke(Color.black, lineWidth: 1.2)
        )
        .shadow(color: .black, radius: 0, x: 1, y: 1)
    }

    private func badgeData(for priority: String) -> (Color, String) {
        switch priority {
        case "Tinggi": return (Color.cartoonPink, "Tinggi")
        case "Normal": return (Color.cartoonYellow, "Normal")
        case "Rendah": return (Color.cartoonMint, "Rendah")
        default: return (Color.white, priority)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ActivityCardView(
            item: Item(title: "Mengerjakan Desain UI Baru", timestamp: Date(), isCompleted: false, priority: "Tinggi", isRecurring: true, recurrenceRule: "Setiap Hari"),
            onToggle: {},
            onDelete: {}
        )
        ActivityCardView(
            item: Item(title: "Meeting Evaluasi Mingguan", timestamp: Date(), isCompleted: true, priority: "Normal"),
            onToggle: {},
            onDelete: {}
        )
    }
    .padding()
    .background(Color.cartoonBg)
}
