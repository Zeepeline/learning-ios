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

    // Filter item yang sesuai dengan tanggal terpilih (100% Data Nyata dari SwiftData)
    private var filteredItems: [Item] {
        allItems.filter { calendar.isDate($0.timestamp, inSameDayAs: selectedDate) }
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

    // Helper untuk task count di setiap tanggal kalender
    private func getTaskCount(for date: Date) -> (total: Int, completed: Int) {
        let itemsOnDate = allItems.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
        let completed = itemsOnDate.filter { $0.isCompleted }.count
        return (total: itemsOnDate.count, completed: completed)
    }

    // Cek apakah tanggal terpilih adalah hari ini
    private var isSelectedDateToday: Bool {
        calendar.isDateInToday(selectedDate)
    }

    var body: some View {
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
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 25)
                                .onEnded { value in
                                    // Pastikan pergerakan dominan horizontal agar scroll vertikal halaman tidak terganggu
                                    guard abs(value.translation.width) > abs(value.translation.height) * 1.3 else { return }
                                    if value.translation.width < -40 {
                                        // Swipe Kiri -> Minggu Depan
                                        changeWeek(by: 1)
                                    } else if value.translation.width > 40 {
                                        // Swipe Kanan -> Minggu Sebelumnya
                                        changeWeek(by: -1)
                                    }
                                }
                        )
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                    }

                    // 3. 🏷️ Header Tanggal Terpilih & Ringkasan Progress Tugas Harian
                    selectedDateSummarySection
                        .padding(.horizontal, HIGSpacing.md)

                    // 3b. 🏃 Kartu Ringkasan Kebugaran Apple Health & Zepp (Khusus Hari Ini)
                    if isSelectedDateToday {
                        CartoonHealthCard()
                            .padding(.horizontal, HIGSpacing.md)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.98)),
                                removal: .opacity
                            ))
                    }

                    // 4. 🗂️ Garis Timeline Vertikal & Kartu Aktivitas (Real Data dari SwiftData)
                    VStack(spacing: HIGSpacing.lg) {
                        if filteredItems.isEmpty {
                            emptyTimelineState
                        } else {
                            // Daftar Tugas Nyata Menggunakan Reusable CartoonTimelineCard
                            ForEach(filteredItems) { item in
                                HStack(alignment: .top, spacing: HIGSpacing.sm) {
                                    // Kolom Waktu di Kiri (Format: 09:00 AM)
                                    Text(item.timestamp.formatted(.dateTime.hour().minute()))
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
                                        onToggle: { onToggleItem(item) },
                                        onDelete: { onDeleteItem(item) },
                                        onTap: { onEditItem(item) }
                                    )
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
            .onChange(of: isQuickAddFocused) { _, focused in
                if focused {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        proxy.scrollTo("quickAddBar", anchor: UnitPoint(x: 0.5, y: 0.25))
                    }
                }
            }
            .onChange(of: selectedDate) { _, newDate in
                // Sinkronkan baseWeekDate saat memilih tanggal agar strip minggu selalu relevan
                if !calendar.isDate(newDate, equalTo: baseWeekDate, toGranularity: .weekOfYear) {
                    baseWeekDate = newDate
                }
            }
        }
        .sheet(isPresented: $isShowingAddActivity) {
            AddActivity()
                .presentationDetents([.fraction(0.92), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
        }
    }

    // MARK: - 📅 Header Kontrol Kalender
    private var calendarControlHeader: some View {
        HStack(spacing: HIGSpacing.xs) {
            // Teks Bulan & Tahun dari baseWeekDate / selectedDate
            HStack(spacing: 6) {
                Text(monthYearText(from: isMonthViewExpanded ? selectedDate : baseWeekDate))
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
            }

            Spacer()

            // Tombol Pintas "Hari Ini" jika bukan di hari ini
            if !isSelectedDateToday {
                Button {
                    HapticManager.shared.impact(style: .light)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        let today = Date()
                        selectedDate = today
                        baseWeekDate = today
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("Hari Ini")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, HIGSpacing.xs)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.cartoonYellow)
                            .shadow(color: .black.opacity(0.15), radius: 0, x: 1, y: 1)
                    )
                    .overlay(Capsule().stroke(Color.black, lineWidth: 1.2))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }

            // Tombol Navigasi < (Minggu/Bulan Sebelumnya)
            Button {
                HapticManager.shared.impact(style: .light)
                if isMonthViewExpanded {
                    changeMonth(by: -1)
                } else {
                    changeWeek(by: -1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.black)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 0, x: 1, y: 1)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

            // Tombol Navigasi > (Minggu/Bulan Selanjutnya)
            Button {
                HapticManager.shared.impact(style: .light)
                if isMonthViewExpanded {
                    changeMonth(by: 1)
                } else {
                    changeWeek(by: 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.black)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 0, x: 1, y: 1)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

            // Tombol Toggle Kalender Bulanan Penuh / Mingguan
            Button {
                HapticManager.shared.selection()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isMonthViewExpanded.toggle()
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isMonthViewExpanded ? Color.cartoonCoral : Color.white)
                        .frame(width: 32, height: 32)
                        .shadow(color: .black.opacity(0.1), radius: 0, x: 1, y: 1)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))

                    Image(systemName: isMonthViewExpanded ? "rectangle.split.1x2.fill" : "calendar")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isMonthViewExpanded ? .white : .black)
                }
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
        }
    }

    // MARK: - 🏷️ Section Header Tanggal Terpilih & Progress Card
    private var selectedDateSummarySection: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.xs) {
            HStack(alignment: .center) {
                // Judul Hari & Tanggal Lengkap
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedDate.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                    
                    if isSelectedDateToday {
                        Text("Jadwal Hari Ini")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Color.cartoonCoral)
                    }
                }

                Spacer()

                // Badge Ringkasan Tugas
                if totalTasksCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: completedTasksCount == totalTasksCount ? "checkmark.seal.fill" : "list.clipboard.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("\(completedTasksCount)/\(totalTasksCount) Selesai")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, HIGSpacing.xs)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(completedTasksCount == totalTasksCount ? Color.cartoonMint : Color.cartoonBlue)
                            .shadow(color: .black.opacity(0.12), radius: 0, x: 1, y: 1)
                    )
                    .overlay(Capsule().stroke(Color.black, lineWidth: 1.2))
                }
            }

            // Progress Bar Bergaya Kartun jika ada tugas
            if totalTasksCount > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.92, green: 0.92, blue: 0.94))
                            .frame(height: 8)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))

                        RoundedRectangle(cornerRadius: 6)
                            .fill(completedTasksCount == totalTasksCount ? Color.cartoonMint : Color.cartoonCoral)
                            .frame(width: max(0, geo.size.width * CGFloat(progressRatio)), height: 8)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: progressRatio > 0 ? 1.0 : 0))
                    }
                }
                .frame(height: 8)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: progressRatio)
            }
        }
        .padding(HIGSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CartoonMetrics.cornerRadius)
                .fill(Color.white)
                .shadow(color: .black, radius: 0, x: 2, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
    }

    // MARK: - 📬 Tampilan Kosong untuk Tanggal Terpilih
    private var emptyTimelineState: some View {
        VStack(spacing: HIGSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.cartoonYellow)
                    .frame(width: 64, height: 64)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
            }
            .padding(.top, HIGSpacing.md)

            VStack(spacing: HIGSpacing.xxs) {
                Text("Tidak Ada Jadwal")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Text("Belum ada tugas terjadwal pada tanggal ini.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Tombol Tambah Tugas untuk Tanggal Ini
            Button {
                isShowingAddActivity = true
            } label: {
                HStack(spacing: HIGSpacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Buat Jadwal Baru")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black)
                .padding(.horizontal, HIGSpacing.lg)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cartoonMint)
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                )
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.8))
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            .padding(.top, HIGSpacing.xxs)

            // ➕ Reusable Input Tambah Cepat
            CartoonQuickAddBar(timeLabel: "Add", text: $newSubtaskTitle) {
                createQuickSubtask()
            }
            .padding(.top, HIGSpacing.sm)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HIGSpacing.md)
    }

    // MARK: - Helper Logika Navigasi & Aksi
    private func monthYearText(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func changeWeek(by amount: Int) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            if let newBase = calendar.date(byAdding: .weekOfYear, value: amount, to: baseWeekDate) {
                baseWeekDate = newBase
                if let newSelected = calendar.date(byAdding: .weekOfYear, value: amount, to: selectedDate) {
                    selectedDate = newSelected
                }
            }
        }
    }

    private func changeMonth(by amount: Int) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            if let newDate = calendar.date(byAdding: .month, value: amount, to: selectedDate) {
                selectedDate = newDate
                baseWeekDate = newDate
            }
        }
    }

    private func createQuickSubtask() {
        guard !newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            let newItem = Item(
                title: newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                timestamp: selectedDate,
                isCompleted: false,
                priority: "Normal",
                category: "Subtask"
            )
            modelContext.insert(newItem)
            try? modelContext.save()
            newSubtaskTitle = ""
            WidgetCenter.shared.reloadAllTimelines()
            HapticManager.shared.impact(style: .medium)
        }
    }
}

#Preview {
    TodayTimelineView(
        onDeleteItem: { _ in },
        onToggleItem: { _ in },
        onEditItem: { _ in }
    )
    .modelContainer(for: Item.self, inMemory: true)
}
