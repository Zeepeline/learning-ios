//
//  AddHabitView.swift
//  learning
//
//  Created by macbook on 9/6/26.
//

import SwiftUI
import SwiftData
import WidgetKit

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var title: String = ""
    @State private var selectedCategory: String = "Kesehatan"
    @State private var selectedIcon: String = "flame.fill"
    @State private var selectedColorHex: String = "#FF6B6B"
    @State private var selectedFrequency: String = "Harian"
    @State private var errorMessage: String?
    
    // Preset Icon Pilihan Kartun
    private let availableIcons = [
        "flame.fill", "drop.fill", "book.fill", "figure.run",
        "bed.double.fill", "fork.knife", "brain.head.profile", "moon.stars.fill",
        "heart.fill", "bolt.fill", "pencil.and.outline", "leaf.fill"
    ]
    
    // Preset Warna Pastel Kartun
    private let availableColors = [
        ("#FF6B6B", "Merah Coral"),
        ("#FFD166", "Kuning"),
        ("#06D6A0", "Hijau Mint"),
        ("#118AB2", "Biru Langit"),
        ("#B388FF", "Ungu Lavender"),
        ("#FF9E79", "Oranye Pastel")
    ]
    
    private let categories = ["Kesehatan", "Belajar", "Olahraga", "Mindfulness", "Produktivitas"]
    private let frequencies = ["Harian", "Hari Kerja", "Akhir Pekan"]
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    dynamic var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: HIGSpacing.md) {
                    // 1. Preview Kartun Interaktif
                    VStack(spacing: 8) {
                        Text("PREVIEW KEBIASAAN")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: selectedColorHex))
                                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                                    .frame(width: 46, height: 46)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.8))
                                
                                Image(systemName: selectedIcon)
                                    .font(.system(size: 20, weight: .black))
                                    .foregroundColor(.black)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(title.isEmpty ? "Nama Kebiasaan..." : title)
                                    .font(.system(size: 14.5, weight: .heavy, design: .rounded))
                                    .foregroundColor(title.isEmpty ? .secondary : .black)
                                    .lineLimit(1)
                                
                                HStack(spacing: 6) {
                                    Text(selectedCategory)
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.white)
                                        .cornerRadius(6)
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1))
                                    
                                    Text(selectedFrequency)
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white)
                                .shadow(color: .black, radius: 0, x: 2, y: 2)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 1.8))
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    
                    // 2. Input Nama Kebiasaan
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NAMA KEBIASAAN")
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        TextField("Contoh: Minum 2L Air / Baca 15 Menit", text: $title)
                            .font(.system(size: 13.5, weight: .bold, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                            )
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.5))
                            .submitLabel(.done)
                            .onSubmit {
                                if isFormValid {
                                    saveHabit()
                                }
                            }
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    
                    // 3. Pilihan Icon Kartun
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PILIH IKON")
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                            ForEach(availableIcons, id: \.self) { icon in
                                let isSelected = selectedIcon == icon
                                Button {
                                    HapticManager.shared.selection()
                                    selectedIcon = icon
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isSelected ? Color.cartoonYellow : Color.white)
                                            .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                                            .frame(height: 44)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.black, lineWidth: isSelected ? 2.0 : 1.2)
                                            )
                                        
                                        Image(systemName: icon)
                                            .font(.system(size: 16, weight: .black))
                                            .foregroundColor(.black)
                                    }
                                }
                                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                            }
                        }
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    
                    // 4. Pilihan Warna Tema
                    VStack(alignment: .leading, spacing: 6) {
                        Text("WARNA TEMA")
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 10) {
                            ForEach(availableColors, id: \.0) { hex, _ in
                                let isSelected = selectedColorHex == hex
                                Button {
                                    HapticManager.shared.selection()
                                    selectedColorHex = hex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black, lineWidth: isSelected ? 2.4 : 1.2)
                                        )
                                        .overlay(
                                            isSelected ?
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 13, weight: .black))
                                                .foregroundColor(.black)
                                            : nil
                                        )
                                }
                                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                            }
                        }
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    
                    // 5. Pilihan Kategori
                    VStack(alignment: .leading, spacing: 6) {
                        Text("KATEGORI")
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { cat in
                                    let isSelected = selectedCategory == cat
                                    Button {
                                        HapticManager.shared.selection()
                                        selectedCategory = cat
                                    } label: {
                                        Text(cat)
                                            .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(isSelected ? Color.cartoonMint : Color.white)
                                                    .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.black, lineWidth: isSelected ? 1.8 : 1.1)
                                            )
                                    }
                                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                                }
                            }
                            .padding(.horizontal, HIGSpacing.md)
                        }
                        .padding(.horizontal, -HIGSpacing.md)
                    }
                    .padding(.horizontal, HIGSpacing.md)

                    // 6. Pilihan Frekuensi Target
                    VStack(alignment: .leading, spacing: 6) {
                        Text("FREKUENSI TARGET")
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            ForEach(frequencies, id: \.self) { freq in
                                let isSelected = selectedFrequency == freq
                                Button {
                                    HapticManager.shared.selection()
                                    selectedFrequency = freq
                                } label: {
                                    Text(freq)
                                        .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(isSelected ? Color.cartoonYellow : Color.white)
                                                .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.black, lineWidth: isSelected ? 1.8 : 1.1)
                                        )
                                }
                                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                            }
                        }
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                            .padding(.horizontal, HIGSpacing.md)
                    }
                    
                    // 7. Tombol Simpan Kebiasaan di Bawah
                    Button {
                        saveHabit()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14, weight: .black))
                            Text("Buat Kebiasaan Baru")
                                .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isFormValid ? Color.cartoonYellow : Color.gray.opacity(0.3))
                                .shadow(color: .black, radius: 0, x: isFormValid ? 2 : 0, y: isFormValid ? 2 : 0)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.8))
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    .disabled(!isFormValid)
                    .padding(.horizontal, HIGSpacing.md)
                    .padding(.top, 6)
                    .padding(.bottom, HIGSpacing.xl)
                }
                .padding(.vertical, HIGSpacing.md)
            }
            .background(Color.cartoonBg)
            .navigationTitle("Tambah Kebiasaan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Batal") {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundColor(.black)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Simpan") {
                        saveHabit()
                    }
                    .font(.system(.body, design: .rounded).weight(.black))
                    .foregroundColor(isFormValid ? .black : .gray.opacity(0.5))
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func saveHabit() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let newHabit = Habit(
            title: trimmedTitle,
            icon: selectedIcon,
            colorHex: selectedColorHex,
            category: selectedCategory,
            targetFrequency: selectedFrequency,
            completedDates: [],
            createdAt: Date()
        )
        
        modelContext.insert(newHabit)
        
        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
            SoundManager.shared.playTaskCompletedSound()
            dismiss()
        } catch {
            print("⚠️ Gagal menyimpan kebiasaan baru: \(error.localizedDescription)")
            self.errorMessage = "Gagal menyimpan: \(error.localizedDescription)"
        }
    }
}

