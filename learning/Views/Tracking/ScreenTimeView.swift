//
//  ScreenTimeView.swift
//  learning
//
//  Created by macbook on 9/5/26.
//

import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity

extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}

struct ScreenTimeView: View {
    @Bindable private var manager = ScreenTimeManager.shared
    @State private var isPickerPresented: Bool = false
    @State private var isAppListPresented: Bool = false
    @State private var isRequestingAuth: Bool = false

    dynamic var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: HIGSpacing.md) {
                // 1. Status Izin FamilyControls (Hanya jika belum diizinkan)
                if !manager.isAuthorized {
                    ScreenTimeAuthPromptCard(
                        isRequestingAuth: $isRequestingAuth,
                        onRequestAuth: {
                            HapticManager.shared.impact(style: .medium)
                            isRequestingAuth = true
                            Task {
                                await manager.requestAuthorization()
                                isRequestingAuth = false
                            }
                        }
                    )
                }

                // 2. Kartu Pengunci & Pemilih Aplikasi Terpadu (Dapat dibuka bottomsheet-nya)
                ScreenTimeShieldManagerCard(
                    manager: manager,
                    onOpenPicker: {
                        HapticManager.shared.impact(style: .light)
                        isPickerPresented = true
                    },
                    onOpenAppList: {
                        HapticManager.shared.impact(style: .light)
                        isAppListPresented = true
                    }
                )

                // 3. Batas Durasi Harian Otomatis (Threshold Lock)
                ScreenTimeDailyLimitCard(manager: manager)

                // 4. Laporan Durasi Penggunaan Aplikasi Dibatasi (Bukan Total Layar Nyala)
                ScreenTimeReportCardView(manager: manager)
            }
            .padding(.horizontal, HIGSpacing.md)
            .padding(.top, HIGSpacing.xxs)
            .padding(.bottom, 110)
        }
        .background(Color.cartoonBg)
        .familyActivityPicker(
            isPresented: $isPickerPresented,
            selection: $manager.activitySelection
        )
        .sheet(isPresented: $isAppListPresented) {
            SelectedAppsBottomSheet(
                manager: manager,
                onOpenPicker: {
                    isPickerPresented = true
                }
            )
            .presentationDetents([.fraction(0.65), .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(22)
        }
        .onAppear {
            manager.checkAuthorizationStatus()
        }
    }
}

// MARK: - 1. Prompt Izin FamilyControls
struct ScreenTimeAuthPromptCard: View {
    @Binding var isRequestingAuth: Bool
    let onRequestAuth: () -> Void

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.cartoonCoral)
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.4))

                    Image(systemName: "key.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Izin Screen Time Diperlukan")
                        .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)

                    Text("Izinkan akses Apple FamilyControls untuk memilih dan mengunci aplikasi.")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }

            Button {
                onRequestAuth()
            } label: {
                HStack(spacing: 6) {
                    if isRequestingAuth {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("Berikan Izin")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                    }
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.cartoonYellow)
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                )
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.5))
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            .disabled(isRequestingAuth)
        }
        .padding(HIGSpacing.md)
        .cartoonCard()
    }
}

// MARK: - 2. Kartu Pengunci & Pemilih Aplikasi Terpadu
struct ScreenTimeShieldManagerCard: View {
    var manager: ScreenTimeManager
    let onOpenPicker: () -> Void
    let onOpenAppList: () -> Void

    private var totalSelectedCount: Int {
        manager.activitySelection.applicationTokens.count + manager.activitySelection.categoryTokens.count
    }

