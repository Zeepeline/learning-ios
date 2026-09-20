//
//  CartoonTimelineComponents.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import SwiftUI

// MARK: - 📅 Reusable Strip Seleksi Hari Mingguan
struct CartoonWeeklyStrip: View {
    @Binding var selectedDate: Date
    let weekDays: [Date]
    var taskCountForDate: ((Date) -> (total: Int, completed: Int))? = nil

    private let calendar = Calendar.current

    dynamic var body: some View {
        HStack(spacing: HIGSpacing.xs) {
            ForEach(weekDays, id: \.self) { date in
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let isToday = calendar.isDateInToday(date)
                let taskStats = taskCountForDate?(date) ?? (total: 0, completed: 0)

                Button {
                    HapticManager.shared.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedDate = date
                    }
                } label: {
                    VStack(spacing: 4) {
                        // Nama Hari (SEN, SEL, RAB / MON, TUE, WED...)
                        Text(CalendarDateCache.shared.formatWeekday(date))
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(isSelected ? .white : .secondary)

                        // Angka Tanggal (14, 15, 17...)
                        Text(CalendarDateCache.shared.formatDay(date))
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(isSelected ? .white : .black)

                        // Indikator Titik Tugas (Task Dots)
                        HStack(spacing: 3) {
                            if taskStats.total > 0 {
                                Circle()
                                    .fill(
                                        isSelected
                                            ? Color.white
                                            : (taskStats.completed == taskStats.total ? Color.cartoonMint : Color.cartoonCoral)
                                    )
                                    .frame(width: 5, height: 5)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black, lineWidth: isSelected ? 0.8 : 0.8)
                                    )
                            } else {
                                // Spacer dot transparan untuk menjaga tinggi konsisten
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 5, height: 5)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                isSelected
                                    ? Color.cartoonCoral
                                    : (isToday ? Color.cartoonYellow.opacity(0.35) : Color.white)
                            )
                            .shadow(
                                color: isSelected ? .black : (isToday ? Color.black.opacity(0.15) : Color.black.opacity(0.08)),
                                radius: 0,
                                x: isSelected ? 2 : 1,
                                y: isSelected ? 2 : 1
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                Color.black,
                                lineWidth: isSelected ? 2.0 : (isToday ? 1.5 : 1.2)
                            )
                    )
                    .scaleEffect(isSelected ? 1.04 : 1.0)
                    .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isSelected)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
        }
    }
}

// MARK: - 🗂️ Reusable Kartu Timeline Aktivitas (Item)
struct CartoonTimelineCard: View {
    let title: String
    let timeText: String
    var category: String = ""
    var notes: String = ""
    var isCompleted: Bool = false
    var isRecurring: Bool = false
    var recurrenceTitle: String = ""
    let onToggle: () -> Void
    let onDelete: () -> Void
    var onTap: (() -> Void)?

    dynamic var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // 1-Tap Animated Cartoon Checkbox
            Button {
                HapticManager.shared.success()
                if !isCompleted {
                    SoundManager.shared.playSuccessChime()
                } else {
                    SoundManager.shared.playPop()
                }
                withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                    onToggle()
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isCompleted ? Color.cartoonMint : Color.white)
                        .frame(width: 24, height: 24)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.6))
                        .shadow(color: .black, radius: 0, x: 1, y: 1)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.black)
                    }
                }
                .padding(.top, 2)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))

            // Main Content Body
            VStack(alignment: .leading, spacing: 4) {
                // Header Kartu: Judul & Menu More (•••)
                HStack(alignment: .top) {
                    Button {
                        HapticManager.shared.selection()
                        onTap?()
                    } label: {
                        Text(title)
                            .font(.system(size: 14.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                            .strikethrough(isCompleted, color: .black.opacity(0.6))
                            .opacity(isCompleted ? 0.6 : 1.0)
                            .multilineTextAlignment(.leading)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Menu {
                        Button {
                            onTap?()
                        } label: {
                            Label("Edit Tugas", systemImage: "pencil")
                        }
                        Button {
                            onToggle()
                        } label: {
                            Label(isCompleted ? "Tandai Belum Selesai" : "Tandai Selesai", systemImage: isCompleted ? "circle" : "checkmark.circle")
                        }
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Hapus Tugas", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.black.opacity(0.7))
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                }

                // Waktu & Recurring Tag
                HStack(spacing: 6) {
                    Text(timeText)
                        .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)

                    if isRecurring && !recurrenceTitle.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "repeat")
                                .font(.system(size: 8, weight: .bold))
                            Text(recurrenceTitle)
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cartoonLavender)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.black, lineWidth: 0.9))
                    }

                    if !category.isEmpty {
                        Text(category)
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(categoryBadgeColor(for: category))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.black, lineWidth: 0.8))
                    }
                }

                // Catatan Tugas / Notes (Jika Ada)
                if !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 1)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isCompleted ? Color.black.opacity(0.04) : Color.white)
                .shadow(color: .black, radius: 0, x: isCompleted ? 1 : 2, y: isCompleted ? 1 : 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
    }

    private func categoryBadgeColor(for cat: String) -> Color {
        let lower = cat.lowercased()
        if lower.contains("belajar") || lower.contains("learning") { return .cartoonYellow }
        if lower.contains("kerja") || lower.contains("work") || lower.contains("coding") { return .cartoonBlue }
        if lower.contains("sehat") || lower.contains("health") || lower.contains("olahraga") { return .cartoonMint }
        if lower.contains("desain") || lower.contains("design") { return .cartoonLavender }
        if lower.contains("keuangan") || lower.contains("finance") { return .cartoonMint.opacity(0.7) }
        return Color(red: 0.92, green: 0.92, blue: 0.94)
    }
}

// MARK: - ➕ Reusable Input Cepat Subtask ("Add new subtask")
struct CartoonQuickAddBar: View {
    let timeLabel: String
    @Binding var text: String
    let onSubmit: () -> Void

    dynamic var body: some View {
        HStack(alignment: .center, spacing: HIGSpacing.sm) {
            Text(timeLabel)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 58, alignment: .leading)

            HStack(spacing: HIGSpacing.xs) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.secondary)

                TextField("Tambah aktivitas cepat...", text: $text)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .onSubmit {
                        onSubmit()
                    }

                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        onSubmit()
                    } label: {
                        Text("Simpan")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.cartoonYellow)
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: 1.2)
            )
            .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
        }
    }
}
