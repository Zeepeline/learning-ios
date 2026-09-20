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
                    // 1. ✨ Kartu Kata Motivasi Harian
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

                        // Kartu Riwayat Semua Tugas Selesai (Buka Fullscreen Sheet)
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
        .onAppear {
            debouncedSearchText = rawSearchText
        }
    }

    // MARK: - Greeting Name Helper
    private var displayGreetingName: String {
        let stored = UserDefaults.standard.string(forKey: "userName") ?? ""
        return stored.isEmpty ? "Sahabat" : stored
    }

    // MARK: - Search & Filter Header
    private var searchAndFilterHeader: some View {
        HStack(spacing: HIGSpacing.xs) {
            // Search Input Field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.black)

                TextField("Cari tugas, catatan, kategori...", text: $rawSearchText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .onChange(of: rawSearchText) { _, newVal in
                        debouncedSearchText = newVal
                    }

                if !rawSearchText.isEmpty {
                    Button {
                        rawSearchText = ""
                        debouncedSearchText = ""
                        HapticManager.shared.selection()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 38)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 1.4)
            )
            .shadow(color: .black, radius: 0, x: 1, y: 1)

            // Filter Toggle Button
            Button {
                HapticManager.shared.impact(style: .light)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    isFilterPanelExpanded.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: hasActiveFilter ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 13, weight: .bold))
                    if hasActiveFilter {
                        Circle()
                            .fill(Color.cartoonCoral)
                            .frame(width: 6, height: 6)
                    }
                }
                .foregroundColor(.black)
                .frame(width: 38, height: 38)
                .background(hasActiveFilter ? Color.cartoonYellow : Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black, lineWidth: 1.4)
                )
                .shadow(color: .black, radius: 0, x: 1, y: 1)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
        }
    }

    // MARK: - Filter Drawer Section
    private var filterDrawerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(statusFilters, id: \.id) { filter in
                        let isSelected = selectedStatusFilter == filter.id
                        Button {
                            HapticManager.shared.selection()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                selectedStatusFilter = filter.id
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: filter.icon)
                                    .font(.system(size: 11, weight: .bold))
                                Text(filter.label)
                                    .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(isSelected ? filter.color : Color.white)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.black, lineWidth: isSelected ? 1.6 : 1.0)
                            )
                            .shadow(color: .black, radius: 0, x: isSelected ? 1 : 0, y: isSelected ? 1 : 0)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))
                    }
                }
            }

            // Category Filter Pills
            if availableCategories.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(availableCategories, id: \.self) { cat in
                            let isSelected = selectedCategoryFilter.lowercased() == cat.lowercased()
                            Button {
                                HapticManager.shared.selection()
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    selectedCategoryFilter = cat
                                }
                            } label: {
                                Text(cat == "all" ? "Semua Kategori" : cat)
                                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(isSelected ? Color.cartoonLavender : Color.white)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.black, lineWidth: isSelected ? 1.4 : 0.8)
                                    )
                            }
                            .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.6))
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }

    // MARK: - Activity List Section
    private var activityListSection: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            if filteredItems.isEmpty {
                emptyFilteredView
            } else {
                LazyVStack(spacing: HIGSpacing.sm) {
                    ForEach(filteredItems) { item in
                        ActivityCardView(
                            item: item,
                            onToggle: {
                                onToggleItem(item)
                            },
                            onDelete: {
                                onDeleteItem(item)
                            },
                            onTap: {
                                onEditItem(item)
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Empty Filtered View
    private var emptyFilteredView: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 32, weight: .black))
                .foregroundColor(Color.black)
                .padding(.top, 16)

            Text("Tidak Ada Tugas")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(.black)

            Text("Tidak ada aktivitas yang sesuai dengan filter atau kata kunci saat ini.")
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .foregroundColor(Color.black.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
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

    // MARK: - Clear All Completed Tasks
    private func clearAllCompletedTasks() {
        let completedToday = items.filter { $0.isCompleted && isCompletedToday($0) }.map { $0.persistentModelID }
        for id in completedToday {
            if let model = modelContext.model(for: id) as? Item {
                modelContext.delete(model)
            }
        }
        try? modelContext.save()
        HapticManager.shared.success()
        SoundManager.shared.playDeleteSound()
        withAnimation {
            isShowingClearCompletedDialog = false
        }
    }
}