    dynamic var body: some View {
        VStack(spacing: 12) {
            // Header Info & Status Kunci
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)

                    Text("PELINDUNG FOKUS")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(manager.isShieldActive ? Color.cartoonCoral : Color.cartoonMint)
                        .frame(width: 6.5, height: 6.5)
                        .overlay(Circle().stroke(Color.black, lineWidth: 0.8))

                    Text(manager.isShieldActive ? "Terkunci" : "Terbuka")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(manager.isShieldActive ? Color.cartoonCoral.opacity(0.3) : Color.cartoonMint.opacity(0.3))
                )
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1))
            }

            // Ringkasan Pilihan Aplikasi & Tombol Buka Sheet / Picker
            HStack(spacing: 10) {
                Button {
                    if totalSelectedCount > 0 {
                        onOpenAppList()
                    } else {
                        onOpenPicker()
                    }
                } label: {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.cartoonBlue.opacity(0.4))
                                .frame(width: 34, height: 34)
                                .overlay(Circle().stroke(Color.black, lineWidth: 1.2))

                            Image(systemName: "apps.iphone")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text("\(manager.activitySelection.applicationTokens.count) App • \(manager.activitySelection.categoryTokens.count) Kategori")
                                    .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                                    .foregroundColor(.black)

                                if totalSelectedCount > 0 {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Text(totalSelectedCount > 0 ? "Ketuk untuk lihat icon & daftar" : "Belum ada aplikasi dipilih")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                Spacer()

                // Tombol Buka Apple FamilyActivityPicker
                Button {
                    onOpenPicker()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 10, weight: .bold))
                        Text("Pilih")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
            .padding(9)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.7))
            )
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.2))

            // Action: Tombol Kunci / Buka Cepat
            Button {
                HapticManager.shared.impact(style: .medium)
                if manager.isShieldActive {
                    manager.disableAppShield()
                } else {
                    manager.enableAppShield()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: manager.isShieldActive ? "lock.open.fill" : "lock.fill")
                        .font(.system(size: 12, weight: .black))

                    Text(manager.isShieldActive ? "Buka Kunci Aplikasi" : "Kunci Aplikasi Sekarang")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(manager.isShieldActive ? Color.cartoonCoral : Color.cartoonMint)
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                )
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.6))
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
        }
        .padding(HIGSpacing.md)
        .cartoonCard()
    }
}

// MARK: - 3. Kartu Batas Durasi Harian Otomatis (Threshold Lock)
struct ScreenTimeDailyLimitCard: View {
    var manager: ScreenTimeManager

    private let limitPresets: [(label: String, minutes: Int)] = [
        ("15m", 15),
        ("30m", 30),
        ("1 Jam", 60),
        ("2 Jam", 120)
    ]

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            // Header & Toggle
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)

                    Text("KUNCI OTOMATIS BERKALA")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                CartoonToggleSwitch(
                    isOn: Binding(
                        get: { manager.isDailyLimitEnabled },
                        set: { manager.toggleDailyLimit($0) }
                    ),
                    activeColor: Color.cartoonCoral
                )
            }

            Text("Otomatis kunci aplikasi terpilih jika total pemakaian harian melewati batas waktu.")
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundColor(.black.opacity(0.75))

            if manager.isDailyLimitEnabled {
                // Preset Durasi Harian
                HStack(spacing: 6) {
                    ForEach(limitPresets, id: \.minutes) { preset in
                        let isSelected = manager.dailyLimitMinutes == preset.minutes
                        Button {
                            HapticManager.shared.selection()
                            manager.updateDailyLimitMinutes(preset.minutes)
                        } label: {
                            Text(preset.label)
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6.5)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isSelected ? Color.cartoonYellow : Color.white)
                                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.black, lineWidth: isSelected ? 1.6 : 1.0)
                                )
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    }
                }
                .padding(.top, 1)
            }
        }
        .padding(HIGSpacing.md)
        .cartoonCard()
    }
}

// MARK: - 4. ScreenTimeReportCardView (Laporan Penggunaan Aplikasi yang Dibatasi)
struct ScreenTimeReportCardView: View {
    var manager: ScreenTimeManager
    @State private var filter: DeviceActivityFilter = DeviceActivityFilter(
        segment: .daily(
            during: Calendar.current.dateInterval(of: .day, for: Date()) ?? DateInterval(start: Date(), duration: 86400)
        ),
        users: .all,
        devices: .init([.iPhone, .iPad])
    )

