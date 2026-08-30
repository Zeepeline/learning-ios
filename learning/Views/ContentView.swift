//
//  ContentView.swift
//  learning
//
//  Created by macbook on 8/29/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.timestamp, order: .forward) private var items: [Item]
    
    @State private var isShowingAddActivity = false
    @State private var isSidebarOpen = false
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Background dasar aplikasi
            Color.cartoonBg.ignoresSafeArea()

            // 1. Konten Layar Utama Berdasarkan Tab
            NavigationStack {
                ZStack(alignment: .bottom) {
                    // Latar belakang halaman
                    Color.cartoonBg.ignoresSafeArea()

                    // Tampilan Halaman Sesuai Tab
                    Group {
                        switch selectedTab {
                        case 0:
                            activityListView
                        case 1:
                            todayView
                        case 2:
                            importantView
                        case 3:
                            ProfileView()
                        default:
                            activityListView
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Floating Bottom Navigation Bar
                    CustomBottomNavBar(selectedTab: $selectedTab)
                }
                .navigationTitle(navigationTitleForTab)
                .toolbarBackground(Color.cartoonBg, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    // Tombol Hamburger Menu di Kiri Atas
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isSidebarOpen.toggle()
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.title3)
                                .foregroundColor(.cartoonTextPrimary)
                        }
                        .buttonStyle(.plain)
                    }

                    // Tombol Tambah di Kanan Atas (Khusus Tab Tugas)
                    if selectedTab == 0 {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                isShowingAddActivity = true
                            } label: {
                                HStack(spacing: 1) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 13, weight: .black))
                                    Text("Tambah")
                                        .font(.cartoonBadge)
                                }
                                .foregroundColor(.cartoonTextPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .cartoonCard(bgColor: .cartoonYellow, cornerRadius: 10, borderWidth: 1.5, shadowOffset: 1.5)
                            }
                        }
                    }
                }
                .sheet(isPresented: $isShowingAddActivity) {
                    AddActivity()
                }
            }

            // 2. Custom Drawer Sidebar Melayang
            SidebarView(isOpen: $isSidebarOpen)
        }
    }

    // MARK: - Tab 1: Daftar Aktivitas Bergaya Kartu Vertikal
    private var activityListView: some View {
        ScrollView {
            if items.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(items) { item in
                        ActivityCardView(
                            item: item,
                            onToggle: {
                                item.isCompleted.toggle()
                            },
                            onDelete: {
                                deleteItem(item)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 75) // Ruang agar kartu terbawah tidak tertutup bottom bar
        }
    }

    // Tampilan Saat Belum Ada Tugas
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.cartoonYellow)
                    .frame(width: 80, height: 80)
                    .overlay(Circle().stroke(Color.cartoonBorder, lineWidth: 2.5))
                    .shadow(color: .cartoonBorder, radius: 0, x: 3, y: 3)

                Image(systemName: "sparkles")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.cartoonTextPrimary)
            }
            .padding(.top, 50)

            Text("Belum Ada Aktivitas!")
                .font(.cartoonHeadline)
                .foregroundColor(.cartoonTextPrimary)

            Text("Ketuk tombol '+ Tambah' di pojok kanan atas untuk membuat tugas baru.")
                .font(.cartoonSubheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tab 2: Hari Ini
    private var todayView: some View {
        ScrollView {
            let todayItems = items.filter { Calendar.current.isDateInToday($0.timestamp) }
            if todayItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                        .padding(.top, 50)
                    Text("Semua Beres Hari Ini! ☀️")
                        .font(.cartoonHeadline)
                    Text("Tidak ada tugas terjadwal untuk hari ini.")
                        .font(.cartoonSubheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(todayItems) { item in
                        ActivityCardView(
                            item: item,
                            onToggle: { item.isCompleted.toggle() },
                            onDelete: { deleteItem(item) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 75)
        }
    }

    // MARK: - Tab 3: Penting
    private var importantView: some View {
        ScrollView {
            let importantItems = items.filter { $0.priority == "Tinggi" }
            if importantItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                        .padding(.top, 50)
                    Text("Tidak Ada Tugas Prioritas Tinggi")
                        .font(.cartoonHeadline)
                    Text("Semua tugas penting Anda akan muncul di sini.")
                        .font(.cartoonSubheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(importantItems) { item in
                        ActivityCardView(
                            item: item,
                            onToggle: { item.isCompleted.toggle() },
                            onDelete: { deleteItem(item) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
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

    private func deleteItem(_ item: Item) {
        withAnimation {
            modelContext.delete(item)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
