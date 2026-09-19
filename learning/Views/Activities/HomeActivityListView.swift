//
//  HomeActivityListView.swift
//  learning
//
//  Created by macbook on 9/1/26.
//

import SwiftUI
import SwiftData

struct HomeActivityListView: View {
    @Environment(\.modelContext) private var modelContext
    let items: [Item]
    var onEditItem: (Item) -> Void
    var onToggleItem: (Item) -> Void
    var onDeleteItem: (Item) -> Void

    // Filter & Search State
    @State private var rawSearchText: String = ""
    @State private var debouncedSearchText: String = ""
    @State private var selectedStatusFilter: String = "all"
    @State private var selectedCategoryFilter: String = "all"
    @State private var isFilterPanelExpanded: Bool = false

    // Dialog & Sheet State
    @State private var isShowingHistorySheet: Bool = false
    @State private var isShowingClearCompletedDialog: Bool = false

    // Filter chips definitions
    private let statusFilters: [(id: String, label: String, icon: String, color: Color)] = [
        ("all", "Semua", "list.bullet", .cartoonYellow),
        ("pending", "Belum Selesai", "hourglass", .cartoonCoral),
        ("high", "Prioritas Tinggi", "flame.fill", .cartoonCoral),
        ("recurring", "Rutin", "repeat", .cartoonLavender),
        ("completed", "Selesai", "checkmark.circle.fill", .cartoonMint)
    ]

    private var hasActiveFilter: Bool {
        selectedStatusFilter != "all" || selectedCategoryFilter != "all"
    }

    private var activeFilterLabel: String {
        var labels: [String] = []
        if let status = statusFilters.first(where: { $0.id == selectedStatusFilter }), selectedStatusFilter != "all" {
            labels.append(status.label)
        }
        if selectedCategoryFilter != "all" {
            labels.append(selectedCategoryFilter)
        }
        return labels.joined(separator: " • ")
    }

    private var availableCategories: [String] {
        var categoriesSet = Set<String>()
        for item in items where !item.category.isEmpty {
            categoriesSet.insert(item.category)
        }
        return ["all"] + Array(categoriesSet).sorted()
    }

    private func isCompletedToday(_ item: Item) -> Bool {
        let date = item.completedAt ?? item.timestamp
        return Calendar.current.isDateInToday(date)
    }

    private var todayCompletedCount: Int {
        items.filter { $0.isCompleted && isCompletedToday($0) }.count
    }

    private var totalCompletedAllTimeCount: Int {
        items.filter { $0.isCompleted }.count
    }

    private var pendingCount: Int { items.filter { !$0.isCompleted }.count }

    private var filteredItems: [Item] {
        let query = debouncedSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return items.filter { item in
            let matchesSearch = query.isEmpty ||
                item.title.localizedCaseInsensitiveContains(query) ||
                item.notes.localizedCaseInsensitiveContains(query) ||
                item.category.localizedCaseInsensitiveContains(query)

            let matchesFilter: Bool
            switch selectedStatusFilter {
            case "recurring":
                matchesFilter = item.isRecurring && !item.isCompleted
            case "pending":
                matchesFilter = !item.isCompleted
            case "completed":
                matchesFilter = item.isCompleted
            case "high":
                matchesFilter = item.priority == "Tinggi" && !item.isCompleted
            default: // "all" -> Hanya menampilkan tugas yang belum selesai di Home
                matchesFilter = !item.isCompleted
            }

            let matchesCategory: Bool = (selectedCategoryFilter == "all") || (item.category.lowercased() == selectedCategoryFilter.lowercased())

            return matchesSearch && matchesFilter && matchesCategory
        }
    }

