//
//  EditActivity.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import SwiftUI
import SwiftData
import WidgetKit

struct EditActivity: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var existingItems: [Item]

    // Binding item yang sedang diedit
    @Bindable var item: Item
    var onDelete: (() -> Void)?

    // State form
    @State private var taskTitle: String = ""
    @State private var dueDate: Date = Date()
    @State private var taskDetails: String = ""
    @State private var selectedCategory: String = "Belajar"
    @State private var selectedPriority: String = "Normal"
    @State private var isCompleted: Bool = false
    @State private var isShowingDatePicker: Bool = false
    
    // Scheduler States
    @State private var isSchedulerEnabled: Bool = false
    @State private var selectedRecurrence: RecurrenceRule = .daily
    @State private var selectedCustomSound: String? = "cartoon_bell.caf"

    // Subtasks & Attachments States
    @State private var subtasks: [SubtaskItem] = []
    @State private var imageAttachmentData: Data? = nil

    private let priorities = ["Tinggi", "Normal", "Rendah"]

    // Deteksi Konflik Jadwal (Kecualikan Item Ini Sendiri)
    private var detectedConflicts: [ScheduleConflict] {
        ScheduleConflictDetector.shared.detectConflicts(for: dueDate, in: existingItems, excludingItemId: item.id)
    }

    dynamic var body: some View {
        NavigationStack {
            ZStack {
                Color.cartoonBg
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: HIGSpacing.lg) {
                        
                        // 1. Header Toolbar (Tombol Tutup & Hapus & Simpan Cepat)
                        HStack {
                            CartoonIconButton(icon: "xmark") {
                                HapticManager.shared.impact(style: .light)
                                dismiss()
                            }

                            Spacer()

                            Text("Edit Task")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)

                            Spacer()

                            // Tombol Simpan Cepat di Header Atas (Tanpa Perlu Scroll ke Bawah)
                            Button {
                                HapticManager.shared.success()
                                saveChanges()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 13, weight: .black))
                                    Text("Simpan")
                                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color.cartoonYellow)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.5))
                                .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                            }
                            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                            .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                            CartoonIconButton(icon: "trash.fill", iconColor: .red) {
                                HapticManager.shared.warning()
                                dismiss()
                                onDelete?()
                            }
                        }
                        .padding(.top, HIGSpacing.md)

                        // 2. Status Selesai / Belum Selesai (Toggle Instan Auto-Save)
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isCompleted.toggle()
                                item.isCompleted = isCompleted
                                item.completedAt = isCompleted ? Date() : nil
                                try? modelContext.save()
                                WidgetCenter.shared.reloadAllTimelines()

                                if isCompleted {
                                    HapticManager.shared.success()
                                    SoundManager.shared.playSuccessChime()
                                } else {
                                    HapticManager.shared.impact(style: .medium)
                                }
                            }
                        } label: {
                            HStack(spacing: HIGSpacing.sm) {
                                ZStack {
                                    Circle()
                                        .fill(isCompleted ? Color.cartoonMint : Color.white)
                                        .frame(width: 36, height: 36)
                                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                                        .overlay(Circle().stroke(Color.black, lineWidth: 2))

                                    if isCompleted {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .black))
                                            .foregroundColor(.black)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(isCompleted ? "Status: Selesai" : "Status: Belum Selesai")
                                            .font(.system(size: 14.5, weight: .heavy, design: .rounded))
                                            .foregroundColor(.black)

                                        Text("(Tersimpan)")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }

                                    Text("Ketuk untuk langsung ubah status pengerjaan")
                                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(isCompleted ? Color.cartoonMint : Color.secondary.opacity(0.4))
                            }
                            .padding(HIGSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .fill(isCompleted ? Color.cartoonMint.opacity(0.3) : Color.white)
                                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                        // 3. Form Input Utama
                        VStack(spacing: HIGSpacing.sm) {
                            
                            // Field 1: Task Title
                            HStack(spacing: HIGSpacing.xs) {
                                Text("|")
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                    .foregroundColor(.secondary.opacity(0.6))
                                TextField("Task Title", text: $taskTitle)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .padding(.horizontal, HIGSpacing.md)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .fill(Color.white)
                                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )

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
                                .background(
                                    RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                        .fill(Color.white)
                                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                                    )
                                .overlay(
                                    RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                        .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                                    )
                            }
                            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                            // 🎨 Reusable Cartoon Calendar Component
                            if isShowingDatePicker {
                                CartoonCalendarView(selectedDate: $dueDate)
                                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                            }

                            // ⚠️ Peringatan Tabrakan Jadwal Otomatis
                            if let conflict = detectedConflicts.first {
                                CartoonConflictWarningBanner(conflict: conflict) { suggestedDate in
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        dueDate = suggestedDate
                                    }
                                }
                                .padding(.top, 4)
                                .transition(.scale(scale: 0.95).combined(with: .opacity))
                            }

                            // Field 3: Task Details
                            VStack(alignment: .leading, spacing: HIGSpacing.xxs) {
                                ZStack(alignment: .topLeading) {
                                    if taskDetails.isEmpty {
                                        Text("Catatan atau detail tugas...")
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundColor(.secondary.opacity(0.7))
                                            .padding(.top, HIGSpacing.xs)
                                            .padding(.leading, HIGSpacing.xxs)
                                    }
                                    
                                    TextEditor(text: $taskDetails)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .frame(minHeight: 100)
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                }
                            }
                            .padding(HIGSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .fill(Color.white)
                                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                        }

                        // 4. Checklist & Subtasks (dengan Smart AI Auto-Breakdown)
                        CartoonSubtaskSectionView(
                            subtasks: $subtasks,
                            taskTitle: taskTitle,
                            taskCategory: selectedCategory
                        )

                        // 5. Lampiran Foto / Gambar Referensi
                        CartoonImageAttachmentView(imageData: $imageAttachmentData)

                        // 6. Section Scheduler / Jadwal Rutin (Mirip Pengaturan)
                        schedulerSection

                        // 7. Prioritas Selector Kartun (Tinggi, Normal, Rendah)
                        VStack(alignment: .leading, spacing: HIGSpacing.xs) {
                            Text("Prioritas Tugas")
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)

                            HStack(spacing: HIGSpacing.xs) {
                                ForEach(priorities, id: \.self) { priority in
                                    let isSelected = selectedPriority == priority
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedPriority = priority
                                            HapticManager.shared.selection()
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            if priority == "Tinggi" {
                                                Image(systemName: "bolt.fill")
                                            }
                                            Text(priority)
                                        }
                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(priorityBgColor(for: priority, isSelected: isSelected))
                                                .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.black, lineWidth: isSelected ? 2.0 : 1.4)
                                        )
                                    }
                                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                                }
                            }
                        }

                        // 8. 🎨 Reusable Category Picker Grid
                        CartoonCategoryPicker(selectedCategory: $selectedCategory)
                            .padding(.top, HIGSpacing.xxs)

                        // 9. Tombol Simpan Perubahan Utama di Bawah
                        CartoonPrimaryButton(
                            title: "Simpan Perubahan",
                            icon: "checkmark.circle.fill",
                            bgColor: Color.cartoonYellow,
                            fgColor: .black,
                            isEnabled: !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ) {
                            saveChanges()
                        }
                        .padding(.top, HIGSpacing.xs)
                        .padding(.bottom, 60)
                    }
                    .padding(.horizontal, HIGSpacing.lg)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Selesai") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(.black)
                }
            }
        }
        .onAppear {
            taskTitle = item.title
            dueDate = item.timestamp
            taskDetails = item.notes
            selectedCategory = item.category.isEmpty ? "Belajar" : item.category
            selectedPriority = item.priority.isEmpty ? "Normal" : item.priority
            isCompleted = item.isCompleted
            isSchedulerEnabled = item.isRecurring
            selectedRecurrence = item.recurrence
            selectedCustomSound = item.customSoundName ?? "cartoon_bell.caf"
            subtasks = item.subtasks
            imageAttachmentData = item.imageAttachmentData
        }
    }

    // MARK: - 🔁 Section Scheduler / Jadwal Berulang
    private var schedulerSection: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            HStack {
                HStack(spacing: HIGSpacing.xs) {
                    Image(systemName: "repeat.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Jadwal Rutin / Berulang")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                CartoonToggleSwitch(isOn: $isSchedulerEnabled)
            }
            
            if isSchedulerEnabled {
                VStack(spacing: HIGSpacing.sm) {
                    // Pilihan Frekuensi Berulang
                    HStack(spacing: HIGSpacing.xs) {
                        ForEach(RecurrenceRule.allCases, id: \.self) { rule in
                            if rule != .none {
                                let isSelected = selectedRecurrence == rule
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        selectedRecurrence = rule
                                        HapticManager.shared.selection()
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: rule.icon)
                                            .font(.system(size: 11, weight: .bold))
                                        Text(rule.title)
                                            .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                                    }
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(isSelected ? Color.cartoonYellow : Color.white)
                                            .shadow(color: .black, radius: 0, x: isSelected ? 1.5 : 0.8, y: isSelected ? 1.5 : 0.8)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.black, lineWidth: isSelected ? 1.6 : 1.0)
                                    )
                                }
                                .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))
                            }
                        }
                    }
                    
                    // Pemilih Suara Notifikasi Khusus
                    CartoonAlarmSoundPicker(selectedSoundName: $selectedCustomSound)
                }
                .padding(HIGSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                        .fill(Color.cartoonBg)
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                        .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - 🎨 Helpers Warna Prioritas Kartun
    private func priorityBgColor(for priority: String, isSelected: Bool) -> Color {
        guard isSelected else { return .white }
        switch priority {
        case "Tinggi": return Color.cartoonCoral
        case "Normal": return Color.cartoonYellow
        case "Rendah": return Color.cartoonMint
        default: return Color.white
        }
    }

    // MARK: - 💾 Logic Simpan Perubahan ke SwiftData
    private func saveChanges() {
        let trimmedTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        // Batalkan notifikasi lama
        NotificationManager.shared.cancelNotification(for: item)

        // Update atribut item
        item.title = trimmedTitle
        item.timestamp = dueDate
        item.notes = taskDetails.trimmingCharacters(in: .whitespacesAndNewlines)
        item.category = selectedCategory
        item.priority = selectedPriority
        item.isCompleted = isCompleted
        item.completedAt = isCompleted ? (item.completedAt ?? Date()) : nil
        item.isRecurring = isSchedulerEnabled
        item.recurrence = isSchedulerEnabled ? selectedRecurrence : .none
        item.customSoundName = selectedCustomSound
        item.subtasks = subtasks
        item.imageAttachmentData = imageAttachmentData

        do {
            try modelContext.save()
            
            // Jadwalkan notifikasi baru jika belum selesai
            if !isCompleted {
                Task {
                    await NotificationManager.shared.scheduleNotification(for: item)
                }
            }

            // Sync ke Kalender Apple jika izin diberikan
            Task {
                _ = try? await CalendarSyncManager.shared.addEventToCalendar(title: item.title, startDate: item.timestamp, notes: item.notes)
            }

            // Reload Timeline Widget
            WidgetCenter.shared.reloadAllTimelines()

            HapticManager.shared.success()
            dismiss()
        } catch {
            print("Gagal menyimpan perubahan tugas: \(error.localizedDescription)")
        }
    }
}
