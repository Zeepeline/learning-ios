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

// PATCH-THUNKS-BEGIN (generated by `patchcli prepare` — DO NOT EDIT)
// @generated
// =========================================================================
// AUTOGENERATED BY `patchcli prepare` — DO NOT EDIT THIS SECTION.
//
// Do NOT edit any code in this generated section — neither by hand NOR with
// an AI coding assistant (Copilot, Cursor, Claude, etc.).
//
// Reason: this block is REGENERATED on every `patchcli prepare` run (which
// also runs automatically inside `patchcli build`/`push`/`release`). Any
// manual change here is SILENTLY OVERWRITTEN on the next prepare, and an
// inconsistent thunk can break the OTA fingerprint (causing a MISMATCH that
// blocks your release).
//
// To change a view's behaviour: edit the VIEW SOURCE FILE itself — never
// this generated thunk. To remove this section entirely, delete the block
// from BEGIN to END and re-run `patchcli prepare` (it recreates it).
// =========================================================================
// Patch kept the patch-thunk code for the view(s) below in YOUR file because each is
// declared `private`/`fileprivate` (or its body host-resolves a `private` member) —
// and Swift access control is file-scoped, so a thunk in the separate
// `Patch/Generated/` folder cannot reach it. Only the minimum that genuinely needs
// file-scoped access is here.
// ContentView: helper methods kept here — its body reads private member(s): confirmDelete, deleteItem, isShowingDeleteDialog, itemToDelete, itemToEdit, items, navigationTitleForTab, quickActionManager, toggleItemCompletion.
//   To move this into Patch/Generated/, make those member(s) `internal` (drop
//   `private`/`fileprivate`) and re-run `patchcli prepare`.
#if canImport(SwiftUI)
import SwiftUI
import PatchSDK
import PatchSwiftUI
import PatchRender
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(ActivityKit)
import ActivityKit
#endif
#if canImport(AdSupport)
import AdSupport
#endif
#if canImport(AppIntents)
import AppIntents
#endif
#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif
#if canImport(Combine)
import Combine
#endif
#if canImport(DeviceActivity)
import DeviceActivity
#endif
#if canImport(EventKit)
import EventKit
#endif
#if canImport(ExtensionKit)
import ExtensionKit
#endif
#if canImport(FamilyControls)
import FamilyControls
#endif
#if canImport(Foundation)
import Foundation
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
#if canImport(HealthKit)
import HealthKit
#endif
#if canImport(LocalAuthentication)
import LocalAuthentication
#endif
#if canImport(ManagedSettings)
import ManagedSettings
#endif
#if canImport(Observation)
import Observation
#endif
#if canImport(SafariServices)
import SafariServices
#endif
#if canImport(SwiftData)
import SwiftData
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(UserNotifications)
import UserNotifications
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif

extension ContentView {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_24b0a5a6e1d60e58"] = { (a: [String]) in a.count >= 1 ? AnyView(ZStack {
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
                    title: a[0],
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
        }) : AnyView(EmptyView()) }
        return __s
    }

    /// Resolved design-system token values for this view's `.hostToken(id)`/
    /// `.fontToken(id)`/numeric/string token slots. Empty when the view uses none.
    @MainActor func __patchTokens() -> [String: PatchHostToken] {
        [:]
    }

    /// Per-row indexed native-action slots for this view's `.indexedForEachSlot`
    /// nodes. Each natively evaluates the body-local collection (over `self`) →
    /// a row count + a per-row factory `(Int) -> AnyView` (closing over `self`, so
    /// each row's real per-row native action works). Empty when the view has none.
    @MainActor func __patchRowSlots() -> [String: PatchRowSlot] {
        [:]
    }

    /// Native-action slots for this view's `.actionSlotButton` nodes — an actions-list
    /// Button (`.swipeActions`/`.toolbar`/`.alert`/`Menu`/`.contextMenu`) whose action is a
    /// native method call. Each closure (`() -> Void`, over `self`) runs the real action;
    /// the SDK wires it to the reconstituted Button by id. Empty when the view has none.
    @MainActor func __patchActionSlots() -> [String: () -> Void] {
        [:]
    }

    /// Native effect-modifier slots for this view's `.nativeEffectSlot` modifiers — an
    /// undispatchable `.task`/`.onAppear`/`.refreshable`/`.onSubmit`/gesture whose closure
    /// runs a native side-effect. Each closure (`(AnyView) -> AnyView`, over `self`) applies
    /// the real modifier to its content; the SDK applies it to the rendered subtree by id.
    /// Empty when the view has none.
    @MainActor func __patchEffectSlots() -> [String: (AnyView) -> AnyView] {
        [:]
    }

    /// Child-view callback slots for this view's `.callbackSlot` nodes — a custom child-view
    /// call whose `() -> Void` closure arg lowers to a WASM dispatch sequence. Each closure
    /// returns the full child-view `AnyView` with the callback arg replaced by a stable
    /// forwarder `{ self.__patchDispatchCallback("<id>") }`. The SDK fills the opaque slot
    /// position from this table by id. Empty when the view has no callback slots.
    @MainActor func __patchCallbackSlots() -> [String: () -> AnyView] {
        [:]
    }
}

#endif
// @generated — END OF AUTOGENERATED SECTION. DO NOT EDIT ABOVE (regenerated by `patchcli prepare`).
// PATCH-THUNKS-END
