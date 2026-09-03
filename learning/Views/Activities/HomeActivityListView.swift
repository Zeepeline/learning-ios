//
//  HomeActivityListView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI
import SwiftData

struct HomeActivityListView: View {
    @Environment(\.modelContext) private var modelContext
    let items: [Item]
    let onEditItem: (Item) -> Void
    let onToggleItem: (Item) -> Void
    let onDeleteItem: (Item) -> Void

    @State private var searchText: String = ""
    @State private var selectedStatusFilter: String = "all"

    private let statusFilters: [(id: String, label: String, icon: String)] = [
        ("all", "Semua", "tray.full.fill"),
        ("pending", "Tertunda", "hourglass"),
        ("completed", "Selesai", "checkmark.circle.fill"),
        ("high", "Tinggi ⚡️", "bolt.fill")
    ]

    private var completedCount: Int { items.filter { $0.isCompleted }.count }
    private var pendingCount: Int { items.filter { !$0.isCompleted }.count }

    private var filteredItems: [Item] {
        items.filter { item in
            let matchesSearch = searchText.isEmpty ||
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.notes.localizedCaseInsensitiveContains(searchText) ||
                item.category.localizedCaseInsensitiveContains(searchText)

            let matchesFilter: Bool
            switch selectedStatusFilter {
            case "pending":
                matchesFilter = !item.isCompleted
            case "completed":
                matchesFilter = item.isCompleted
            case "high":
                matchesFilter = item.priority == "Tinggi"
            default:
                matchesFilter = true
            }

            return matchesSearch && matchesFilter
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: HIGSpacing.md) {
                // 1. 🌟 Progress Banner Sapaan Harian (HIG Glanceability)
                CartoonProgressBanner(
                    userName: "Bruce",
                    completedCount: completedCount,
                    totalCount: items.count
                )
                .padding(.horizontal, HIGSpacing.md)
                .padding(.top, HIGSpacing.xs)

                // 2. 📊 3 Kartu Mini Ringkasan Statistik
                HStack(spacing: HIGSpacing.xs) {
                    CartoonStatCard(
                        title: "Total Tugas",
                        count: items.count,
                        icon: "list.bullet.clipboard.fill",
                        color: .cartoonYellow
                    )

                    CartoonStatCard(
                        title: "Tertunda",
                        count: pendingCount,
                        icon: "hourglass",
                        color: .cartoonCoral
                    )

                    CartoonStatCard(
                        title: "Selesai",
                        count: completedCount,
                        icon: "checkmark.seal.fill",
                        color: .cartoonMint
                    )
                }
                .padding(.horizontal, HIGSpacing.md)

                // 3. 🔍 Search Bar
                CartoonSearchBar(searchText: $searchText)
                    .padding(.horizontal, HIGSpacing.md)

                // 4. 🏷️ Filter Chips Segment
                CartoonFilterStrip(
                    selectedFilter: $selectedStatusFilter,
                    filters: statusFilters
                )
                .padding(.horizontal, HIGSpacing.md)

                // 5. 🗂️ Konten Daftar Tugas
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
    }

    // MARK: - Daftar Tugas dengan Pemisahan Seksi
    private var taskListContent: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            let pendingItems = filteredItems.filter { !$0.isCompleted }
            let doneItems = filteredItems.filter { $0.isCompleted }

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

            // Seksi 2: Tugas yang Telah Selesai
            if !doneItems.isEmpty {
                HStack(spacing: HIGSpacing.xxs) {
                    Text("Sudah Selesai ✨")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(.secondary)

                    Text("\(doneItems.count)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.cartoonMint)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.black, lineWidth: 1.2))
                }
                .padding(.horizontal, HIGSpacing.md)
                .padding(.top, HIGSpacing.xs)

                LazyVStack(spacing: HIGSpacing.sm) {
                    ForEach(doneItems) { item in
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
        }
    }

    // MARK: - Zero-State Onboarding
    private var zeroStateOnboardingView: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            Text("Inspirasi Tugas Cepat 💡")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, HIGSpacing.md)
                .padding(.top, HIGSpacing.xs)

            VStack(spacing: HIGSpacing.xs) {
                CartoonQuickTemplateCard(
                    title: "Buat Desain UI & Wireframe",
                    category: "Design",
                    icon: "paintbrush.pointed.fill",
                    color: .cartoonYellow
                ) {
                    addQuickTask(title: "Buat Desain UI & Wireframe", category: "Design")
                }

                CartoonQuickTemplateCard(
                    title: "Daily Standup & Sync Tim",
                    category: "Meeting",
                    icon: "person.2.fill",
                    color: .cartoonPink
                ) {
                    addQuickTask(title: "Daily Standup & Sync Tim", category: "Meeting")
                }

                CartoonQuickTemplateCard(
                    title: "Coding & Fix Bug Modul Auth",
                    category: "Coding",
                    icon: "hammer.fill",
                    color: .cartoonMint
                ) {
                    addQuickTask(title: "Coding & Fix Bug Modul Auth", category: "Coding")
                }
            }
            .padding(.horizontal, HIGSpacing.md)
        }
    }

    // MARK: - Empty Search Result
    private var emptySearchResultView: some View {
        VStack(spacing: HIGSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.top, HIGSpacing.lg)

            Text("Tidak Ada Hasil")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.black)

            Text("Tidak ditemukan tugas dengan kata kunci \"\(searchText)\".")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HIGSpacing.md)
    }

    private func addQuickTask(title: String, category: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            let newItem = Item(
                title: title,
                notes: "Dibuat dari inspirasi template cepat",
                timestamp: Date(),
                isCompleted: false,
                priority: "Normal",
                category: category
            )
            modelContext.insert(newItem)
            HapticManager.shared.success()
        }
    }
}