    private var reportHeight: CGFloat {
        let appCount = manager.activitySelection.applicationTokens.count
        let categoryCount = manager.activitySelection.categoryTokens.count
        let totalCount = appCount + categoryCount
        
        if totalCount == 0 {
            // Header summary card (70) + spacing (10) + empty hint message (35) + padding
            return 130
        } else {
            // Header summary card (70) + spacing (10) + section title (25) + rows (totalCount * 50) + padding
            return CGFloat(120 + max(totalCount, 1) * 52)
        }
    }

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            Label("PENGGUNAAN APLIKASI DIBATASI HARI INI", systemImage: "chart.bar.xaxis")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundColor(.secondary)

            // Extension Report View Apple (Hanya menghitung durasi aplikasi yang dipilih)
            // allowsHitTesting(false) memungkinkan sentuhan/scroll diteruskan ke parent ScrollView tanpa terblokir
            DeviceActivityReport(.totalActivity, filter: filter)
                .frame(height: reportHeight)
                .allowsHitTesting(false)
        }
        .padding(HIGSpacing.md)
        .cartoonCard()
        .onAppear {
            updateFilter()
        }
        .onChange(of: manager.activitySelection) {
            updateFilter()
        }
    }

    private func updateFilter() {
        if manager.activitySelection.applicationTokens.isEmpty && manager.activitySelection.categoryTokens.isEmpty {
            filter = DeviceActivityFilter(
                segment: .daily(
                    during: Calendar.current.dateInterval(of: .day, for: Date()) ?? DateInterval(start: Date(), duration: 86400)
                ),
                users: .all,
                devices: .init([.iPhone, .iPad])
            )
        } else {
            filter = DeviceActivityFilter(
                segment: .daily(
                    during: Calendar.current.dateInterval(of: .day, for: Date()) ?? DateInterval(start: Date(), duration: 86400)
                ),
                users: .all,
                devices: .init([.iPhone, .iPad]),
                applications: manager.activitySelection.applicationTokens,
                categories: manager.activitySelection.categoryTokens
            )
        }
    }
}

// MARK: - 5. BottomSheet: Daftar Aplikasi & Kategori Terpilih dengan Ikon & Nama Aplikasi Pas
struct SelectedAppsBottomSheet: View {
    var manager: ScreenTimeManager
    let onOpenPicker: () -> Void
    @Environment(\.dismiss) private var dismiss

    dynamic var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: HIGSpacing.sm) {
                    // Header Card Ringkas
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.cartoonLavender)
                                .frame(width: 32, height: 32)
                                .overlay(Circle().stroke(Color.black, lineWidth: 1.3))
                                .shadow(color: .black, radius: 0, x: 1, y: 1)

                            Image(systemName: "apps.iphone")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.black)
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text("Daftar Target Kunci")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)

                            Text("Aplikasi dan kategori ini akan diblokir saat sesi aktif.")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(HIGSpacing.sm)
                    .cartoonCard()

                    // Seksi 1: Aplikasi Spesifik dengan Icon Box & Nama Aplikasi di Sampingnya
                    if !manager.activitySelection.applicationTokens.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 5) {
                                Image(systemName: "app.badge.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text("APLIKASI SPESIFIK (\(manager.activitySelection.applicationTokens.count))")
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .foregroundColor(.secondary)
                            }

                            VStack(spacing: 6) {
                                ForEach(Array(manager.activitySelection.applicationTokens), id: \.self) { token in
                                    HStack(spacing: 10) {
                                        // Badge / Frame Ikon Aplikasi
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 7)
                                                .fill(Color.cartoonLavender.opacity(0.4))
                                                .frame(width: 30, height: 30)
                                                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.black, lineWidth: 1.1))

                                            Label(token)
                                                .labelStyle(.iconOnly)
                                                .scaleEffect(0.85)
                                        }

                                        // Tulisan Nama Aplikasi di samping ikon
                                        Label(token)
                                            .labelStyle(.titleOnly)
                                            .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                                            .foregroundColor(.black)
                                            .lineLimit(1)
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                        Spacer()

                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white)
                                            .shadow(color: .black, radius: 0, x: 1, y: 1)
                                    )
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.1))
                                }
                            }
                        }
                        .padding(HIGSpacing.sm)
                        .cartoonCard()
                    }

                    // Seksi 2: Kategori Aplikasi dengan Icon & Nama Kategori
                    if !manager.activitySelection.categoryTokens.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 5) {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text("KATEGORI APLIKASI (\(manager.activitySelection.categoryTokens.count))")
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .foregroundColor(.secondary)
                            }

                            VStack(spacing: 6) {
                                ForEach(Array(manager.activitySelection.categoryTokens), id: \.self) { token in
                                    HStack(spacing: 10) {
                                        // Badge / Frame Ikon Kategori
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 7)
                                                .fill(Color.cartoonYellow.opacity(0.4))
                                                .frame(width: 30, height: 30)
                                                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.black, lineWidth: 1.1))

                                            Label(token)
                                                .labelStyle(.iconOnly)
                                                .scaleEffect(0.85)
                                        }

                                        // Tulisan Nama Kategori di samping ikon
                                        Label(token)
                                            .labelStyle(.titleOnly)
                                            .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                                            .foregroundColor(.black)
                                            .lineLimit(1)
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                        Spacer()

                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white)
                                            .shadow(color: .black, radius: 0, x: 1, y: 1)
                                    )
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.1))
                                }
                            }
                        }
                        .padding(HIGSpacing.sm)
                        .cartoonCard()
                    }

                    // Tombol Ganti / Ubah Pilihan
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onOpenPicker()
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 12, weight: .black))
                            Text("Ubah Pilihan Aplikasi")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.cartoonYellow)
                                .shadow(color: .black, radius: 0, x: 2, y: 2)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.5))
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    .padding(.top, 2)
                }
                .padding(.horizontal, HIGSpacing.md)
                .padding(.top, HIGSpacing.xs)
                .padding(.bottom, 24)
            }
            .background(Color.cartoonBg)
            .navigationTitle("Aplikasi Terpilih")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.black)
                    }
                }
            }
        }
    }
}

