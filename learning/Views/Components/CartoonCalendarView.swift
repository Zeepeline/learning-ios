//
//  CartoonCalendarView.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import SwiftUI

// MARK: - 📅 Model Sel Kalender (Dengan Unique ID Anti-Bentrok)
struct CartoonDayCell: Identifiable {
    let id: String
    let dayNumber: Int?
    let date: Date?
}

// MARK: - 📅 Custom Cartoon Neo-Brutalist Calendar & Time Picker (Reusable)
struct CartoonCalendarView: View {
    @Binding var selectedDate: Date
    var showTimePicker: Bool = true
    var taskCountForDate: ((Date) -> (total: Int, completed: Int))? = nil
    
    @State private var currentMonth: Date = Date()

    private let calendar = Calendar.current
    private let weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    // Perhitungan Tanggal Lengkap Bebas Duplikasi ID
    private var calendarDays: [CartoonDayCell] {
        var cells: [CartoonDayCell] = []

        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let firstDayOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: currentMonth) else {
            return []
        }

        // Sunday-based weekday (Sunday = 1, Monday = 2 ... Saturday = 7)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let leadingOffset = firstWeekday - 1 // 0..6 sel kosong

        for i in 0..<leadingOffset {
            cells.append(CartoonDayCell(id: "leading-\(i)", dayNumber: nil, date: nil))
        }

        for day in range {
            var dayComponents = components
            dayComponents.day = day
            let date = calendar.date(from: dayComponents)
            cells.append(CartoonDayCell(id: "day-\(day)", dayNumber: day, date: date))
        }

        return cells
    }

    dynamic var body: some View {
        VStack(spacing: HIGSpacing.sm) {
            
            // 1. Header: Bulan & Tahun + Tombol Navigasi < >
            HStack {
                // Judul Bulan & Tahun dengan SF Pro Rounded Heavy
                HStack(spacing: HIGSpacing.xxs) {
                    Text(monthYearString(from: currentMonth))
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(Color.cartoonCoral)
                }

                Spacer()

                // Shortcut "Hari Ini"
                Button {
                    HapticManager.shared.impact(style: .light)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDate = Date()
                        currentMonth = Date()
                    }
                } label: {
                    Text("Hari Ini")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, HIGSpacing.xs)
                        .padding(.vertical, 4)
                        .background(Color.cartoonYellow)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.black, lineWidth: 1.2))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                // Tombol Bulan Sebelumnya <
                Button {
                    HapticManager.shared.impact(style: .light)
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(Color.cartoonCoral)
                        .frame(width: 32, height: 32)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                // Tombol Bulan Selanjutnya >
                Button {
                    HapticManager.shared.impact(style: .light)
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(Color.cartoonCoral)
                        .frame(width: 32, height: 32)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
            .padding(.horizontal, HIGSpacing.xxs)

            // 2. Baris Nama-Nama Hari (SUN, MON, TUE...)
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(height: 24)
                }
            }

            // 3. Grid Angka Tanggal Kalender
            LazyVGrid(columns: columns, spacing: HIGSpacing.xs) {
                ForEach(calendarDays) { cell in
                    if let dayNumber = cell.dayNumber, let cellDate = cell.date {
                        let isSelected = isDaySelected(dayNumber)
                        let isToday = isDayToday(dayNumber)
                        let taskStats = taskCountForDate?(cellDate) ?? (total: 0, completed: 0)

                        Button {
                            HapticManager.shared.selection()
                            selectDay(dayNumber)
                        } label: {
                            VStack(spacing: 2) {
                                Text("\(dayNumber)")
                                    .font(.system(size: 13, weight: isSelected ? .heavy : .bold, design: .rounded))
                                    .foregroundColor(isSelected ? .white : .black)

                                // Task Dot Indicator
                                if taskStats.total > 0 {
                                    Circle()
                                        .fill(
                                            isSelected
                                                ? Color.white
                                                : (taskStats.completed == taskStats.total ? Color.cartoonMint : Color.cartoonCoral)
                                        )
                                        .frame(width: 4.5, height: 4.5)
                                } else {
                                    Circle()
                                        .fill(Color.clear)
                                        .frame(width: 4.5, height: 4.5)
                                }
                            }
                            .frame(width: 36, height: 36)
                            .background(
                                isSelected
                                    ? Color.cartoonCoral
                                    : (isToday ? Color.cartoonYellow.opacity(0.4) : Color.clear)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        Color.black,
                                        lineWidth: isSelected ? 1.8 : (isToday ? 1.4 : 0)
                                    )
                            )
                            .shadow(
                                color: isSelected ? .black : .clear,
                                radius: 0,
                                x: 1.5,
                                y: 1.5
                            )
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    } else {
                        // Ruang Kosong Sebelum Tanggal 1
                        Color.clear
                            .frame(width: 36, height: 36)
                    }
                }
            }

            // 4. Baris Pengaturan Waktu (Jika Diaktifkan)
            if showTimePicker {
                Divider()
                    .padding(.vertical, HIGSpacing.xxs)

                HStack {
                    Text("Waktu")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)

                    Spacer()

                    DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(Color.cartoonCoral)
                        .fontDesign(.rounded)
                        .environment(\.font, .system(size: 13, weight: .heavy, design: .rounded))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.94, green: 0.94, blue: 0.96))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 1.5)
                        )
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                }
            }
        }
        .padding(HIGSpacing.md)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
        .onAppear {
            currentMonth = selectedDate
        }
        .onChange(of: selectedDate) { _, newDate in
            let currentComponents = calendar.dateComponents([.year, .month], from: currentMonth)
            let newComponents = calendar.dateComponents([.year, .month], from: newDate)
            if currentComponents.year != newComponents.year || currentComponents.month != newComponents.month {
                currentMonth = newDate
            }
        }
    }

    // MARK: - Helper Logika Tanggal
    private func monthYearString(from date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "id_ID")))
    }

    private func changeMonth(by amount: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            if let newMonth = calendar.date(byAdding: .month, value: amount, to: currentMonth) {
                currentMonth = newMonth
            }
        }
    }

    private func isDaySelected(_ dayNumber: Int) -> Bool {
        let targetComponents = calendar.dateComponents([.year, .month], from: currentMonth)
        let selectedComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        return targetComponents.year == selectedComponents.year &&
               targetComponents.month == selectedComponents.month &&
               targetComponents.day == dayNumber
    }

    private func isDayToday(_ dayNumber: Int) -> Bool {
        let targetComponents = calendar.dateComponents([.year, .month], from: currentMonth)
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        return targetComponents.year == todayComponents.year &&
               targetComponents.month == todayComponents.month &&
               todayComponents.day == dayNumber
    }

    private func selectDay(_ dayNumber: Int) {
        var components = calendar.dateComponents([.year, .month], from: currentMonth)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedDate)
        components.day = dayNumber
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            if let newDate = calendar.date(from: components) {
                selectedDate = newDate
            }
        }
    }
}

