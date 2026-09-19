//
//  CompletedTasksHistoryView.swift
//  learning
//
//  Created by macbook on 9/19/26.
//

import SwiftUI
import SwiftData
import WidgetKit

struct CompletedTasksHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Item> { $0.isCompleted }, sort: \Item.timestamp, order: .reverse)
    private var completedItems: [Item]

    @State private var searchText: String = ""
    @State private var isShowingClearAllDialog: Bool = false
    @State private var itemToRestore: Item? = nil
    @State private var itemToDelete: Item? = nil

    private var filteredItems: [Item] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return completedItems
        }
        return completedItems.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.notes.localizedCaseInsensitiveContains(query) ||
            $0.category.localizedCaseInsensitiveContains(query)
        }
    }

    // Kelompokkan item berdasarkan tanggal penyelesaian
    private var groupedItems: [(title: String, items: [Item])] {
        let calendar = Calendar.current
        var today: [Item] = []
        var yesterday: [Item] = []
        var thisWeek: [Item] = []
        var thisMonth: [Item] = []
        var older: [Item] = []

        for item in filteredItems {
            let date = item.completedAt ?? item.timestamp
            if calendar.isDateInToday(date) {
                today.append(item)
            } else if calendar.isDateInYesterday(date) {
                yesterday.append(item)
            } else if let diff = calendar.dateComponents([.day], from: date, to: Date()).day, diff <= 7 {
                thisWeek.append(item)
            } else if calendar.isDate(date, equalTo: Date(), toGranularity: .month) {
                thisMonth.append(item)
            } else {
                older.append(item)
            }
        }

        var groups: [(title: String, items: [Item])] = []
        if !today.isEmpty { groups.append(("Hari Ini", today)) }
        if !yesterday.isEmpty { groups.append(("Kemarin", yesterday)) }
        if !thisWeek.isEmpty { groups.append(("7 Hari Terakhir", thisWeek)) }
        if !thisMonth.isEmpty { groups.append(("Bulan Ini", thisMonth)) }
        if !older.isEmpty { groups.append(("Lebih Lama", older)) }

        return groups
    }

    dynamic var body: some View {
        ZStack {
            Color.cartoonBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. Header Navigation Bar
                headerView

                ScrollView(showsIndicators: false) {
                    VStack(spacing: HIGSpacing.md) {
                        // 2. Banner Ringkasan Total Riwayat Selesai
                        summaryBanner
                            .padding(.horizontal, HIGSpacing.md)
                            .padding(.top, HIGSpacing.xs)

                        // 3. Search Bar
                        if !completedItems.isEmpty {
                            CartoonSearchBar(searchText: $searchText)
                                .padding(.horizontal, HIGSpacing.md)
                        }

                        // 4. Daftar Tugas Selesai Dikelompokkan
                        if completedItems.isEmpty {
                            emptyStateView
                        } else if filteredItems.isEmpty {
                            emptySearchStateView
                        } else {
                            historyListContent
                        }
                    }
                    .padding(.bottom, 40)
                }
            }

            // Dialog Konfirmasi Hapus Semua Riwayat
            if isShowingClearAllDialog {
                CartoonConfirmDialog(
                    title: "Hapus Semua Riwayat?",
                    message: "Semua tugas yang telah selesai akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.",
                    cancelTitle: "Batal",
                    confirmTitle: "Ya, Hapus Semua",
                    onCancel: {
                        HapticManager.shared.impact(style: .light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            isShowingClearAllDialog = false
                        }
                    },
                    onConfirm: {
                        clearAllHistory()
                    }
                )
            }
        }
    }

    // MARK: - 1. Header Bar
    private var headerView: some View {
        HStack {
            // Tombol Tutup / Kembali
            Button {
                HapticManager.shared.impact(style: .light)
                dismiss()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                    Text("Kembali")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.4))
                .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

            Spacer()

            Text("Riwayat Selesai")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.black)

            Spacer()

            // Tombol Bersihkan Semua Riwayat
            if !completedItems.isEmpty {
                Button {
                    HapticManager.shared.warning()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        isShowingClearAllDialog = true
                    }
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .background(Color.cartoonPink)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.4))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            } else {
                Color.clear.frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, HIGSpacing.md)
        .padding(.top, HIGSpacing.xs)
        .padding(.bottom, HIGSpacing.xs)
    }

    // MARK: - 2. Summary Banner
    private var summaryBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.cartoonMint)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.black)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("TOTAL TUGAS SELESAI")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(.secondary)

                Text("\(completedItems.count) Aktivitas Berhasil Dituntaskan")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
            }

            Spacer()
        }
        .padding(HIGSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .fill(Color.white)
                .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
    }

    // MARK: - 3. Grouped History List Content
    private var historyListContent: some View {
        VStack(spacing: HIGSpacing.md) {
            ForEach(groupedItems, id: \.title) { group in
                VStack(alignment: .leading, spacing: HIGSpacing.xs) {
                    HStack(spacing: 6) {
                        Text(group.title)
                            .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)

                        Text("\(group.items.count)")
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6.5)
                            .padding(.vertical, 2)
                            .background(Color.cartoonMint)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.black, lineWidth: 1.0))

                        Spacer()
                    }
                    .padding(.horizontal, HIGSpacing.md)

                    LazyVStack(spacing: 8) {
                        ForEach(group.items) { item in
                            CompletedActivityCardView(
                                item: item,
                                onToggle: {
                                    restoreItem(item)
                                },
                                onDelete: {
                                    deleteSingleItem(item)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, HIGSpacing.md)
                }
            }
        }
    }

    // MARK: - 4. Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.cartoonYellow)
                    .frame(width: 64, height: 64)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1.8))
                    .shadow(color: .black, radius: 0, x: 2, y: 2)

                Image(systemName: "sparkles")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.black)
            }
            .padding(.top, 40)

            Text("Belum Ada Riwayat Selesai")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.black)

            Text("Selesaikan tugas hari ini dan tugasmu akan otomatis tercatat di sini!")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 20)
    }

    private var emptySearchStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.top, 30)

            Text("Tidak Ada Hasil Ditemukan")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(.black)

            Text("Coba cari dengan kata kunci judul atau kategori lain.")
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Helper Actions
    private func restoreItem(_ item: Item) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            item.isCompleted = false
            item.completedAt = nil
            try? modelContext.save()
            HapticManager.shared.impact(style: .medium)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func deleteSingleItem(_ item: Item) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            modelContext.delete(item)
            try? modelContext.save()
            HapticManager.shared.impact(style: .light)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func clearAllHistory() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            for item in completedItems {
                modelContext.delete(item)
            }
            try? modelContext.save()
            isShowingClearAllDialog = false
            HapticManager.shared.success()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
