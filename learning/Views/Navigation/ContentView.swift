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

    // State untuk AI Assistant Floating Action Sheet
    @State private var isShowingAIAssistant: Bool = false

    dynamic var body: some View {
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

            // 🤖 Floating Action Button (FAB) AI Assistant
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        HapticManager.shared.impact(style: .medium)
                        SoundManager.shared.playPop()
                        isShowingAIAssistant = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(.black)
                            Text("AI Partner")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.cartoonMint)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.black, lineWidth: 2.0)
                        )
                        .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
                    .padding(.trailing, HIGSpacing.md)
                    .padding(.bottom, 76)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)

            // 📱 Floating Bottom Navigation Bar
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
        .sheet(isPresented: $isShowingAIAssistant) {
            AIAssistantSheetView()
                .presentationDetents([.fraction(0.85), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
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
        case 0: return "Beranda"
        case 1: return "Hari Ini"
        case 2: return "Kebiasaan"
        case 3: return "Fokus"
        case 4: return "Profil Saya"
        default: return "Beranda"
        }
    }

    private func toggleItemCompletion(_ item: Item) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            item.isCompleted.toggle()
            item.completedAt = item.isCompleted ? Date() : nil

            if item.isCompleted {
                for i in item.subtasks.indices {
                    item.subtasks[i].isCompleted = true
                }
            }

            try? modelContext.save()

            if item.isCompleted {
                HapticManager.shared.success()
                SoundManager.shared.playSuccessChime()
            }

            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func confirmDelete(_ item: Item) {
        HapticManager.shared.impact(style: .medium)
        itemToDelete = item
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            isShowingDeleteDialog = true
        }
    }

    private func deleteItem(_ item: Item) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            modelContext.delete(item)
            try? modelContext.save()
            itemToDelete = nil
            isShowingDeleteDialog = false
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