#Preview {
    CartoonCalendarView(selectedDate: .constant(Date()))
        .padding()
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
// CartoonCalendarView: helper methods kept here — its body reads private member(s): calendar, calendarDays, changeMonth, columns, currentMonth, isDaySelected, isDayToday, monthYearString, selectDay, weekdays.
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

extension CartoonCalendarView {
    /// Native renderers for this view's non-lowerable leaves, keyed by the
    /// shipped tree's opaque-slot id. Each is a FACTORY `([String]) -> AnyView`:
    /// a PARAMETERIZED leaf (a slotted custom view with lifted string-literal
    /// args) substitutes the runtime-supplied `a[k]` into its template, so an
    /// OTA patch that only edited a string ships through here (the id is
    /// structural/stable, the new value rides WASM in `BodyEmission.slotArgs`).
    /// A plain leaf ignores its args. Empty for a fully-lowered view.
    @MainActor func __patchSlots() -> [String: ([String]) -> AnyView] {
        var __s: [String: ([String]) -> AnyView] = [:]
        __s["op_8d8c87edcf3427e3"] = { (a: [String]) in a.count >= 4 ? AnyView(HStack {
                // Judul Bulan & Tahun dengan SF Pro Rounded Heavy
                HStack(spacing: HIGSpacing.xxs) {
                    Text(monthYearString(from: currentMonth))
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                    
                    Image(systemName: a[0])
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(Color.cartoonCoral)
                }

                Spacer()

                // Shortcut "Hari Ini"
                Button {
                    HapticManager.shared.impact(style: .light)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDate = Date()
                        currentMonth = Date()
                    }
                } label: {
                    Text(LocalizedStringKey(a[1]))
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, HIGSpacing.xs)
                        .padding(.vertical, 4)
                        .background(Color.cartoonYellow)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.black, lineWidth: 1.2))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                // Tombol Bulan Sebelumnya <
                Button {
                    HapticManager.shared.impact(style: .light)
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: a[2])
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(Color.cartoonCoral)
                        .frame(width: 32, height: 32)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                // Tombol Bulan Selanjutnya >
                Button {
                    HapticManager.shared.impact(style: .light)
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: a[3])
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(Color.cartoonCoral)
                        .frame(width: 32, height: 32)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
            .padding(.horizontal, HIGSpacing.xxs)) : AnyView(EmptyView()) }
        __s["op_a7c777c6d2a583e9"] = { (_: [String]) in AnyView(LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(height: 24)
                }
            }) }
        __s["op_203616dd4268e7e2"] = { (_: [String]) in AnyView(LazyVGrid(columns: columns, spacing: HIGSpacing.xs) {
                ForEach(calendarDays) { cell in
                    if let dayNumber = cell.dayNumber, let cellDate = cell.date {
                        let isSelected = isDaySelected(dayNumber)
                        let isToday = isDayToday(dayNumber)
                        let taskStats = taskCountForDate?(cellDate) ?? (total: 0, completed: 0)

                        Button {
                            HapticManager.shared.selection()
                            selectDay(dayNumber)
                        } label: {
                            VStack(spacing: 2) {
                                Text("\(dayNumber)")
                                    .font(.system(size: 13, weight: isSelected ? .heavy : .bold, design: .rounded))
                                    .foregroundColor(isSelected ? .white : .black)

                                // Task Dot Indicator
                                if taskStats.total > 0 {
                                    Circle()
                                        .fill(
                                            isSelected
                                                ? Color.white
                                                : (taskStats.completed == taskStats.total ? Color.cartoonMint : Color.cartoonCoral)
                                        )
                                        .frame(width: 4.5, height: 4.5)
                                } else {
                                    Circle()
                                        .fill(Color.clear)
                                        .frame(width: 4.5, height: 4.5)
                                }
                            }
                            .frame(width: 36, height: 36)
                            .background(
                                isSelected
                                    ? Color.cartoonCoral
                                    : (isToday ? Color.cartoonYellow.opacity(0.4) : Color.clear)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        Color.black,
                                        lineWidth: isSelected ? 1.8 : (isToday ? 1.4 : 0)
                                    )
                            )
                            .shadow(
                                color: isSelected ? .black : .clear,
                                radius: 0,
                                x: 1.5,
                                y: 1.5
                            )
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    } else {
                        // Ruang Kosong Sebelum Tanggal 1
                        Color.clear
                            .frame(width: 36, height: 36)
                    }
                }
            }) }
        __s["op_e56ee8e62db7d657"] = { (_: [String]) in AnyView(Divider()
                    .padding(.vertical, HIGSpacing.xxs)) }
        __s["op_f1e9de8d27e0452c"] = { (_: [String]) in AnyView(DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(Color.cartoonCoral)
                        .fontDesign(.rounded)
                        .environment(\.font, .system(size: 13, weight: .heavy, design: .rounded))) }
        return __s
    }

    /// Resolved design-system token values for this view's `.hostToken(id)`/
    /// `.fontToken(id)`/numeric/string token slots. Empty when the view uses none.
    @MainActor func __patchTokens() -> [String: PatchHostToken] {
        var __t: [String: PatchHostToken] = [:]
        __t["nt_7be55366dcb65dae"] = .number(Double(HIGSpacing.sm))
        __t["nt_7bfa3866dcc88bd7"] = .number(Double(HIGSpacing.md))
        __t["nt_98ff9976f3b5d171"] = .number(Double(CartoonMetrics.cardCornerRadius))
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
        var __e: [String: (AnyView) -> AnyView] = [:]
        __e["eff65b22e82e2c6bc55"] = { (content: AnyView) -> AnyView in AnyView(content.onAppear {
            currentMonth = selectedDate
        }) }
        __e["effc2d7b3690afb5407"] = { (content: AnyView) -> AnyView in AnyView(content.onChange(of: selectedDate) { _, newDate in
            let currentComponents = calendar.dateComponents([.year, .month], from: currentMonth)
            let newComponents = calendar.dateComponents([.year, .month], from: newDate)
            if currentComponents.year != newComponents.year || currentComponents.month != newComponents.month {
                currentMonth = newDate
            }
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

#endif
// @generated — END OF AUTOGENERATED SECTION. DO NOT EDIT ABOVE (regenerated by `patchcli prepare`).
// PATCH-THUNKS-END