    dynamic var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: HIGSpacing.sm) {
                    // 1. ✨ Kartu Kata Motivasi Harian (Posisi Teratas Sesuai Preferensi)
                    CartoonMotivationalQuoteCard()
                        .padding(.horizontal, HIGSpacing.md)
                        .padding(.top, HIGSpacing.xs)

                    // 2. 🌟 Progress Banner Sapaan Harian & Statistik
                    CartoonProgressBanner(
                        userName: displayGreetingName,
                        completedCount: todayCompletedCount,
                        totalCount: pendingCount + todayCompletedCount
                    )
                    .padding(.horizontal, HIGSpacing.md)

                    // 3. 📊 3 Kartu Mini Ringkasan Statistik
                    HStack(spacing: HIGSpacing.xs) {
                        CartoonStatCard(
                            title: "Perlu Dikerjakan",
                            count: pendingCount,
                            icon: "hourglass",
                            color: .cartoonCoral
                        )

                        CartoonStatCard(
                            title: "Selesai Hari Ini",
                            count: todayCompletedCount,
                            icon: "checkmark.seal.fill",
                            color: .cartoonMint
                        )

                        // Kartu Riwayat Semua Tugas Selesai (Buka Fullscreen Cover)
                        Button {
                            HapticManager.shared.impact(style: .light)
                            isShowingHistorySheet = true
                        } label: {
                            CartoonStatCard(
                                title: "Riwayat Selesai",
                                count: totalCompletedAllTimeCount,
                                icon: "clock.arrow.circlepath",
                                color: .cartoonLavender
                            )
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    }
                    .padding(.horizontal, HIGSpacing.md)

                    // 4. 🔍 Search & Filter Header
                    searchAndFilterHeader
                        .padding(.horizontal, HIGSpacing.md)
                        .padding(.top, 4)

                    // Filter Drawer (Collapsible)
                    if isFilterPanelExpanded {
                        filterDrawerSection
                            .padding(.horizontal, HIGSpacing.md)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // 5. 📋 Daftar Aktivitas
                    activityListSection
                        .padding(.horizontal, HIGSpacing.md)

                    // Spacer agar tidak tertutup Bottom Bar & FAB
                    Spacer()
                        .frame(height: 120)
                }
                .padding(.top, 4)
            }
            .refreshable {
                HapticManager.shared.impact(style: .medium)
            }

            // Dialog Konfirmasi Hapus / Bersihkan Semua Tugas Selesai
            if isShowingClearCompletedDialog {
                CartoonConfirmDialog(
                    title: "Bersihkan Selesai?",
                    message: "Apakah kamu yakin ingin menghapus tugas yang selesai hari ini?",
                    cancelTitle: "Batal",
                    confirmTitle: "Ya, Bersihkan",
                    onCancel: {
                        HapticManager.shared.impact(style: .light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            isShowingClearCompletedDialog = false
                        }
                    },
                    onConfirm: {
                        clearAllCompletedTasks()
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $isShowingHistorySheet) {
            CompletedTasksHistoryView()
        }
    }

    // MARK: - 🔍 Search & Filter Header Terpadu
    private var searchAndFilterHeader: some View {
        HStack(spacing: HIGSpacing.xs) {
            CartoonSearchBar(searchText: $rawSearchText)
                .onChange(of: rawSearchText) { _, newValue in
                    Task {
                        try? await Task.sleep(nanoseconds: 180_000_000) // 180ms debounce
                        guard !Task.isCancelled else { return }
                        debouncedSearchText = newValue
                    }
                }

            // Tombol Filter Icon Neo-Brutalist
            Button {
                HapticManager.shared.impact(style: .light)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isFilterPanelExpanded.toggle()
                }
            } label: {
                ZStack(alignment: .topTrailing) {
                    HStack(spacing: 4) {
                        Image(systemName: isFilterPanelExpanded ? "line.3.horizontal.decrease.circle.fill" : "slider.horizontal.3")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(hasActiveFilter ? Color.cartoonYellow : (isFilterPanelExpanded ? Color.cartoonLavender : Color.white))
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 1.6)
                    )

                    // Dot penanda filter sedang aktif
                    if hasActiveFilter {
                        Circle()
                            .fill(Color.cartoonCoral)
                            .frame(width: 9, height: 9)
                            .overlay(Circle().stroke(Color.black, lineWidth: 1.2))
                            .offset(x: 2, y: -2)
                    }
                }
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
        }
    }

    // MARK: - 🗂️ Collapsible Filter Drawer Section
    private var filterDrawerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header drawer dengan tombol Reset
            HStack {
                Text("FILTER AKTIVITAS")
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .foregroundColor(.secondary)

                Spacer()

                if hasActiveFilter {
                    Button {
                        HapticManager.shared.impact(style: .light)
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                            selectedStatusFilter = "all"
                            selectedCategoryFilter = "all"
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 9, weight: .bold))
                            Text("Reset")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.cartoonCoral.opacity(0.8))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
                    }
                }
            }

            // Chips Status (Semua, Belum, Tinggi, Rutin, Selesai)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(statusFilters, id: \.id) { filter in
                        let isSelected = selectedStatusFilter == filter.id
                        Button {
                            HapticManager.shared.selection()
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                selectedStatusFilter = filter.id
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: filter.icon)
                                    .font(.system(size: 9, weight: .bold))
                                Text(filter.label)
                                    .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isSelected ? filter.color : Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: isSelected ? 1.6 : 1.0)
                            )
                            .shadow(color: .black, radius: 0, x: isSelected ? 1.5 : 0.8, y: isSelected ? 1.5 : 0.8)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))
                    }
                }
                .padding(.vertical, 2)
            }

            // Chips Kategori Dinamis
            if availableCategories.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(availableCategories, id: \.self) { cat in
                            let isSelected = selectedCategoryFilter.lowercased() == cat.lowercased()
                            Button {
                                HapticManager.shared.selection()
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                    selectedCategoryFilter = cat
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    if cat != "all" {
                                        Image(systemName: "tag.fill")
                                            .font(.system(size: 8, weight: .bold))
                                    }
                                    Text(cat == "all" ? "Semua Kategori" : cat)
                                        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(isSelected ? Color.cartoonYellow : Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.black, lineWidth: isSelected ? 1.6 : 1.0)
                                )
                                .shadow(color: .black, radius: 0, x: isSelected ? 1.5 : 0.8, y: isSelected ? 1.5 : 0.8)
                            }
                            .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(10)
        .background(Color.cartoonBg)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.4))
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }

    // MARK: - 📋 Activity List Section
    private var activityListSection: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.xs) {
            // Header List & Tombol Aksi Cepat
            HStack {
                Text(listHeaderTitle)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Spacer()

                if todayCompletedCount > 0 && selectedStatusFilter == "completed" {
                    Button {
                        HapticManager.shared.impact(style: .light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            isShowingClearCompletedDialog = true
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "trash")
                                .font(.system(size: 9, weight: .bold))
                            Text("Bersihkan Selesai")
                                .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.cartoonPink.opacity(0.8))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))
                }
            }
            .padding(.top, 4)

            // Items List / Empty State
            if filteredItems.isEmpty {
                emptyStateView
                    .padding(.top, 16)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredItems) { item in
                        ActivityCardView(
                            item: item,
                            onToggle: { onToggleItem(item) },
                            onDelete: { onDeleteItem(item) },
                            onTap: { onEditItem(item) }
                        )
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(Color.black.opacity(0.3))

            Text(hasActiveFilter ? "Tidak ada tugas yang cocok dengan filter" : "Belum ada tugas hari ini")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(Color.black.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var listHeaderTitle: String {
        if hasActiveFilter {
            return "Hasil Filter (\(filteredItems.count))"
        }
        return "Daftar Tugas (\(filteredItems.count))"
    }

    private var displayGreetingName: String {
        let auth = GoogleAuthManager.shared
        if auth.isUserLoggedIn, let name = auth.currentUserName, !name.isEmpty {
            return name.components(separatedBy: " ").first ?? "Teman"
        }
        return "Juara"
    }

    private func clearAllCompletedTasks() {
        HapticManager.shared.success()
        SoundManager.shared.playDeleteSound()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            for item in items where item.isCompleted {
                modelContext.delete(item)
            }
            try? modelContext.save()
            isShowingClearCompletedDialog = false
        }
    }
}
