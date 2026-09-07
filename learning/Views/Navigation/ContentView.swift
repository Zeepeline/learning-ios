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
    @Bindable private var quickActionManager = QuickActionManager.shared

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
                    trailingAction: (quickActionManager.selectedTab == 0) ? {
                        HapticManager.shared.impact(style: .medium)
                        quickActionManager.isShowingAddActivity = true
                    } : nil
                )

                // ⚡ Cached Indexed Tab Content Stack (0ms Latency, Zero View Teardown)
                ZStack {
                    // Tab 0: Daftar Tugas / Aktivitas
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
                    .opacity(quickActionManager.selectedTab == 0 ? 1 : 0)
                    .allowsHitTesting(quickActionManager.selectedTab == 0)
                    .zIndex(quickActionManager.selectedTab == 0 ? 1 : 0)

                    // Tab 1: Timeline Hari Ini & Kalender
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
                    .opacity(quickActionManager.selectedTab == 1 ? 1 : 0)
                    .allowsHitTesting(quickActionManager.selectedTab == 1)
                    .zIndex(quickActionManager.selectedTab == 1 ? 1 : 0)

                    // Tab 2: Habit Tracker
                    HabitTrackerView()
                        .opacity(quickActionManager.selectedTab == 2 ? 1 : 0)
                        .allowsHitTesting(quickActionManager.selectedTab == 2)
                        .zIndex(quickActionManager.selectedTab == 2 ? 1 : 0)

                    // Tab 3: Fokus Hub (Pomodoro & Screen Time)
                    FocusHubView()
                        .opacity(quickActionManager.selectedTab == 3 ? 1 : 0)
                        .allowsHitTesting(quickActionManager.selectedTab == 3)
                        .zIndex(quickActionManager.selectedTab == 3 ? 1 : 0)

                    // Tab 4: Profil Saya
                    ProfileView()
                        .opacity(quickActionManager.selectedTab == 4 ? 1 : 0)
                        .allowsHitTesting(quickActionManager.selectedTab == 4)
                        .zIndex(quickActionManager.selectedTab == 4 ? 1 : 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }

            // Floating Bottom Navigation Bar
            VStack {
                Spacer()
                CustomBottomNavBar(selectedTab: $quickActionManager.selectedTab)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)

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
        .sheet(isPresented: $quickActionManager.isShowingAddActivity) {
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
        switch quickActionManager.selectedTab {
        case 0: return "Aktivitas"
        case 1: return "Hari Ini"
        case 2: return "Kebiasaan"
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
                SoundManager.shared.playTaskCompletedSound()
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
        Item(title: "Desain Wireframe App", notes: "Selesaikan figma", timestamp: Date(), isCompleted: false, priority: "Tinggi", category: "Design"),
        Item(title: "Daily Standup", notes: "Via Zoom", timestamp: Date(), isCompleted: true, priority: "Normal", category: "Meeting"),
        Item(title: "Review Pull Request", notes: "Cek code PR #42", timestamp: Date(), isCompleted: false, priority: "Rendah", category: "Coding")
    ]
    for item in sampleItems {
        container.mainContext.insert(item)
    }

    return ContentView()
        .modelContainer(container)
}
