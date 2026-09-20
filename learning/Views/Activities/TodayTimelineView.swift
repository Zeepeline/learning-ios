//
//  TodayTimelineView.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import SwiftUI
import SwiftData
import WidgetKit

struct TodayTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.timestamp, order: .forward) private var allItems: [Item]

    @State private var selectedDate: Date = Date()
    @State private var baseWeekDate: Date = Date()
    @State private var isMonthViewExpanded: Bool = false
    @State private var newSubtaskTitle: String = ""
    @State private var isShowingAddActivity: Bool = false
    @State private var isShowingRebalancerSheet: Bool = false
    @FocusState private var isQuickAddFocused: Bool

    // Callback untuk delete, toggle, & edit dari ContentView
    var onDeleteItem: (Item) -> Void
    var onToggleItem: (Item) -> Void
    var onEditItem: (Item) -> Void

    private let calendar = Calendar.current

    // Mendapatkan 7 hari dalam minggu dari baseWeekDate
    private var weekDays: [Date] {
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: baseWeekDate)?.start else {
            return [baseWeekDate]
        }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    // Cek apakah item aktif pada tanggal tertentu (mendukung tugas berulang / scheduler)
    @inline(__always)
    private func isItemActive(_ item: Item, on date: Date) -> Bool {
        if !item.isRecurring {
            return calendar.isDate(item.timestamp, inSameDayAs: date)
        }

        // Jangan tampilkan sebelum tanggal pertama kali dibuat
        let targetStart = calendar.startOfDay(for: date)
        let itemStart = calendar.startOfDay(for: item.timestamp)
        guard targetStart >= itemStart else {
            return false
        }

        let targetWeekday = calendar.component(.weekday, from: date)
        switch item.recurrence {
        case .daily:
            return true
        case .weekdays:
            return (2...6).contains(targetWeekday)
        case .weekends:
            return targetWeekday == 1 || targetWeekday == 7
        case .weekly:
            let itemWeekday = calendar.component(.weekday, from: item.timestamp)
            return targetWeekday == itemWeekday
        case .none:
            return calendar.isDate(item.timestamp, inSameDayAs: date)
        }
    }

    // Filter item yang sesuai dengan tanggal terpilih (100% Data Nyata dari SwiftData)
    private var filteredItems: [Item] {
        allItems.filter { isItemActive($0, on: selectedDate) }
    }

    // Statistik tugas pada tanggal terpilih
    private var completedTasksCount: Int {
        filteredItems.filter { $0.isCompleted }.count
    }

    private var totalTasksCount: Int {
        filteredItems.count
    }

    private var progressRatio: Double {
        guard totalTasksCount > 0 else { return 0 }
        return Double(completedTasksCount) / Double(totalTasksCount)
    }

    // ⚡ Optimized Fast Task Count per Date (Single-pass lookup)
    private func getTaskCount(for date: Date) -> (total: Int, completed: Int) {
        var total = 0
        var completed = 0
        for item in allItems {
            if isItemActive(item, on: date) {
                total += 1
                if item.isCompleted {
                    completed += 1
                }
            }
        }
        return (total: total, completed: completed)
    }

    // Cek apakah tanggal terpilih adalah hari ini
    private var isSelectedDateToday: Bool {
        calendar.isDateInToday(selectedDate)
    }

    dynamic var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: HIGSpacing.md) {
                    
                    // 1. 📅 Bar Navigasi Kalender (Bulan/Tahun, Hari Ini, < >, Mode Toggle)
                    calendarControlHeader
                        .padding(.horizontal, HIGSpacing.md)
                        .padding(.top, HIGSpacing.xs)

                    // 2. 🗓️ Tampilan Kalender (Mingguan Strip atau Bulanan Penuh)
                    if isMonthViewExpanded {
                        CartoonCalendarView(
                            selectedDate: $selectedDate,
                            showTimePicker: false,
                            taskCountForDate: { date in
                                getTaskCount(for: date)
                            }
                        )
                        .padding(.horizontal, HIGSpacing.md)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.96)),
                            removal: .opacity.combined(with: .scale(scale: 0.96))
                        ))
                    } else {
                        CartoonWeeklyStrip(
                            selectedDate: $selectedDate,
                            weekDays: weekDays,
                            taskCountForDate: { date in
                                getTaskCount(for: date)
                            }
                        )
                        .padding(.horizontal, HIGSpacing.md)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.96)),
                            removal: .opacity.combined(with: .scale(scale: 0.96))
                        ))
                    }

                    // 3. 🤖 Banner AI Rebalancer (Jika sedang di tab Hari Ini & ada tugas terlewat/bentrok)
                    if isSelectedDateToday {
                        CartoonAIRebalanceBanner(items: allItems) {
                            isShowingRebalancerSheet = true
                        }
                        .padding(.horizontal, HIGSpacing.md)
                    }

                    // 4. 🎯 Kartu Ringkasan Progress Harian
                    dailyProgressCard
                        .padding(.horizontal, HIGSpacing.md)

                    // 5. 🗂️ Garis Timeline Vertikal & Kartu Aktivitas (Menggunakan LazyVStack untuk 120fps)
                    VStack(spacing: HIGSpacing.md) {
                        if filteredItems.isEmpty {
                            emptyTimelineState
                        } else {
                            // ⚡ LazyVStack: Instansiasi on-demand kartu tugas untuk performa scroll mulus
                            LazyVStack(spacing: HIGSpacing.sm) {
                                ForEach(filteredItems) { item in
                                    HStack(alignment: .top, spacing: HIGSpacing.sm) {
                                        // Kolom Waktu di Kiri (Format: 09:00 AM)
                                        Text(CalendarDateCache.shared.formatTime(item.timestamp))
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(.secondary)
                                            .frame(width: 58, alignment: .leading)
                                            .padding(.top, HIGSpacing.xs)

                                        // Reusable Timeline Card Component dengan Dukungan Edit saat Diketuk
                                        CartoonTimelineCard(
                                            title: item.title,
                                            timeText: item.timestamp.formatted(date: .omitted, time: .shortened),
                                            category: item.category,
                                            notes: item.notes,
                                            isCompleted: item.isCompleted,
                                            isRecurring: item.isRecurring,
                                            recurrenceTitle: item.recurrence.shortTitle,
                                            onToggle: { onToggleItem(item) },
                                            onDelete: { onDeleteItem(item) },
                                            onTap: { onEditItem(item) }
                                        )
                                    }
                                }
                            }

                            // ➕ Reusable Baris Input Cepat "Add new subtask"
                            CartoonQuickAddBar(timeLabel: "Quick", text: $newSubtaskTitle) {
                                createQuickSubtask()
                            }
                            .focused($isQuickAddFocused)
                            .id("quickAddBar")
                        }
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    .padding(.top, HIGSpacing.xs)
                    .padding(.bottom, 100) // Ruang safe area bottom bar
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .onTapGesture {
                isQuickAddFocused = false
            }
            .sheet(isPresented: $isShowingAddActivity) {
                AddActivity()
            }
            .sheet(isPresented: $isShowingRebalancerSheet) {
                AISmartRebalancerSheetView(items: allItems)
            }
        }
    }

    // MARK: - 🎛️ Header Kontrol Kalender
    private var calendarControlHeader: some View {
        HStack {
            // Label Bulan & Tahun
            VStack(alignment: .leading, spacing: 2) {
                Text(monthYearText(from: selectedDate))
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Text(isSelectedDateToday ? "Hari Ini" : selectedDate.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "id_ID"))))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(isSelectedDateToday ? Color.cartoonCoral : .secondary)
            }

            Spacer()

            // Tombol "Hari Ini" Cepat
            if !isSelectedDateToday {
                Button {
                    HapticManager.shared.impact(style: .light)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedDate = Date()
                        baseWeekDate = Date()
                    }
                } label: {
                    Text("Hari Ini")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.cartoonYellow)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.5))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }

            // Tombol Navigasi Minggu Sebelumnya & Berikutnya
            HStack(spacing: 4) {
                CartoonIconButton(icon: "chevron.left", size: 32) {
                    shiftWeek(by: -7)
                }
                CartoonIconButton(icon: "chevron.right", size: 32) {
                    shiftWeek(by: 7)
                }
            }

            // Tombol Toggle Mode Tampilan (Mingguan / Bulanan)
            Button {
                HapticManager.shared.selection()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isMonthViewExpanded.toggle()
                }
            } label: {
                Image(systemName: isMonthViewExpanded ? "calendar.badge.minus" : "calendar.badge.plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 34, height: 34)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.5))
                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
        }
    }

    // MARK: - 🎯 Kartu Ringkasan Progress Harian
    private var dailyProgressCard: some View {
        HStack(spacing: 12) {
            // Icon Checklist Kartun
            ZStack {
                Circle()
                    .fill(progressRatio == 1.0 && totalTasksCount > 0 ? Color.cartoonMint : Color.cartoonYellow)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1.8))
                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)

                Image(systemName: progressRatio == 1.0 && totalTasksCount > 0 ? "checkmark.seal.fill" : "flag.checkered")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
            }

            // Teks Keterangan & Progress Bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(progressStatusTitle)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)

                    Spacer()

                    Text("\(completedTasksCount)/\(totalTasksCount) Selesai")
                        .font(.system(size: 11.5, weight: .black, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                // Custom Cartoon Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(red: 0.92, green: 0.92, blue: 0.92))
                            .frame(height: 10)
                            .overlay(Capsule().stroke(Color.black, lineWidth: 1.2))

                        Capsule()
                            .fill(Color.cartoonMint)
                            .frame(width: max(0, geo.size.width * CGFloat(progressRatio)), height: 10)
                            .overlay(Capsule().stroke(Color.black, lineWidth: progressRatio > 0 ? 1.2 : 0))
                    }
                }
                .frame(height: 10)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }

    private var progressStatusTitle: String {
        if totalTasksCount == 0 {
            return "Hari Bebas Tugas 🎉"
        } else if completedTasksCount == totalTasksCount {
            return "Semua Tugas Tuntas! 🏆"
        } else if completedTasksCount > 0 {
            return "Sedang Berprogres 💪"
        } else {
            return "Target Hari Ini 🎯"
        }
    }

    // MARK: - 📭 Empty Timeline State
    private var emptyTimelineState: some View {
        VStack(spacing: HIGSpacing.sm) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.top, HIGSpacing.lg)

            Text("Tidak Ada Aktivitas")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.black)

            Text("Belum ada jadwal tugas yang direncanakan untuk tanggal ini.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, HIGSpacing.xl)

            Button {
                HapticManager.shared.impact(style: .medium)
                isShowingAddActivity = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Buat Aktivitas Baru")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.cartoonYellow)
                .cornerRadius(CartoonMetrics.cardCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                        .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                )
                .shadow(color: .black, radius: 0, x: 2, y: 2)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            .padding(.top, HIGSpacing.xs)
            .padding(.bottom, HIGSpacing.lg)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }

    // MARK: - Helper Methods
    private func shiftWeek(by days: Int) {
        HapticManager.shared.impact(style: .light)
        if let newBase = calendar.date(byAdding: .day, value: days, to: baseWeekDate) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                baseWeekDate = newBase
                selectedDate = newBase
            }
        }
    }

    private func monthYearText(from date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "id_ID")))
    }

    private func createQuickSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let newItem = Item(
            title: trimmed,
            notes: "Ditambahkan dari Timeline Harian",
            timestamp: selectedDate,
            isCompleted: false,
            completedAt: nil,
            priority: "Normal",
            category: "Umum"
        )

        modelContext.insert(newItem)

        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
            newSubtaskTitle = ""
            isQuickAddFocused = false
            HapticManager.shared.success()
            SoundManager.shared.playSuccessChime()
        } catch {
            print("Gagal menyimpan subtask cepat: \(error.localizedDescription)")
        }
    }
}
