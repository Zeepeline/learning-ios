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

    var body: some View {
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

    var body: some View {
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

    var body: some View {
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

    var body: some View {
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

    var body: some View {
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

    var body: some View {
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