#Preview {
    ScreenTimeView()
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
// ScreenTimeDailyLimitCard: helper methods kept here — its body reads private member(s): limitPresets.
//   To move this into Patch/Generated/, make those member(s) `internal` (drop
//   `private`/`fileprivate`) and re-run `patchcli prepare`.
// ScreenTimeReportCardView: helper methods kept here — its body reads private member(s): filter, reportHeight, updateFilter.
//   To move this into Patch/Generated/, make those member(s) `internal` (drop
//   `private`/`fileprivate`) and re-run `patchcli prepare`.
// ScreenTimeShieldManagerCard: helper methods kept here — its body reads private member(s): totalSelectedCount.
//   To move this into Patch/Generated/, make those member(s) `internal` (drop
//   `private`/`fileprivate`) and re-run `patchcli prepare`.
// SelectedAppsBottomSheet: helper methods kept here — its body reads private member(s): dismiss.
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

extension ScreenTimeDailyLimitCard {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_c612673e6f1c71a8"] = { (a: [String]) in a.count >= 3 ? AnyView(VStack(alignment: .leading, spacing: 9) {
            // Header & Toggle
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: a[0])
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)

                    Text(LocalizedStringKey(a[1]))
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                CartoonToggleSwitch(
                    isOn: Binding(
                        get: { manager.isDailyLimitEnabled },
                        set: { manager.toggleDailyLimit($0) }
                    ),
                    activeColor: Color.cartoonCoral
                )
            }

            Text(LocalizedStringKey(a[2]))
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundColor(.black.opacity(0.75))

            if manager.isDailyLimitEnabled {
                // Preset Durasi Harian
                HStack(spacing: 6) {
                    ForEach(limitPresets, id: \.minutes) { preset in
                        let isSelected = manager.dailyLimitMinutes == preset.minutes
                        Button {
                            HapticManager.shared.selection()
                            manager.updateDailyLimitMinutes(preset.minutes)
                        } label: {
                            Text(preset.label)
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6.5)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isSelected ? Color.cartoonYellow : Color.white)
                                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.black, lineWidth: isSelected ? 1.6 : 1.0)
                                )
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    }
                }
                .padding(.top, 1)
            }
        }
        .padding(HIGSpacing.md)
        .cartoonCard()) : AnyView(EmptyView()) }
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


