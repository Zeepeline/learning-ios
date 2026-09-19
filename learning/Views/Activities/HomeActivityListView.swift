//
//  HomeActivityListView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI
import SwiftData
import WidgetKit

struct HomeActivityListView: View {
    @Environment(\.modelContext) private var modelContext
    let items: [Item]
    let onEditItem: (Item) -> Void
    let onToggleItem: (Item) -> Void
    let onDeleteItem: (Item) -> Void

    // Search & Filter state
    @State private var rawSearchText: String = ""
    @State private var debouncedSearchText: String = ""
    @State private var selectedStatusFilter: String = "all"
    @State private var selectedCategoryFilter: String = "all"
    @State private var isFilterPanelExpanded: Bool = false
    @State private var isCompletedSectionExpanded: Bool = false
    @State private var isShowingClearCompletedDialog: Bool = false
    @State private var isShowingHistorySheet: Bool = false

    private let statusFilters: [(id: String, label: String, icon: String)] = [
        ("all", "Semua", "tray.full.fill"),
        ("recurring", "Rutin", "repeat"),
        ("pending", "Tertunda", "hourglass"),
        ("completed", "Selesai", "checkmark.circle.fill"),
        ("high", "Tinggi", "bolt.fill")
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
                matchesFilter = item.isRecurring
            case "pending":
                matchesFilter = !item.isCompleted
            case "completed":
                matchesFilter = item.isCompleted
            case "high":
                matchesFilter = item.priority == "Tinggi"
            default:
                matchesFilter = true
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
                        userName: "Bruce",
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

                        CartoonStatCard(
                            title: "Total Riwayat",
                            count: totalCompletedAllTimeCount,
                            icon: "clock.arrow.circlepath",
                            color: .cartoonYellow
                        )
                    }
                    .padding(.horizontal, HIGSpacing.md)

                    // 4. 🔍 Unified Search Bar & Filter Button (HIG Compact & Rapi)
                    searchAndFilterHeader
                        .padding(.horizontal, HIGSpacing.md)
                        .padding(.top, 2)

