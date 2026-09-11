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

    @State private var searchText: String = ""
    @State private var selectedStatusFilter: String = "all"

    private let statusFilters: [(id: String, label: String, icon: String)] = [
        ("all", "Semua", "tray.full.fill"),
        ("recurring", "Rutin", "repeat"),
        ("pending", "Tertunda", "hourglass"),
        ("completed", "Selesai", "checkmark.circle.fill"),
        ("high", "Tinggi", "bolt.fill")
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

            return matchesSearch && matchesFilter
        }
    }

    dynamic var body: some View {
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
                    Text("Sudah Selesai")
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

    // MARK: - State Ketika Belum Ada Data (Empty State Pertama Kali)
    private var zeroStateOnboardingView: some View {
        VStack(spacing: HIGSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.cartoonLavender)
                    .frame(width: 80, height: 80)
                    .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))

                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.black)
            }
            .padding(.top, HIGSpacing.xl)

            VStack(spacing: HIGSpacing.xxs) {
                Text("Mulai Harimu!")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Text("Tekan tombol '+' di bawah untuk menambahkan aktivitas pertamamu.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HIGSpacing.xl)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HIGSpacing.xl)
    }

    // MARK: - State Ketika Pencarian / Filter Tidak Menemukan Hasil
    private var emptySearchResultView: some View {
        VStack(spacing: HIGSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.top, HIGSpacing.lg)

            Text("Tidak Ada Hasil")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.black)

            Text("Coba kata kunci lain atau ubah filter.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HIGSpacing.xl)
    }
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
// HomeActivityListView: helper methods kept here — its body reads private member(s): completedCount, filteredItems, pendingCount, searchText, selectedStatusFilter, statusFilters.
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

extension HomeActivityListView {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_b26c4e0596741f7d"] = { (_: [String]) in AnyView(CartoonProgressBanner(
                    userName: "Bruce",
                    completedCount: completedCount,
                    totalCount: items.count
                )
                .padding(.horizontal, HIGSpacing.md)
                .padding(.top, HIGSpacing.xs)) }
        __s["op_fa27cdbbd48ad8"] = { (a: [String]) in a.count >= 6 ? AnyView(HStack(spacing: HIGSpacing.xs) {
                    CartoonStatCard(
                        title: a[0],
                        count: items.count,
                        icon: a[1],
                        color: .cartoonYellow
                    )

                    CartoonStatCard(
                        title: a[2],
                        count: pendingCount,
                        icon: a[3],
                        color: .cartoonCoral
                    )

                    CartoonStatCard(
                        title: a[4],
                        count: completedCount,
                        icon: a[5],
                        color: .cartoonMint
                    )
                }
                .padding(.horizontal, HIGSpacing.md)) : AnyView(EmptyView()) }
        __s["op_718d4fecef79d4c7"] = { (_: [String]) in AnyView(CartoonSearchBar(searchText: $searchText)
                    .padding(.horizontal, HIGSpacing.md)) }
        __s["op_32f9d81cc207835c"] = { (_: [String]) in AnyView(CartoonFilterStrip(
                    selectedFilter: $selectedStatusFilter,
                    filters: statusFilters
                )
                .padding(.horizontal, HIGSpacing.md)) }
        __s["op_b2186388f4526d16"] = { (a: [String]) in a.count >= 3 ? AnyView(VStack(spacing: HIGSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.cartoonLavender)
                    .frame(width: 80, height: 80)
                    .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))

                Image(systemName: a[0])
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.black)
            }
            .padding(.top, HIGSpacing.xl)

            VStack(spacing: HIGSpacing.xxs) {
                Text(LocalizedStringKey(a[1]))
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Text(LocalizedStringKey(a[2]))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HIGSpacing.xl)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HIGSpacing.xl)) : AnyView(EmptyView()) }
        __s["op_ebb6d828684d5eda"] = { (a: [String]) in a.count >= 3 ? AnyView(VStack(spacing: HIGSpacing.sm) {
            Image(systemName: a[0])
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.top, HIGSpacing.lg)

            Text(LocalizedStringKey(a[1]))
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.black)

            Text(LocalizedStringKey(a[2]))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HIGSpacing.xl)) : AnyView(EmptyView()) }
        return __s
    }

    /// Resolved design-system token values for this view's `.hostToken(id)`/
    /// `.fontToken(id)`/numeric/string token slots. Empty when the view uses none.
    @MainActor func __patchTokens() -> [String: PatchHostToken] {
        var __t: [String: PatchHostToken] = [:]
        __t["nt_7bfa3866dcc88bd7"] = .number(Double(HIGSpacing.md))
        __t["nt_e9a21343686cc75c"] = .number(Double((items).count))
        __t["nt_cfc936e230275e7d"] = .number(Double((filteredItems).count))
        __t["nt_7be55366dcb65dae"] = .number(Double(HIGSpacing.sm))
        return __t
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
