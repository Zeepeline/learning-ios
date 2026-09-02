//
//  CartoonCalendarView.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import SwiftUI

// MARK: - 📅 Model Sel Kalender (Dengan Unique ID Anti-Bentrok)
struct CartoonDayCell: Identifiable {
    let id: String
    let dayNumber: Int?
}

// MARK: - 📅 Custom Cartoon Neo-Brutalist Calendar & Time Picker (Reusable)
struct CartoonCalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentMonth: Date = Date()

    private let calendar = Calendar.current
    private let weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    // Perhitungan Tanggal Lengkap Bebas Duplikasi ID
    private var calendarDays: [CartoonDayCell] {
        var cells: [CartoonDayCell] = []

        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let firstDayOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: currentMonth) else {
            return []
        }

        // Sunday-based weekday (Sunday = 1, Monday = 2 ... Saturday = 7)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let leadingOffset = firstWeekday - 1 // 0..6 sel kosong

        for i in 0..<leadingOffset {
            cells.append(CartoonDayCell(id: "leading-\(i)", dayNumber: nil))
        }

        for day in range {
            cells.append(CartoonDayCell(id: "day-\(day)", dayNumber: day))
        }

        return cells
    }

    var body: some View {
        VStack(spacing: HIGSpacing.sm) {
            
            // 1. Header: Bulan & Tahun + Tombol Navigasi < >
            HStack {
                // Judul Bulan & Tahun dengan SF Pro Rounded Heavy
                HStack(spacing: HIGSpacing.xxs) {
                    Text(monthYearString(from: currentMonth))
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(Color.cartoonCoral)
                }

                Spacer()

                // Shortcut "Hari Ini"
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDate = Date()
                        currentMonth = Date()
                    }
                } label: {
                    Text("Hari Ini")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, HIGSpacing.xs)
                        .padding(.vertical, 4)
                        .background(Color.cartoonYellow)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.black, lineWidth: 1.2))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                // Tombol Bulan Sebelumnya < (44pt Hit Area)
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(Color.cartoonCoral)
                        .frame(width: 32, height: 32)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                // Tombol Bulan Selanjutnya > (44pt Hit Area)
                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(Color.cartoonCoral)
                        .frame(width: 32, height: 32)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
            .padding(.horizontal, HIGSpacing.xxs)

            // 2. Baris Nama-Nama Hari (SUN, MON, TUE...) dengan SF Pro Rounded
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(height: 24)
                }
            }

            // 3. Grid Angka Tanggal Kalender
            LazyVGrid(columns: columns, spacing: HIGSpacing.xs) {
                ForEach(calendarDays) { cell in
                    if let dayNumber = cell.dayNumber {
                        let isSelected = isDaySelected(dayNumber)
                        let isToday = isDayToday(dayNumber)

                        Button {
                            selectDay(dayNumber)
                        } label: {
                            ZStack {
                                if isSelected {
                                    Circle()
                                        .fill(Color.cartoonCoral)
                                        .frame(width: 34, height: 34)
                                        .overlay(Circle().stroke(Color.black, lineWidth: 1.8))
                                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                                } else if isToday {
                                    Circle()
                                        .stroke(Color.black, lineWidth: 1.5)
                                        .background(Circle().fill(Color.cartoonYellow.opacity(0.4)))
                                        .frame(width: 34, height: 34)
                                }

                                Text("\(dayNumber)")
                                    .font(.system(size: 14, weight: isSelected ? .heavy : .bold, design: .rounded))
                                    .foregroundColor(isSelected ? .white : .black)
                            }
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    } else {
                        // Ruang Kosong Sebelum Tanggal 1
                        Color.clear
                            .frame(width: 36, height: 36)
                    }
                }
            }

            Divider()
                .padding(.vertical, HIGSpacing.xxs)

            // 4. Baris Pengaturan Waktu (Time Picker Bergaya Kartun)
            HStack {
                Text("Time")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Spacer()

                DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .tint(Color.cartoonCoral)
                    .fontDesign(.rounded)
                    .environment(\.font, .system(size: 13, weight: .heavy, design: .rounded))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.94, green: 0.94, blue: 0.96))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1.5)
                    )
                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
            }
        }
        .padding(HIGSpacing.md)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
        .onAppear {
            currentMonth = selectedDate
        }
    }

    // MARK: - Helper Logika Tanggal
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func changeMonth(by amount: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            if let newMonth = calendar.date(byAdding: .month, value: amount, to: currentMonth) {
                currentMonth = newMonth
            }
        }
    }

    private func isDaySelected(_ dayNumber: Int) -> Bool {
        let targetComponents = calendar.dateComponents([.year, .month], from: currentMonth)
        let selectedComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        return targetComponents.year == selectedComponents.year &&
               targetComponents.month == selectedComponents.month &&
               selectedComponents.day == dayNumber
    }

    private func isDayToday(_ dayNumber: Int) -> Bool {
        let targetComponents = calendar.dateComponents([.year, .month], from: currentMonth)
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        return targetComponents.year == todayComponents.year &&
               targetComponents.month == todayComponents.month &&
               todayComponents.day == dayNumber
    }

    private func selectDay(_ dayNumber: Int) {
        var components = calendar.dateComponents([.year, .month], from: currentMonth)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedDate)
        components.day = dayNumber
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            if let newDate = calendar.date(from: components) {
                selectedDate = newDate
            }
        }
    }
}

#Preview {
    CartoonCalendarView(selectedDate: .constant(Date()))
        .padding()
}