                    // 5. 🏷️ Collapsible Filter Drawer (Hanya tampil saat tombol filter diketuk)
                    if isFilterPanelExpanded {
                        filterDrawerSection
                            .padding(.horizontal, HIGSpacing.md)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .move(edge: .top))
                            ))
                    }

                    // 6. 🔖 Active Filter Indicator Chip (Jika ada filter aktif tapi panel tertutup)
                    if hasActiveFilter && !isFilterPanelExpanded {
                        activeFilterBadgeView
                            .padding(.horizontal, HIGSpacing.md)
                    }

                    // 7. 🗂️ Konten Daftar Tugas
                    if items.isEmpty {
                        zeroStateOnboardingView
                    } else if filteredItems.isEmpty {
                        emptySearchResultView
                    } else {
                        taskListContent
                    }
                }
                .padding(.bottom, 85)
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
                        Text("Reset Filter")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(.cartoonCoral)
                    }
                }
            }

            // Status Filter Chips
            CartoonFilterStrip(
                selectedFilter: $selectedStatusFilter,
                filters: statusFilters
            )

            // Category Filter Chips (Jika ada lebih dari 1 kategori)
            if availableCategories.count > 2 {
                categoryFilterRow
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .black, radius: 0, x: 2, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black, lineWidth: 1.4)
        )
    }

    // MARK: - 🔖 Active Filter Badge View
    private var activeFilterBadgeView: some View {
        HStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 11, weight: .bold))
                Text("Filter: \(activeFilterLabel)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
            }
            .foregroundColor(.black)
            .padding(.horizontal, 9)
            .padding(.vertical, 4.5)
            .background(Color.cartoonYellow)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.1))

            Button {
                HapticManager.shared.impact(style: .light)
                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                    selectedStatusFilter = "all"
                    selectedCategoryFilter = "all"
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    // MARK: - Category Filter Strip
    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(availableCategories, id: \.self) { cat in
                    let isSelected = selectedCategoryFilter == cat
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                            selectedCategoryFilter = cat
                            HapticManager.shared.selection()
                        }
                    } label: {
                        Text(cat == "all" ? "Semua Kategori" : cat)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(isSelected ? Color.cartoonLavender : Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: isSelected ? 1.6 : 1.0)
                            )
                            .shadow(color: .black.opacity(isSelected ? 0.15 : 0.05), radius: 0, x: 1, y: 1)
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Daftar Tugas dengan Pemisahan Seksi
    private var taskListContent: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            let pendingItems = filteredItems.filter { !$0.isCompleted }
            let doneItemsToday = filteredItems.filter { $0.isCompleted && (selectedStatusFilter == "completed" || isCompletedToday($0)) }

            // Seksi 1: Tugas yang Perlu Dikerjakan
            if !pendingItems.isEmpty {
                HStack(spacing: HIGSpacing.xxs) {
                    Text("Perlu Dikerjakan")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        
                    Text("\(pendingItems.count)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.cartoonCoral)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.black, lineWidth: 1.2))
                }
                .padding(.horizontal, HIGSpacing.md)
                .padding(.top, HIGSpacing.xxs)

                LazyVStack(spacing: HIGSpacing.sm) {
                    ForEach(pendingItems) { item in
                        ActivityCardView(
                            item: item,
                            onToggle: { onToggleItem(item) },
                            onDelete: { onDeleteItem(item) },
                            onTap: {
                                HapticManager.shared.impact(style: .light)
                                onEditItem(item)
                            }
                        )
                    }
                }
                .padding(.horizontal, HIGSpacing.md)
            }

            // Seksi 2: Tugas yang Selesai Hari Ini (Hanya hari ini, hari berikutnya otomatis diarsipkan ke Riwayat)
            if !doneItemsToday.isEmpty {
                VStack(spacing: HIGSpacing.xs) {
                    HStack {
                        Button {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                                isCompletedSectionExpanded.toggle()
                                HapticManager.shared.selection()
                            }
                        } label: {
                            HStack(spacing: HIGSpacing.xxs) {
                                Image(systemName: isCompletedSectionExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.secondary)

                                Text("Selesai Hari Ini")
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                    .foregroundColor(.secondary)

                                Text("\(doneItemsToday.count)")
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2.5)
                                    .background(Color.cartoonMint)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color.black, lineWidth: 1.2))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    .padding(.top, HIGSpacing.xs)

                    if isCompletedSectionExpanded {
                        LazyVStack(spacing: 6) {
                            ForEach(doneItemsToday) { item in
                                CompletedActivityCardView(
                                    item: item,
                                    onToggle: { onToggleItem(item) },
                                    onDelete: { onDeleteItem(item) },
                                    onTap: {
                                        HapticManager.shared.impact(style: .light)
                                        onEditItem(item)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, HIGSpacing.md)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }

            // Seksi 3: Tombol Akses Riwayat Tugas Selesai Penuh (Dedicated Archive View)
            if totalCompletedAllTimeCount > 0 {
                Button {
                    HapticManager.shared.impact(style: .light)
                    isShowingHistorySheet = true
                } label: {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.cartoonMint)
                                .frame(width: 26, height: 26)
                                .overlay(Circle().stroke(Color.black, lineWidth: 1.2))

                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.black)
                        }

                        Text("Lihat Semua Riwayat Selesai (\(totalCompletedAllTimeCount))")
                            .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.4))
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                .padding(.horizontal, HIGSpacing.md)
                .padding(.top, HIGSpacing.xxs)
            }
        }
    }

    // MARK: - 🎨 Zero-State Onboarding View (Saat App Baru & Kosong)
    private var zeroStateOnboardingView: some View {
        VStack(spacing: HIGSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.cartoonYellow)
                    .frame(width: 80, height: 80)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2.0))
                    .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)

                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.black)
            }
            .padding(.top, HIGSpacing.md)

            VStack(spacing: 4) {
                Text("Mulai Aktivitas Pertamamu!")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Text("Pilih salah satu template cepat di bawah atau buat tugas baru dari tombol '+' di pojok kanan atas.")
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HIGSpacing.lg)
            }

            // 3 Template Cepat
            VStack(spacing: HIGSpacing.xs) {
                CartoonQuickTemplateCard(
                    title: "Belajar Swift & SwiftUI 30 Menit",
                    category: "Belajar",
                    icon: "book.fill",
                    color: .cartoonYellow
                ) {
                    createQuickTask(title: "Belajar Swift & SwiftUI 30 Menit", category: "Belajar", priority: "Tinggi")
                }

                CartoonQuickTemplateCard(
                    title: "Olahraga Pagi & Minum Air Putih",
                    category: "Kesehatan",
                    icon: "figure.run",
                    color: .cartoonPink
                ) {
                    createQuickTask(title: "Olahraga Pagi & Minum Air Putih", category: "Kesehatan", priority: "Normal")
                }

                CartoonQuickTemplateCard(
                    title: "Review Target & Pekerjaan Mingguan",
                    category: "Pekerjaan",
                    icon: "briefcase.fill",
                    color: .cartoonLavender
                ) {
                    createQuickTask(title: "Review Target & Pekerjaan Mingguan", category: "Pekerjaan", priority: "Normal")
                }
            }
            .padding(.horizontal, HIGSpacing.md)
            .padding(.top, HIGSpacing.xs)
        }
    }

    // MARK: - State Ketika Pencarian / Filter Tidak Menemukan Hasil
    private var emptySearchResultView: some View {
        VStack(spacing: HIGSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.top, HIGSpacing.xl)

            Text("Tidak Ada Tugas yang Cocok")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(.black)

            Text("Coba ganti kata kunci pencarian atau pilih filter status yang lain.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, HIGSpacing.lg)

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    rawSearchText = ""
                    debouncedSearchText = ""
                    selectedStatusFilter = "all"
                    selectedCategoryFilter = "all"
                    HapticManager.shared.impact(style: .light)
                }
            } label: {
                Text("Reset Filter & Pencarian")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.cartoonYellow)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.4))
                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            .padding(.top, HIGSpacing.xs)
        }
    }

    // Helper Pembersihan Tugas Selesai Hari Ini
    private func clearAllCompletedTasks() {
        HapticManager.shared.warning()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            let completedTodayList = items.filter { $0.isCompleted && isCompletedToday($0) }
            for item in completedTodayList {
                modelContext.delete(item)
            }
            try? modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
            isShowingClearCompletedDialog = false
        }
    }

    // Helper Pembuatan Tugas Cepat dari Template
    private func createQuickTask(title: String, category: String, priority: String) {
        let newItem = Item(
            title: title,
            notes: "Dibuat otomatis dari Template Cepat",
            timestamp: Date(),
            isCompleted: false,
            priority: priority,
            category: category
        )
        modelContext.insert(newItem)
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        HapticManager.shared.success()
    }
}
