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

    @Bindable var item: Item
    var onDelete: (() -> Void)? = nil

    @State private var taskTitle: String = ""
    @State private var taskDetails: String = ""
    @State private var dueDate: Date = Date()
    @State private var selectedPriority: String = "Normal"
    @State private var selectedCategory: String = "Design"
    @State private var isCompleted: Bool = false
    @State private var getAlert: Bool = true
    @State private var isShowingDatePicker: Bool = false
    
    // Scheduler / Jadwal Rutin States (Mirip di Pengaturan)
    @State private var isSchedulerEnabled: Bool = false
    @State private var selectedRecurrence: RecurrenceRule = .daily
    @State private var selectedCustomSound: String? = "cartoon_bell.caf"

    // Subtasks & Attachments States
    @State private var subtasks: [SubtaskItem] = []
    @State private var imageAttachmentData: Data? = nil

    private let priorities = ["Tinggi", "Normal", "Rendah"]

    // Deteksi Konflik Jadwal (Kecualikan item saat ini)
    private var detectedConflicts: [ScheduleConflict] {
        ScheduleConflictDetector.shared.detectConflicts(
            for: dueDate,
            in: existingItems,
            excludingItemId: item.id
        )
    }

    dynamic var body: some View {
        NavigationStack {
            ZStack {
                // Background Utama
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

                            // 🤖 AI Task Breakdown & Auto-Tag Actions Card
                            CartoonAITaskBreakdownCard(
                                taskTitle: taskTitle,
                                taskNotes: taskDetails,
                                onAddSubtasks: { newTitles in
                                    for t in newTitles {
                                        if !subtasks.contains(where: { $0.title.lowercased() == t.lowercased() }) {
                                            subtasks.append(SubtaskItem(title: t))
                                        }
                                    }
                                },
                                onAutoTagApplied: { cat, priority in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        selectedCategory = cat.rawValue
                                        selectedPriority = priority.rawValue
                                    }
                                }
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
                                                .stroke(Color.black, lineWidth: isSelected ? 1.8 : 1.2)
                                        )
                                    }
                                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                                }
                            }
                        }

                        // 8. Kategori Selector Kartun (10 Kategori Baru)
                        CartoonCategoryPicker(
                            selectedCategory: $selectedCategory
                        )

                        // 9. Tombol Simpan Perubahan (Save Changes)
                        let isTitleValid = !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        Button {
                            HapticManager.shared.success()
                            saveChanges()
                        } label: {
                            HStack(spacing: HIGSpacing.xs) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16, weight: .black))
                                Text("Simpan Perubahan")
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(isTitleValid ? .black : Color.black.opacity(0.4))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(isTitleValid ? Color.cartoonYellow : Color(red: 0.92, green: 0.92, blue: 0.94))
                            .cornerRadius(CartoonMetrics.cardCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                            .shadow(color: .black, radius: 0, x: isTitleValid ? 2.5 : 1.5, y: isTitleValid ? 2.5 : 1.5)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: isTitleValid ? 1.5 : 0))
                        .disabled(!isTitleValid)
                        .padding(.top, HIGSpacing.sm)
                        .padding(.bottom, 60)
                    }
                    .padding(.horizontal, HIGSpacing.lg)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .onAppear {
                taskTitle = item.title
                taskDetails = item.notes
                dueDate = item.timestamp
                selectedPriority = item.priority
                selectedCategory = item.category
                isCompleted = item.isCompleted
                isSchedulerEnabled = item.isRecurring
                selectedRecurrence = item.recurrence
                selectedCustomSound = item.customSoundName ?? "cartoon_bell.caf"
                subtasks = item.subtasks
                imageAttachmentData = item.imageAttachmentData
            }
        }
    }

    // MARK: - 🔄 Section Scheduler / Jadwal Rutin
    private var schedulerSection: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.xs) {
            Text("JADWAL RUTIN / RECURRING")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            VStack(spacing: HIGSpacing.sm) {
                // Switch Aktifkan Pengulangan
                CartoonToggleRow(
                    icon: "repeat",
                    iconColor: .black,
                    iconBgColor: Color.cartoonLavender,
                    title: "Ulangi Aktivitas",
                    subtitle: "Jadwalkan tugas otomatis berkala",
                    isOn: $isSchedulerEnabled,
                    activeColor: Color.cartoonLavender
                )

                if isSchedulerEnabled {
                    VStack(alignment: .leading, spacing: HIGSpacing.xs) {
                        Text("PILIH POLA PENGULANGAN")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(.leading, 2)

                        // Grid Pilihan Aturan Jadwal
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: HIGSpacing.xs) {
                            ForEach(RecurrenceRule.allCases.filter { $0 != .none }) { rule in
                                let isSelected = selectedRecurrence == rule
                                Button {
                                    HapticManager.shared.selection()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        selectedRecurrence = rule
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: rule.icon)
                                            .font(.system(size: 12, weight: .bold))
                                        Text(rule.shortTitle)
                                            .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                                    }
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? rule.badgeColor : Color.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.black, lineWidth: isSelected ? 1.6 : 1.0)
                                    )
                                    .shadow(color: .black, radius: 0, x: isSelected ? 1.5 : 0.5, y: isSelected ? 1.5 : 0.5)
                                }
                                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                            }
                        }
                    }
                    .padding(HIGSpacing.sm)
                    .background(Color.cartoonLavender.opacity(0.15))
                    .cornerRadius(CartoonMetrics.cardCornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                            .stroke(Color.cartoonLavender.opacity(0.5), lineWidth: 1.2)
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
    }

    // MARK: - Helper Methods
    private func saveChanges() {
        let trimmedTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        item.title = trimmedTitle
        item.notes = taskDetails
        item.timestamp = dueDate
        item.priority = selectedPriority
        item.category = selectedCategory
        item.isCompleted = isCompleted
        item.completedAt = isCompleted ? (item.completedAt ?? Date()) : nil
        item.isRecurring = isSchedulerEnabled
        item.recurrenceRule = isSchedulerEnabled ? selectedRecurrence.rawValue : RecurrenceRule.none.rawValue
        item.customSoundName = selectedCustomSound
        item.subtasks = subtasks
        item.imageAttachmentData = imageAttachmentData

        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()

            // Jadwalkan Ulang Notifikasi
            Task {
                await NotificationManager.shared.scheduleNotification(for: item)
            }

            dismiss()
        } catch {
            print("Gagal menyimpan perubahan aktivitas: \(error.localizedDescription)")
        }
    }

    private func priorityBgColor(for priority: String, isSelected: Bool) -> Color {
        guard isSelected else { return Color.white }
        switch priority {
        case "Tinggi": return Color.cartoonCoral
        case "Normal": return Color.cartoonYellow
        case "Rendah": return Color.cartoonMint
        default: return Color.cartoonYellow
        }
    }
}