extension ScreenTimeReportCardView {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_45d6e2ca2356c6a9"] = { (a: [String]) in a.count >= 2 ? AnyView(VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            Label(LocalizedStringKey(a[0]), systemImage: a[1])
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundColor(.secondary)

            // Extension Report View Apple (Hanya menghitung durasi aplikasi yang dipilih)
            // allowsHitTesting(false) memungkinkan sentuhan/scroll diteruskan ke parent ScrollView tanpa terblokir
            DeviceActivityReport(.totalActivity, filter: filter)
                .frame(height: reportHeight)
                .allowsHitTesting(false)
        }
        .padding(HIGSpacing.md)
        .cartoonCard()) : AnyView(EmptyView()) }
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
        var __e: [String: (AnyView) -> AnyView] = [:]
        __e["eff77e462b3df454abc"] = { (content: AnyView) -> AnyView in AnyView(content.onAppear {
            updateFilter()
        }) }
        __e["eff2d3a7fceeaccfc89"] = { (content: AnyView) -> AnyView in AnyView(content.onChange(of: manager.activitySelection) {
            updateFilter()
        }) }
        return __e
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


extension ScreenTimeShieldManagerCard {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_99cfc5941118473e"] = { (a: [String]) in a.count >= 14 ? AnyView(VStack(spacing: 12) {
            // Header Info & Status Kunci
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: a[0])
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)

                    Text(LocalizedStringKey(a[1]))
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(manager.isShieldActive ? Color.cartoonCoral : Color.cartoonMint)
                        .frame(width: 6.5, height: 6.5)
                        .overlay(Circle().stroke(Color.black, lineWidth: 0.8))

                    Text(manager.isShieldActive ? LocalizedStringKey(a[2]) : LocalizedStringKey(a[3]))
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(manager.isShieldActive ? Color.cartoonCoral.opacity(0.3) : Color.cartoonMint.opacity(0.3))
                )
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1))
            }

            // Ringkasan Pilihan Aplikasi & Tombol Buka Sheet / Picker
            HStack(spacing: 10) {
                Button {
                    if totalSelectedCount > 0 {
                        onOpenAppList()
                    } else {
                        onOpenPicker()
                    }
                } label: {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.cartoonBlue.opacity(0.4))
                                .frame(width: 34, height: 34)
                                .overlay(Circle().stroke(Color.black, lineWidth: 1.2))

                            Image(systemName: a[4])
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text("\(manager.activitySelection.applicationTokens.count) App • \(manager.activitySelection.categoryTokens.count) Kategori")
                                    .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                                    .foregroundColor(.black)

                                if totalSelectedCount > 0 {
                                    Image(systemName: a[5])
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Text(totalSelectedCount > 0 ? LocalizedStringKey(a[6]) : LocalizedStringKey(a[7]))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                Spacer()

                // Tombol Buka Apple FamilyActivityPicker
                Button {
                    onOpenPicker()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: a[8])
                            .font(.system(size: 10, weight: .bold))
                        Text(LocalizedStringKey(a[9]))
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
            .padding(9)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.7))
            )
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.2))

            // Action: Tombol Kunci / Buka Cepat
            Button {
                HapticManager.shared.impact(style: .medium)
                if manager.isShieldActive {
                    manager.disableAppShield()
                } else {
                    manager.enableAppShield()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: manager.isShieldActive ? a[10] : a[11])
                        .font(.system(size: 12, weight: .black))

                    Text(manager.isShieldActive ? LocalizedStringKey(a[12]) : LocalizedStringKey(a[13]))
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(manager.isShieldActive ? Color.cartoonCoral : Color.cartoonMint)
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                )
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.6))
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
        }
        .padding(HIGSpacing.md)
        .cartoonCard()) : AnyView(EmptyView()) }
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


