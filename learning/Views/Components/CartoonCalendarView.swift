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
    let date: Date?
}

// MARK: - 📅 Custom Cartoon Neo-Brutalist Calendar & Time Picker (Reusable)
struct CartoonCalendarView: View {
    @Binding var selectedDate: Date
    var showTimePicker: Bool = true
    var taskCountForDate: ((Date) -> (total: Int, completed: Int))? = nil
    
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
            cells.append(CartoonDayCell(id: "leading-\(i)", dayNumber: nil, date: nil))
        }

        for day in range {
            var dayComponents = components
            dayComponents.day = day
            let date = calendar.date(from: dayComponents)
            cells.append(CartoonDayCell(id: "day-\(day)", dayNumber: day, date: date))
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
                    HapticManager.shared.impact(style: .light)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDate = Date()
                        currentMonth = Date()
                    }
                } label: {
                    Text("Hari Ini")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, HIGSpacing.xs)
                        .padding(.vertical, 4)
                        .background(Color.cartoonYellow)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.black, lineWidth: 1.2))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                // Tombol Bulan Sebelumnya <
                Button {
                    HapticManager.shared.impact(style: .light)
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

                // Tombol Bulan Selanjutnya >
                Button {
                    HapticManager.shared.impact(style: .light)
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

            // 2. Baris Nama-Nama Hari (SUN, MON, TUE...)
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
                    if let dayNumber = cell.dayNumber, let cellDate = cell.date {
                        let isSelected = isDaySelected(dayNumber)
                        let isToday = isDayToday(dayNumber)
                        let taskStats = taskCountForDate?(cellDate) ?? (total: 0, completed: 0)

                        Button {
                            HapticManager.shared.selection()
                            selectDay(dayNumber)
                        } label: {
                            VStack(spacing: 2) {
                                Text("\(dayNumber)")
                                    .font(.system(size: 13, weight: isSelected ? .heavy : .bold, design: .rounded))
                                    .foregroundColor(isSelected ? .white : .black)

                                // Task Dot Indicator
                                if taskStats.total > 0 {
                                    Circle()
                                        .fill(
                                            isSelected
                                                ? Color.white
                                                : (taskStats.completed == taskStats.total ? Color.cartoonMint : Color.cartoonCoral)
                                        )
                                        .frame(width: 4.5, height: 4.5)
                                } else {
                                    Circle()
                                        .fill(Color.clear)
                                        .frame(width: 4.5, height: 4.5)
                                }
                            }
                            .frame(width: 36, height: 36)
                            .background(
                                isSelected
                                    ? Color.cartoonCoral
                                    : (isToday ? Color.cartoonYellow.opacity(0.4) : Color.clear)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        Color.black,
                                        lineWidth: isSelected ? 1.8 : (isToday ? 1.4 : 0)
                                    )
                            )
                            .shadow(
                                color: isSelected ? .black : .clear,
                                radius: 0,
                                x: 1.5,
                                y: 1.5
                            )
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    } else {
                        // Ruang Kosong Sebelum Tanggal 1
                        Color.clear
                            .frame(width: 36, height: 36)
                    }
                }
            }

            // 4. Baris Pengaturan Waktu (Jika Diaktifkan)
            if showTimePicker {
                Divider()
                    .padding(.vertical, HIGSpacing.xxs)

                HStack {
                    Text("Waktu")
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
        .onChange(of: selectedDate) { _, newDate in
            let currentComponents = calendar.dateComponents([.year, .month], from: currentMonth)
            let newComponents = calendar.dateComponents([.year, .month], from: newDate)
            if currentComponents.year != newComponents.year || currentComponents.month != newComponents.month {
                currentMonth = newDate
            }
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
               targetComponents.day == dayNumber
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
