//
//  AddActivity.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI
import SwiftData
import WidgetKit

struct AddActivity: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Form States
    @State private var taskTitle: String = ""
    @State private var dueDate: Date = Date()
    @State private var assignee: String = ""
    @State private var taskDetails: String = ""
    @State private var selectedCategory: String = "Design"
    @State private var getAlert: Bool = true
    @State private var syncToCalendar: Bool = false
    @State private var isShowingDatePicker: Bool = false

    private enum FormField: Hashable {
        case title
        case assignee
        case details
    }
    @FocusState private var focusedField: FormField?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background Cream Cerah (Tap untuk dismiss keyboard)
                Color.cartoonBg
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        focusedField = nil
                    }

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: HIGSpacing.lg) {
                            
                            // 1. Header Toolbar (Tombol X dan Search) - Reusable CartoonIconButton (44pt)
                            HStack {
                                CartoonIconButton(icon: "xmark") {
                                    HapticManager.shared.impact(style: .light)
                                    dismiss()
                                }

                                Spacer()

                                CartoonIconButton(icon: "magnifyingglass") {
                                    HapticManager.shared.impact(style: .light)
                                }
                            }
                            .padding(.top, HIGSpacing.md)

                            // 2. Judul Layar
                            Text("New Tasks")
                                .font(.system(size: 26, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)

                            // 3. Form Input Kartun Neo-Brutalist (4pt/8pt Spatial)
                            VStack(spacing: HIGSpacing.sm) {
                                
                                // Field 1: Task Title
                                HStack(spacing: HIGSpacing.xs) {
                                    Text("|")
                                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                                        .foregroundColor(.secondary.opacity(0.6))
                                    TextField("Task Title", text: $taskTitle)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .focused($focusedField, equals: .title)
                                }
                                .id(FormField.title)
                                .padding(.horizontal, HIGSpacing.md)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(CartoonMetrics.cardCornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                        .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                                )
                                .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)

                                // Field 2: Date Picker Selector
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        isShowingDatePicker.toggle()
                                        HapticManager.shared.selection()
                                    }
                                } label: {
                                    HStack(spacing: HIGSpacing.xs) {
                                        Text("|")
                                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                                            .foregroundColor(.secondary.opacity(0.6))
                                        
                                        Image(systemName: "calendar")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.secondary)
                                        
                                        Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundColor(.black)
                                        
                                        Spacer()
                                        
                                        Image(systemName: isShowingDatePicker ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.black)
                                    }
                                    .padding(.horizontal, HIGSpacing.md)
                                    .frame(height: 50)
                                    .background(Color.white)
                                    .cornerRadius(CartoonMetrics.cardCornerRadius)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                            .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                                    )
                                    .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
                                }
                                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                                // 🎨 Reusable Cartoon Calendar Component
                                if isShowingDatePicker {
                                    CartoonCalendarView(selectedDate: $dueDate)
                                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                                }

                                // Field 3: Assignee
                                HStack(spacing: HIGSpacing.xs) {
                                    Text("|")
                                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                                        .foregroundColor(.secondary.opacity(0.6))
                                    
                                    TextField("Assignee", text: $assignee)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .focused($focusedField, equals: .assignee)
                                    
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 14, weight: .heavy))
                                        .foregroundColor(.secondary)
                                }
                                .id(FormField.assignee)
                                .padding(.horizontal, HIGSpacing.md)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(CartoonMetrics.cardCornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                        .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                                )
                                .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)

                                // Field 4: Large Task Details Area
                                VStack(alignment: .leading, spacing: HIGSpacing.xxs) {
                                    ZStack(alignment: .topLeading) {
                                        if taskDetails.isEmpty {
                                            Text("Add your task details")
                                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                                .foregroundColor(.secondary.opacity(0.7))
                                                .padding(.top, HIGSpacing.xs)
                                                .padding(.leading, HIGSpacing.xxs)
                                        }
                                        
                                        TextEditor(text: $taskDetails)
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .frame(minHeight: 110)
                                            .scrollContentBackground(.hidden)
                                            .background(Color.clear)
                                            .focused($focusedField, equals: .details)
                                    }
                                }
                                .id(FormField.details)
                            .padding(HIGSpacing.sm)
                            .background(Color.white)
                            .cornerRadius(CartoonMetrics.cardCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                            .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)

                            // Utility Icons di Bawah Text Area (Grid, Font, Attachment)
                            HStack(spacing: 0) {
                                Spacer()
                                
                                Button {
                                    HapticManager.shared.impact(style: .light)
                                } label: {
                                    Image(systemName: "square.grid.2x2")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.black)
                                        .frame(width: HIGSpacing.touchTargetMin, height: HIGSpacing.touchTargetMin)
                                        .contentShape(Rectangle())
                                }
                                
                                Button {
                                    HapticManager.shared.impact(style: .light)
                                } label: {
                                    Image(systemName: "textformat")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.black)
                                        .frame(width: HIGSpacing.touchTargetMin, height: HIGSpacing.touchTargetMin)
                                        .contentShape(Rectangle())
                                }
                                
                                Button {
                                    HapticManager.shared.impact(style: .light)
                                } label: {
                                    Image(systemName: "paperclip")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.black)
                                        .frame(width: HIGSpacing.touchTargetMin, height: HIGSpacing.touchTargetMin)
                                        .contentShape(Rectangle())
                                }
                            }
                            .padding(.top, -HIGSpacing.xxs)
                        }

                        // 4. 🎨 Reusable Category Picker Component
                        CartoonCategoryPicker(selectedCategory: $selectedCategory)
                            .padding(.top, HIGSpacing.xxs)

                            Spacer()
                                .frame(height: 2)
                        // 5. 🕹️ Toggles Kartun: Notifikasi & Apple Calendar Sync
                        VStack(spacing: HIGSpacing.xs) {
                            // 🔔 Toggle Notifikasi / Alert (UserNotifications)
                            CartoonToggleRow(
                                icon: "bell.badge.fill",
                                iconColor: .black,
                                iconBgColor: Color.cartoonPink,
                                title: "Get alert for this task",
                                subtitle: "Notifikasi lokal saat mendekati deadline",
                                isOn: $getAlert,
                                activeColor: Color.cartoonCoral
                            )

                            // 📅 Toggle Sinkronisasi ke Apple Calendar (EventKit)
                            CartoonToggleRow(
                                icon: "calendar.badge.plus",
                                iconColor: .black,
                                iconBgColor: Color.cartoonBlue,
                                title: "Sync to Apple Calendar",
                                subtitle: "Otomatis tambahkan jadwal ke kalender",
                                isOn: $syncToCalendar,
                                activeColor: Color.cartoonMint
                            )
                        }
                        .padding(.top, HIGSpacing.xxs)

                        // 6. 🔘 Reusable Primary Button ("Create Task")
                        CartoonPrimaryButton(
                            title: "Create Task",
                            isEnabled: !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ) {
                            createTask()
                        }
                        .padding(.top, HIGSpacing.xs)
                        .padding(.bottom, 60)
                    }
                    .padding(.horizontal, HIGSpacing.lg)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: focusedField) { _, newField in
                    if let newField = newField {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            // Anchor y: 0.25 memposisikan field di area 25% atas layar (banyak ruang lega di bawahnya)
                            proxy.scrollTo(newField, anchor: UnitPoint(x: 0.5, y: 0.25))
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Selesai") {
                        focusedField = nil
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(.black)
                }
            }
        }
    }
}

    // Aksi Simpan Tugas
    private func createTask() {
        let trimmedTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        withAnimation {
            let newItem = Item(
                title: trimmedTitle,
                notes: taskDetails,
                timestamp: dueDate,
                isCompleted: false,
                priority: "Normal",
                category: selectedCategory
            )
            modelContext.insert(newItem)

            // 1. Jadwalkan Pengingat Notifikasi Lokal (UserNotifications)
            if getAlert {
                NotificationManager.shared.scheduleNotification(for: newItem)
            }

            // 2. Sinkronkan ke Apple Calendar (EventKit)
            if syncToCalendar {
                CalendarSyncManager.shared.addEventToCalendar(
                    title: newItem.title,
                    startDate: newItem.timestamp,
                    notes: newItem.notes
                ) { _, _ in }
            }

            // 3. Simpan perubahan ke SQLite shared container secara instan
            try? modelContext.save()

            // 4. Refresh Widget Timeline di Home Screen
            WidgetCenter.shared.reloadAllTimelines()

            HapticManager.shared.success()
            dismiss()
        }
    }
}

#Preview {
    AddActivity()
        .modelContainer(for: Item.self, inMemory: true)
}