#Preview {
    AddHabitView()
        .modelContainer(for: Habit.self, inMemory: true)
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
// AddHabitView: helper methods kept here — its body reads private member(s): availableColors, availableIcons, categories, dismiss, errorMessage, frequencies, isFormValid, saveHabit, selectedCategory, selectedColorHex, selectedFrequency, selectedIcon, title.
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

extension AddHabitView {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_af60bd7e94f91bd6"] = { (a: [String]) in a.count >= 10 ? AnyView(VStack(spacing: HIGSpacing.md) {
                    // 1. Preview Kartun Interaktif
                    VStack(spacing: 8) {
                        Text(LocalizedStringKey(a[0]))
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: selectedColorHex))
                                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                                    .frame(width: 46, height: 46)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.8))
                                
                                Image(systemName: selectedIcon)
                                    .font(.system(size: 20, weight: .black))
                                    .foregroundColor(.black)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(title.isEmpty ? "Nama Kebiasaan..." : title)
                                    .font(.system(size: 14.5, weight: .heavy, design: .rounded))
                                    .foregroundColor(title.isEmpty ? .secondary : .black)
                                    .lineLimit(1)
                                
                                HStack(spacing: 6) {
                                    Text(selectedCategory)
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.white)
                                        .cornerRadius(6)
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1))
                                    
                                    Text(selectedFrequency)
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white)
                                .shadow(color: .black, radius: 0, x: 2, y: 2)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 1.8))
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    
                    // 2. Input Nama Kebiasaan
                    VStack(alignment: .leading, spacing: 6) {
                        Text(LocalizedStringKey(a[1]))
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        TextField(LocalizedStringKey(a[2]), text: $title)
                            .font(.system(size: 13.5, weight: .bold, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                            )
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.5))
                            .submitLabel(.done)
                            .onSubmit {
                                if isFormValid {
                                    saveHabit()
                                }
                            }
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    
                    // 3. Pilihan Icon Kartun
                    VStack(alignment: .leading, spacing: 6) {
                        Text(LocalizedStringKey(a[3]))
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                            ForEach(availableIcons, id: \.self) { icon in
                                let isSelected = selectedIcon == icon
                                Button {
                                    HapticManager.shared.selection()
                                    selectedIcon = icon
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isSelected ? Color.cartoonYellow : Color.white)
                                            .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                                            .frame(height: 44)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.black, lineWidth: isSelected ? 2.0 : 1.2)
                                            )
                                        
                                        Image(systemName: icon)
                                            .font(.system(size: 16, weight: .black))
                                            .foregroundColor(.black)
                                    }
                                }
                                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                            }
                        }
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    
                    // 4. Pilihan Warna Tema
                    VStack(alignment: .leading, spacing: 6) {
                        Text(LocalizedStringKey(a[4]))
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 10) {
                            ForEach(availableColors, id: \.0) { hex, _ in
                                let isSelected = selectedColorHex == hex
                                Button {
                                    HapticManager.shared.selection()
                                    selectedColorHex = hex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black, lineWidth: isSelected ? 2.4 : 1.2)
                                        )
                                        .overlay(
                                            isSelected ?
                                            Image(systemName: a[5])
                                                .font(.system(size: 13, weight: .black))
                                                .foregroundColor(.black)
                                            : nil
                                        )
                                }
                                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                            }
                        }
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    
                    // 5. Pilihan Kategori
                    VStack(alignment: .leading, spacing: 6) {
                        Text(LocalizedStringKey(a[6]))
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { cat in
                                    let isSelected = selectedCategory == cat
                                    Button {
                                        HapticManager.shared.selection()
                                        selectedCategory = cat
                                    } label: {
                                        Text(cat)
                                            .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(isSelected ? Color.cartoonMint : Color.white)
                                                    .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.black, lineWidth: isSelected ? 1.8 : 1.1)
                                            )
                                    }
                                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                                }
                            }
                            .padding(.horizontal, HIGSpacing.md)
                        }
                        .padding(.horizontal, -HIGSpacing.md)
                    }
                    .padding(.horizontal, HIGSpacing.md)

                    // 6. Pilihan Frekuensi Target
                    VStack(alignment: .leading, spacing: 6) {
                        Text(LocalizedStringKey(a[7]))
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            ForEach(frequencies, id: \.self) { freq in
                                let isSelected = selectedFrequency == freq
                                Button {
                                    HapticManager.shared.selection()
                                    selectedFrequency = freq
                                } label: {
                                    Text(freq)
                                        .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(isSelected ? Color.cartoonYellow : Color.white)
                                                .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.black, lineWidth: isSelected ? 1.8 : 1.1)
                                        )
                                }
                                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                            }
                        }
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                            .padding(.horizontal, HIGSpacing.md)
                    }
                    
                    // 7. Tombol Simpan Kebiasaan di Bawah
                    Button {
                        saveHabit()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: a[8])
                                .font(.system(size: 14, weight: .black))
                            Text(LocalizedStringKey(a[9]))
                                .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isFormValid ? Color.cartoonYellow : Color.gray.opacity(0.3))
                                .shadow(color: .black, radius: 0, x: isFormValid ? 2 : 0, y: isFormValid ? 2 : 0)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.8))
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    .disabled(!isFormValid)
                    .padding(.horizontal, HIGSpacing.md)
                    .padding(.top, 6)
                    .padding(.bottom, HIGSpacing.xl)
                }
                .padding(.vertical, HIGSpacing.md)) : AnyView(EmptyView()) }
        __s["op_cb5146b181a6d69c"] = { (a: [String]) in a.count >= 1 ? AnyView(Button(LocalizedStringKey(a[0])) {
                        saveHabit()
                    }
                    .font(.system(.body, design: .rounded).weight(.black))
                    .foregroundColor(isFormValid ? .black : .gray.opacity(0.5))
                    .disabled(!isFormValid)) : AnyView(EmptyView()) }
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
        __a["acte47dfa6ac94a2f8b"] = { dismiss() }
        __a["actb3ed149345552820"] = { saveHabit() }
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
