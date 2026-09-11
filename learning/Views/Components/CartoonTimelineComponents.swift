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

    var body: some View {
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
                        Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(isSelected ? .white : .secondary)

                        // Angka Tanggal (14, 15, 17...)
                        Text(date.formatted(.dateTime.day()))
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

    var body: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.xs) {
            // Header Kartu: Judul & Menu More (•••)
            HStack(alignment: .top) {
                Button {
                    onTap?()
                } label: {
                    Text(title)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .strikethrough(isCompleted, color: .black)
                        .opacity(isCompleted ? 0.6 : 1.0)
                        .multilineTextAlignment(.leading)
                }
                .buttonStyle(.plain)

                Spacer()

                Menu {
                    Button("Edit Tugas") {
                        onTap?()
                    }
                    Button(isCompleted ? "Tandai Belum Selesai" : "Tandai Selesai") {
                        onToggle()
                    }
                    Button("Hapus Tugas", role: .destructive) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
            }

            // Waktu Tugas
            HStack(spacing: 6) {
                Text(timeText)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
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
                    .overlay(Capsule().stroke(Color.black, lineWidth: 1.0))
                }
            }

            // Category Pill (Jika Ada)
            if !category.isEmpty {
                Text(category)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, HIGSpacing.sm)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.94, green: 0.94, blue: 0.94))
                    )
                    .padding(.top, 2)
            }

            // Catatan Tugas / Notes (Jika Ada)
            if !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(HIGSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isCompleted ? Color.gray.opacity(0.12) : Color.white)
                .shadow(color: .black, radius: 0, x: 2, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
    }
}

// MARK: - ➕ Reusable Input Cepat Subtask ("Add new subtask")
struct CartoonQuickAddBar: View {
    let timeLabel: String
    @Binding var text: String
    let onSubmit: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: HIGSpacing.sm) {
            Text(timeLabel)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 58, alignment: .leading)

            HStack(spacing: HIGSpacing.xs) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.secondary)

                TextField("Add new subtask...", text: $text)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .submitLabel(.done)
                    .onSubmit {
                        onSubmit()
                    }

                if !text.isEmpty {
                    Button(action: onSubmit) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.black)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, HIGSpacing.md)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.black, lineWidth: 1.5)
            )
        }
        .padding(.vertical, 4)
    }
}