extension SelectedAppsBottomSheet {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_e34b8a6b27df9200"] = { (a: [String]) in a.count >= 9 ? AnyView(VStack(spacing: HIGSpacing.sm) {
                    // Header Card Ringkas
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.cartoonLavender)
                                .frame(width: 32, height: 32)
                                .overlay(Circle().stroke(Color.black, lineWidth: 1.3))
                                .shadow(color: .black, radius: 0, x: 1, y: 1)

                            Image(systemName: a[0])
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.black)
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text(LocalizedStringKey(a[1]))
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)

                            Text(LocalizedStringKey(a[2]))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(HIGSpacing.sm)
                    .cartoonCard()

                    // Seksi 1: Aplikasi Spesifik dengan Icon Box & Nama Aplikasi di Sampingnya
                    if !manager.activitySelection.applicationTokens.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 5) {
                                Image(systemName: a[3])
                                    .font(.system(size: 11, weight: .bold))
                                Text("APLIKASI SPESIFIK (\(manager.activitySelection.applicationTokens.count))")
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .foregroundColor(.secondary)
                            }

                            VStack(spacing: 6) {
                                ForEach(Array(manager.activitySelection.applicationTokens), id: \.self) { token in
                                    HStack(spacing: 10) {
                                        // Badge / Frame Ikon Aplikasi
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 7)
                                                .fill(Color.cartoonLavender.opacity(0.4))
                                                .frame(width: 30, height: 30)
                                                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.black, lineWidth: 1.1))

                                            Label(token)
                                                .labelStyle(.iconOnly)
                                                .scaleEffect(0.85)
                                        }

                                        // Tulisan Nama Aplikasi di samping ikon
                                        Label(token)
                                            .labelStyle(.titleOnly)
                                            .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                                            .foregroundColor(.black)
                                            .lineLimit(1)
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                        Spacer()

                                        Image(systemName: a[4])
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white)
                                            .shadow(color: .black, radius: 0, x: 1, y: 1)
                                    )
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.1))
                                }
                            }
                        }
                        .padding(HIGSpacing.sm)
                        .cartoonCard()
                    }

                    // Seksi 2: Kategori Aplikasi dengan Icon & Nama Kategori
                    if !manager.activitySelection.categoryTokens.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 5) {
                                Image(systemName: a[5])
                                    .font(.system(size: 11, weight: .bold))
                                Text("KATEGORI APLIKASI (\(manager.activitySelection.categoryTokens.count))")
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .foregroundColor(.secondary)
                            }

                            VStack(spacing: 6) {
                                ForEach(Array(manager.activitySelection.categoryTokens), id: \.self) { token in
                                    HStack(spacing: 10) {
                                        // Badge / Frame Ikon Kategori
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 7)
                                                .fill(Color.cartoonYellow.opacity(0.4))
                                                .frame(width: 30, height: 30)
                                                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.black, lineWidth: 1.1))

                                            Label(token)
                                                .labelStyle(.iconOnly)
                                                .scaleEffect(0.85)
                                        }

                                        // Tulisan Nama Kategori di samping ikon
                                        Label(token)
                                            .labelStyle(.titleOnly)
                                            .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                                            .foregroundColor(.black)
                                            .lineLimit(1)
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                        Spacer()

                                        Image(systemName: a[6])
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white)
                                            .shadow(color: .black, radius: 0, x: 1, y: 1)
                                    )
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.1))
                                }
                            }
                        }
                        .padding(HIGSpacing.sm)
                        .cartoonCard()
                    }

                    // Tombol Ganti / Ubah Pilihan
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onOpenPicker()
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: a[7])
                                .font(.system(size: 12, weight: .black))
                            Text(LocalizedStringKey(a[8]))
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.cartoonYellow)
                                .shadow(color: .black, radius: 0, x: 2, y: 2)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.5))
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    .padding(.top, 2)
                }
                .padding(.horizontal, HIGSpacing.md)
                .padding(.top, HIGSpacing.xs)) : AnyView(EmptyView()) }
        return __s
    }

    /// Resolved design-system token values for this view's `.hostToken(id)`/
    /// `.fontToken(id)`/numeric/string token slots. Empty when the view uses none.
    @MainActor func __patchTokens() -> [String: PatchHostToken] {
        var __t: [String: PatchHostToken] = [:]
        __t["ct_896c50b68f3107a3"] = .color(Color.cartoonBg)
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
        var __a: [String: () -> Void] = [:]
        __a["act6eb923786bbc276"] = { dismiss() }
        return __a
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
