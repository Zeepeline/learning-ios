//
//  ContentView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.timestamp, order: .reverse) private var items: [Item]

    @State private var selectedTab: Int = 0
    @State private var isShowingAddActivity: Bool = false
    @State private var isSidebarOpen: Bool = false

    // State untuk Edit & Delete Dialog
    @State private var itemToEdit: Item?
    @State private var itemToDelete: Item?
    @State private var isShowingDeleteDialog: Bool = false

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

                // Tampilan Halaman Sesuai Tab
                Group {
                    switch selectedTab {
                    case 0:
                        HomeActivityListView(
                            items: items,
                            onEditItem: { item in
                                itemToEdit = item
                            },
                            onToggleItem: { item in
                                toggleItemCompletion(item)
                            },
                            onDeleteItem: { item in
                                confirmDelete(item)
                            }
                        )

                    case 1:
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

                    case 2:
                        ImportantTasksView(
                            items: items,
                            onEditItem: { item in
                                itemToEdit = item
                            },
                            onToggleItem: { item in
                                toggleItemCompletion(item)
                            },
                            onDeleteItem: { item in
                                confirmDelete(item)
                            }
                        )

                    case 3:
                        FocusHubView()

                    case 4:
                        ProfileView()

                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }

            // Floating Bottom Navigation Bar
            VStack {
                Spacer()
                CustomBottomNavBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)

            // Custom Drawer Sidebar Melayang
            SidebarView(isOpen: $isSidebarOpen)

            // 🎨 Reusable Cartoon Pop Confirmation Dialog Component
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

    private var navigationTitleForTab: String {
        switch selectedTab {
        case 0: return "Aktivitas"
        case 1: return "Hari Ini"
        case 2: return "Penting"
        case 3: return "Fokus"
        case 4: return "Profil Saya"
        default: return "Aktivitas"
        }
    }

    private func toggleItemCompletion(_ item: Item) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            item.isCompleted.toggle()
            try? modelContext.save()
            if item.isCompleted {
                HapticManager.shared.success()
                NotificationManager.shared.cancelNotification(for: item)
            } else {
                HapticManager.shared.impact(style: .medium)
            }
            WidgetCenter.shared.reloadAllTimelines()
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
            try? modelContext.save()
            isShowingDeleteDialog = false
            itemToDelete = nil
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = (try? ModelContainer(for: Item.self, configurations: config)) ?? {
        fatalError("Failed to create preview container")
    }()
    
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
