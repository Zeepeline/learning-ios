//
//  ProfileHeaderView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI

struct ProfileHeaderView: View {
    let userName: String
    let userEmail: String
    let userBio: String
    let avatarIcon: String
    let avatarColorHex: String
    var avatarUrl: String = ""
    let totalXP: Int
    let userLevel: Int
    let xpProgressInCurrentLevel: Double
    let onEditTap: () -> Void

    dynamic var body: some View {
        VStack(spacing: HIGSpacing.sm) {
            ZStack(alignment: .bottomTrailing) {
                // Avatar Bulat Kartun (Support Google Avatar & Custom Icon)
                ZStack {
                    Circle()
                        .fill(Color(hex: avatarColorHex))
                        .frame(width: 88, height: 88)
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: CartoonMetrics.thickBorderWidth)
                        )
                        .shadow(color: .black, radius: 0, x: 3, y: 3)
                    
                    if let url = URL(string: avatarUrl), !avatarUrl.isEmpty {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 88, height: 88)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.black, lineWidth: CartoonMetrics.thickBorderWidth)
                                    )
                            case .failure, .empty:
                                cartoonIconFallback
                            @unknown default:
                                cartoonIconFallback
                            }
                        }
                    } else {
                        cartoonIconFallback
                    }
                }

                // Badge Edit Pensil Mini
                Button {
                    HapticManager.shared.impact(style: .light)
                    onEditTap()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Color.cartoonMint)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.6))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
            .padding(.top, HIGSpacing.xs)

            // Nama & Email
            VStack(spacing: HIGSpacing.xxs) {
                Text(userName)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Text(userBio)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)

                Text(userEmail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.8))
            }

            // Badge XP & Level Gamifikasi Real-Time
            VStack(spacing: 6) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.cartoonOrange)
                        Text("Level \(userLevel) Explorer")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                    }

                    Spacer()

                    Text("\(totalXP) XP Total")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }

                // Progress Bar Kartun
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.93, green: 0.93, blue: 0.95))
                            .frame(height: 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: 1.5)
                            )

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.cartoonMint)
                            .frame(width: max(geometry.size.width * CGFloat(xpProgressInCurrentLevel), (totalXP > 0 ? 12 : 0)), height: 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: 1.5)
                            )
                            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: xpProgressInCurrentLevel)
                    }
                }
                .frame(height: 12)
            }
            .padding(HIGSpacing.md)
            .background(Color.white)
            .cornerRadius(CartoonMetrics.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
            )
            .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
            .padding(.horizontal, HIGSpacing.md)
        }
    }

    // MARK: - Fallback Icon
    private var cartoonIconFallback: some View {
        Image(systemName: avatarIcon)
            .resizable()
            .scaledToFit()
            .frame(width: 52, height: 52)
            .foregroundColor(.black)
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
// ProfileHeaderView: helper methods kept here — its body reads private member(s): cartoonIconFallback.
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

extension ProfileHeaderView {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_8fc13a3cfe32d8a0"] = { (a: [String]) in a.count >= 1 ? AnyView(ZStack(alignment: .bottomTrailing) {
                // Avatar Bulat Kartun (Support Google Avatar & Custom Icon)
                ZStack {
                    Circle()
                        .fill(Color(hex: avatarColorHex))
                        .frame(width: 88, height: 88)
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: CartoonMetrics.thickBorderWidth)
                        )
                        .shadow(color: .black, radius: 0, x: 3, y: 3)
                    
                    if let url = URL(string: avatarUrl), !avatarUrl.isEmpty {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 88, height: 88)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.black, lineWidth: CartoonMetrics.thickBorderWidth)
                                    )
                            case .failure, .empty:
                                cartoonIconFallback
                            @unknown default:
                                cartoonIconFallback
                            }
                        }
                    } else {
                        cartoonIconFallback
                    }
                }

                // Badge Edit Pensil Mini
                Button {
                    HapticManager.shared.impact(style: .light)
                    onEditTap()
                } label: {
                    Image(systemName: a[0])
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Color.cartoonMint)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.6))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
            .padding(.top, HIGSpacing.xs)) : AnyView(EmptyView()) }
        __s["op_f6052f164fb8f1c5"] = { (a: [String]) in a.count >= 1 ? AnyView(VStack(spacing: 6) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: a[0])
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.cartoonOrange)
                        Text("Level \(userLevel) Explorer")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                    }

                    Spacer()

                    Text("\(totalXP) XP Total")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }

                // Progress Bar Kartun
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.93, green: 0.93, blue: 0.95))
                            .frame(height: 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: 1.5)
                            )

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.cartoonMint)
                            .frame(width: max(geometry.size.width * CGFloat(xpProgressInCurrentLevel), (totalXP > 0 ? 12 : 0)), height: 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: 1.5)
                            )
                            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: xpProgressInCurrentLevel)
                    }
                }
                .frame(height: 12)
            }
            .padding(HIGSpacing.md)
            .background(Color.white)
            .cornerRadius(CartoonMetrics.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
            )
            .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
            .padding(.horizontal, HIGSpacing.md)) : AnyView(EmptyView()) }
        return __s
    }

    /// Resolved design-system token values for this view's `.hostToken(id)`/
    /// `.fontToken(id)`/numeric/string token slots. Empty when the view uses none.
    @MainActor func __patchTokens() -> [String: PatchHostToken] {
        var __t: [String: PatchHostToken] = [:]
        __t["nt_7be55366dcb65dae"] = .number(Double(HIGSpacing.sm))
        __t["nt_2cf75c8e9945a37"] = .number(Double(HIGSpacing.xxs))
        __t["ct_d717ccf892b8d417"] = .color(.secondary.opacity(0.8))
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
