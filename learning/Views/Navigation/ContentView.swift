//
//  ContentView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.timestamp, order: .reverse) private var items: [Item]

    @State private var selectedTab: Int = 0
    @State private var isShowingAddActivity: Bool = false
    @State private var isSidebarOpen: Bool = false

    // State untuk Pencarian & Filter di Beranda
    @State private var searchText: String = ""
    @State private var selectedStatusFilter: String = "all"

    // State untuk Edit & Delete Dialog
    @State private var itemToEdit: Item? = nil
    @State private var itemToDelete: Item? = nil
    @State private var isShowingDeleteDialog: Bool = false

    // Filter Items Definisi
    private let statusFilters: [(id: String, label: String, icon: String)] = [
        ("all", "Semua", "tray.full.fill"),
        ("pending", "Tertunda", "hourglass"),
        ("completed", "Selesai", "checkmark.circle.fill"),
        ("high", "Tinggi ⚡️", "bolt.fill")
    ]

    // Statistik Cepat
    private var completedCount: Int { items.filter { $0.isCompleted }.count }
    private var pendingCount: Int { items.filter { !$0.isCompleted }.count }
    private var highPriorityCount: Int { items.filter { $0.priority == "Tinggi" }.count }

    // Item terfilter berdasarkan Search & Kategori Status
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
        
        ZStack {
            // Background Lembut
            Color.cartoonBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 🎨 Reusable Custom Top Header Bar
                CartoonHeaderView(
                    title: navigationTitleForTab,
                    onLeadingTap: {
                        HapticManager.shared.impact(style: .light)
                        isSidebarOpen.toggle()
                    },
                    trailingAction: (selectedTab == 0) ? {
                        HapticManager.shared.impact(style: .medium)
                        isShowingAddActivity = true
                    } : nil
                )

                // Tampilan Halaman Sesuai Tab (Menyesuaikan ruang saat keyboard aktif)
                Group {
                    switch selectedTab {
                    case 0:
                        activityListView
                    case 1:
                        todayTimelineView
                    case 2:
                        importantView
                    case 3:
                        ProfileView()
                    default:
                        activityListView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }.onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }

            // Floating Bottom Navigation Bar (Terisolasi hanya TabBar yang menahan posisi dasar)
            VStack {
                Spacer()
                CustomBottomNavBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)

            // 2. Custom Drawer Sidebar Melayang
            SidebarView(isOpen: $isSidebarOpen)

            // 3. 🎨 Reusable Cartoon Pop Confirmation Dialog Component
            if isShowingDeleteDialog, let item = itemToDelete {
                CartoonConfirmDialog(
                    title: "Hapus Tugas?",
                    message: "Apakah kamu yakin ingin menghapus tugas\n\"\(item.title)\"?",
                    onCancel: {
                        HapticManager.shared.impact(style: .light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            isShowingDeleteDialog = false
                            itemToDelete = nil
                        }
                    },
                    onConfirm: {
                        deleteItem(item)
                    }
                )
            }
        }
        .sheet(isPresented: $isShowingAddActivity) {
            AddActivity()
                .presentationDetents([.fraction(0.92), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
        }
        .sheet(item: $itemToEdit) { item in
            EditActivity(item: item) {
                confirmDelete(item)
            }
            .presentationDetents([.fraction(0.92), .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
    }

    // MARK: - Tab 1: 🏠 Daftar Aktivitas Beranda Komprehensif (HIG Aligned)
    private var activityListView: some View {
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
            .padding(.bottom, 85) // Ruang safe area bottom bar
        }
    }

    // Daftar Tugas dengan Pemisahan Seksi
    private var taskListContent: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            let pendingItems = filteredItems.filter { !$0.isCompleted }
            let doneItems = filteredItems.filter { $0.isCompleted }

            // Seksi 1: Tugas yang Perlu Dikerjakan
            if !pendingItems.isEmpty {
                HStack(spacing: HIGSpacing.xxs) {
                    /// Judul seksi untuk menampilkan daftar tugas yang belum diselesaikan (pending).
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
                            onToggle: { toggleItemCompletion(item) },
                            onDelete: { confirmDelete(item) },
                            onTap: {
                                HapticManager.shared.impact(style: .light)
                                itemToEdit = item
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
                            onToggle: { toggleItemCompletion(item) },
                            onDelete: { confirmDelete(item) },
                            onTap: {
                                HapticManager.shared.impact(style: .light)
                                itemToEdit = item
                            }
                        )
                    }
                }
                .padding(.horizontal, HIGSpacing.md)
            }
        }
    }

    // Zero-State Onboarding dengan Inspirasi Template
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

    // Hasil Pencarian Tidak Ditemukan
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

    // MARK: - Tab 2: 📅 Timeline Hari Ini (Sesuai Desain Referensi)
    private var todayTimelineView: some View {
        TodayTimelineView(
            onDeleteItem: { item in
                confirmDelete(item)
            },
            onToggleItem: { item in
                toggleItemCompletion(item)
            },
            onEditItem: { item in
                HapticManager.shared.impact(style: .light)
                itemToEdit = item
            }
        )
    }

    // MARK: - Tab 3: Penting
    private var importantView: some View {
        ScrollView {
            let importantItems = items.filter { $0.priority == "Tinggi" }
            if importantItems.isEmpty {
                VStack(spacing: HIGSpacing.sm) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                        .padding(.top, HIGSpacing.xxl)
                    Text("Tidak Ada Tugas Prioritas Tinggi")
                        .font(.cartoonHeadline)
                    Text("Semua tugas penting Anda akan muncul di sini.")
                        .font(.cartoonSubheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                LazyVStack(spacing: HIGSpacing.sm) {
                    ForEach(importantItems) { item in
                        ActivityCardView(
                            item: item,
                            onToggle: { toggleItemCompletion(item) },
                            onDelete: { confirmDelete(item) },
                            onTap: {
                                HapticManager.shared.impact(style: .light)
                                itemToEdit = item
                            }
                        )
                    }
                }
                .padding(.horizontal, HIGSpacing.md)
                .padding(.top, HIGSpacing.sm)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 75)
        }
    }

    private var navigationTitleForTab: String {
        switch selectedTab {
        case 0: return "Aktivitas"
        case 1: return "Hari Ini"
        case 2: return "Penting"
        case 3: return "Profil Saya"
        default: return "Aktivitas"
        }
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

    private func toggleItemCompletion(_ item: Item) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            item.isCompleted.toggle()
            if item.isCompleted {
                HapticManager.shared.success()
                NotificationManager.shared.cancelNotification(for: item)
            } else {
                HapticManager.shared.impact(style: .medium)
            }
        }
    }

    private func confirmDelete(_ item: Item) {
        HapticManager.shared.warning()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            itemToDelete = item
            isShowingDeleteDialog = true
        }
    }

    private func deleteItem(_ item: Item) {
        HapticManager.shared.warning()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            NotificationManager.shared.cancelNotification(for: item)
            modelContext.delete(item)
            isShowingDeleteDialog = false
            itemToDelete = nil
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Item.self, configurations: config)
    
    let sampleItems = [
        Item(title: "Desain Wireframe App", notes: "Selesaikan flow onboarding", timestamp: Date(), isCompleted: false, priority: "Tinggi", category: "Design"),
        Item(title: "Daily Standup Meeting", notes: "Sync bersama tim iOS", timestamp: Date(), isCompleted: true, priority: "Normal", category: "Meeting"),
        Item(title: "Bug Fixing Auth", notes: "Perbaiki validasi password", timestamp: Date(), isCompleted: false, priority: "Normal", category: "Coding")
    ]
    for item in sampleItems {
        container.mainContext.insert(item)
    }
    
    return ContentView()
        .modelContainer(container)
}
