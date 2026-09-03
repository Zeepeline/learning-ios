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

    private let calendar = Calendar.current

    var body: some View {
        HStack(spacing: HIGSpacing.xs) {
            ForEach(weekDays, id: \.self) { date in
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedDate = date
                    }
                } label: {
                    VStack(spacing: 6) {
                        // Nama Hari (Mon, Tue, Wed...)
                        Text(date.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(isSelected ? .white : .secondary)

                        // Angka Tanggal (14, 15, 17...)
                        Text(date.formatted(.dateTime.day()))
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(isSelected ? .white : .black)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isSelected ? Color.cartoonCoral : Color.clear)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.black, lineWidth: isSelected ? 1.8 : 0)
                    )
                    .shadow(color: isSelected ? .black : .clear, radius: 0, x: 2, y: 2)
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
            Text(timeText)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)

            // Category Pill (Jika Ada)
            if !category.isEmpty {
                Text(category)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, HIGSpacing.sm)
                    .padding(.vertical, 5)
                    .background(Color(red: 0.94, green: 0.94, blue: 0.94))
                    .cornerRadius(8)
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
        .background(isCompleted ? Color.gray.opacity(0.12) : Color.white)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
    }
}

// MARK: - ➕ Reusable Input Cepat "Add new subtask"
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

            HStack {
                TextField("Add new subtask", text: $text)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .onSubmit {
                        onSubmit()
                    }

                Spacer()

                Button {
                    onSubmit()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 28, height: 28)

                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
            .padding(.horizontal, HIGSpacing.md)
            .padding(.vertical, 10)
            .frame(minHeight: 48)
            .background(Color.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
            )
            .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
        }
    }
}
