//
//  TodayTimelineView.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import SwiftUI
import SwiftData

struct TodayTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.timestamp, order: .forward) private var allItems: [Item]

    @State private var selectedDate: Date = Date()
    @State private var newSubtaskTitle: String = ""
    @State private var isShowingAddActivity: Bool = false
    @FocusState private var isQuickAddFocused: Bool
    
    // Callback untuk delete, toggle, & edit dari ContentView
    var onDeleteItem: (Item) -> Void
    var onToggleItem: (Item) -> Void
    var onEditItem: (Item) -> Void

    private let calendar = Calendar.current

    // Mendapatkan 7 hari dalam minggu dari selectedDate
    private var weekDays: [Date] {
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start else {
            return [selectedDate]
        }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    // Filter item yang sesuai dengan tanggal terpilih (100% Data Nyata dari SwiftData)
    private var filteredItems: [Item] {
        allItems.filter { calendar.isDate($0.timestamp, inSameDayAs: selectedDate) }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: HIGSpacing.lg) {
                    
                    // 1. Header Tanggal Dinamis (Contoh: "Monday, 31 August 2026")
                    VStack(alignment: .leading, spacing: HIGSpacing.xxs) {
                        Text(selectedDate.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    .padding(.top, HIGSpacing.xs)

                    // 2. 📅 Reusable Strip Seleksi Hari Mingguan
                    CartoonWeeklyStrip(selectedDate: $selectedDate, weekDays: weekDays)
                        .padding(.horizontal, HIGSpacing.md)

                    // 3. Garis Timeline Vertikal & Kartu Aktivitas (Real Data dari SwiftData)
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

                                    // 🗂️ Reusable Timeline Card Component dengan Dukungan Edit saat Diketuk
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
        }
        
        .sheet(isPresented: $isShowingAddActivity) {
            AddActivity()
                .presentationDetents([.fraction(0.92), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
        }
    }

    // MARK: - Tampilan Kosong untuk Tanggal Terpilih
    private var emptyTimelineState: some View {
        VStack(spacing: HIGSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.cartoonYellow)
                    .frame(width: 64, height: 64)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    .shadow(color: .black, radius: 0, x: 2, y: 2)

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
                .background(Color.cartoonMint)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.8))
                .shadow(color: .black, radius: 0, x: 2, y: 2)
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
            newSubtaskTitle = ""
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
