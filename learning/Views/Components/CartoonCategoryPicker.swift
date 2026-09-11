//
//  CartoonCategoryPicker.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import SwiftUI

// MARK: - 🏷️ Model Kategori Kartun
struct CategoryItem: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    let color: Color
}

// MARK: - 🎨 Kumpulan Kategori Default (Sehari-hari, Belajar, Gaya Hidup & Produktivitas)
enum DefaultCategories {
    static let all: [CategoryItem] = [
        CategoryItem(id: "Belajar", name: "Belajar", icon: "book.fill", color: .cartoonYellow),
        CategoryItem(id: "Kesehatan", name: "Kesehatan", icon: "heart.fill", color: .cartoonPink),
        CategoryItem(id: "Pekerjaan", name: "Pekerjaan", icon: "briefcase.fill", color: .cartoonLavender),
        CategoryItem(id: "Pribadi", name: "Pribadi", icon: "person.fill", color: .cartoonMint),
        CategoryItem(id: "Keuangan", name: "Keuangan", icon: "creditcard.fill", color: .cartoonBlue),
        CategoryItem(id: "Ibadah", name: "Ibadah", icon: "sparkles", color: .cartoonOrange),
        CategoryItem(id: "Rumah", name: "Rumah", icon: "house.fill", color: .cartoonYellow),
        CategoryItem(id: "Sosial", name: "Sosial", icon: "person.2.fill", color: .cartoonPink),
        CategoryItem(id: "Belanja", name: "Belanja", icon: "cart.fill", color: .cartoonMint),
        CategoryItem(id: "Design", name: "Design", icon: "paintbrush.pointed.fill", color: .cartoonLavender),
        CategoryItem(id: "Coding", name: "Coding", icon: "curlybraces", color: .cartoonBlue),
        CategoryItem(id: "Meeting", name: "Meeting", icon: "bubble.left.and.bubble.right.fill", color: .cartoonOrange)
    ]
}

// MARK: - 🏷️ Reusable Chip Kategori Kartun Tunggal
struct CartoonCategoryChip: View {
    let item: CategoryItem
    let isSelected: Bool
    let onSelect: () -> Void

    dynamic var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                onSelect()
            }
        } label: {
            HStack(spacing: 5) {
                // Ikon Stiker Kartun Bulat Mini
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white : item.color.opacity(0.85))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: 1.4)
                        )
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 9.5, weight: .heavy))
                        .foregroundColor(.black)
                }

                // Teks Nama Kategori
                Text(item.name)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(isSelected ? item.color : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: isSelected ? 2.2 : 1.4)
            )
            .shadow(
                color: .black,
                radius: 0,
                x: isSelected ? 2.5 : 1.2,
                y: isSelected ? 2.5 : 1.2
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
    }
}

// MARK: - 🎨 Reusable Kategori Picker Grid
struct CartoonCategoryPicker: View {
    @Binding var selectedCategory: String
    var categories: [CategoryItem] = DefaultCategories.all

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            HStack(spacing: HIGSpacing.xs) {
                Text("CATEGORY")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, HIGSpacing.xxs)

                Spacer()

                if !selectedCategory.isEmpty {
                    Text(selectedCategory)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(selectedCategoryColor.opacity(0.4))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
                }
            }

            // Grid 3-Kolom Kategori
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(categories) { item in
                    CartoonCategoryChip(
                        item: item,
                        isSelected: selectedCategory == item.name,
                        onSelect: {
                            HapticManager.shared.selection()
                            selectedCategory = item.name
                        }
                    )
                }
            }
        }
    }

    private var selectedCategoryColor: Color {
        categories.first(where: { $0.name == selectedCategory })?.color ?? Color.cartoonYellow
    }
}

#Preview {
    CartoonCategoryPicker(selectedCategory: .constant("Belajar"))
        .padding()
        .background(Color.cartoonBg)
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
// CartoonCategoryPicker: helper methods kept here — its body reads private member(s): columns, selectedCategoryColor.
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

extension CartoonCategoryPicker {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_2d662389dc7aa163"] = { (a: [String]) in a.count >= 1 ? AnyView(Text(LocalizedStringKey(a[0]))
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, HIGSpacing.xxs)) : AnyView(EmptyView()) }
        __s["op_d90ac4eac9ebc504"] = { (_: [String]) in AnyView(LazyVGrid(columns: columns, spacing: 8) {
                ForEach(categories) { item in
                    CartoonCategoryChip(
                        item: item,
                        isSelected: selectedCategory == item.name,
                        onSelect: {
                            HapticManager.shared.selection()
                            selectedCategory = item.name
                        }
                    )
                }
            }) }
        return __s
    }

    /// Resolved design-system token values for this view's `.hostToken(id)`/
    /// `.fontToken(id)`/numeric/string token slots. Empty when the view uses none.
    @MainActor func __patchTokens() -> [String: PatchHostToken] {
        var __t: [String: PatchHostToken] = [:]
        __t["nt_7be55366dcb65dae"] = .number(Double(HIGSpacing.sm))
        __t["nt_7bce3566dca34bd3"] = .number(Double(HIGSpacing.xs))
        __t["ct_7310a253eb2a10cd"] = .color(selectedCategoryColor.opacity(0.4))
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
