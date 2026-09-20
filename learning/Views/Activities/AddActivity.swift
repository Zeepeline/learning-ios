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
    @Query private var existingItems: [Item]

    // Form States
    @State private var taskTitle: String = ""
    @State private var taskDetails: String = ""
    @State private var dueDate: Date = Date()
    @State private var selectedCategory: String = "Belajar"
    @State private var getAlert: Bool = true
    @State private var syncToCalendar: Bool = false
    
    // Scheduler / Jadwal Rutin States (Mirip di Pengaturan)
    @State private var isSchedulerEnabled: Bool = false
    @State private var selectedRecurrence: RecurrenceRule = .daily
    @State private var selectedCustomSound: String? = "cartoon_bell.caf"

    // Subtasks & Attachments States
    @State private var subtasks: [SubtaskItem] = []
    @State private var imageAttachmentData: Data? = nil

    // Deteksi Konflik Jadwal
    private var detectedConflicts: [ScheduleConflict] {
        ScheduleConflictDetector.shared.detectConflicts(for: dueDate, in: existingItems)
    }

    dynamic var body: some View {
        NavigationStack {
            ZStack {
                // Background Utama
                Color.cartoonBg
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: HIGSpacing.lg) {
                        
                        // 1. Header Toolbar
                        HStack {
                            CartoonIconButton(icon: "xmark") {
                                dismiss()
                            }

                            Spacer()

                            Text("New Activity")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)

                            Spacer()

                            // Balancing spacer
                            Color.clear.frame(width: 44, height: 44)
                        }
                        .padding(.top, HIGSpacing.md)

                        // 2. Form Input: Title
                        VStack(spacing: HIGSpacing.xs) {
                            HStack(spacing: HIGSpacing.xs) {
                                Text("|")
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                    .foregroundColor(.secondary.opacity(0.6))
                                TextField("Activity Title", text: $taskTitle)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .padding(.horizontal, HIGSpacing.md)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(CartoonMetrics.cardCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                        }

                        // 3. Form Input: Category Picker Grid
                        CartoonCategoryPicker(
                            selectedCategory: $selectedCategory
                        )

                        // 4. Form Input: Details / Description
                        VStack(alignment: .leading, spacing: HIGSpacing.xxs) {
                            Text("DETAILS")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, HIGSpacing.xxs)

                            ZStack(alignment: .topLeading) {
                                if taskDetails.isEmpty {
                                    Text("Tambah catatan atau detail...")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary.opacity(0.6))
                                        .padding(.top, HIGSpacing.sm)
                                        .padding(.leading, HIGSpacing.xs)
                                }

                                TextEditor(text: $taskDetails)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .frame(minHeight: 70)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                            }
                            .padding(HIGSpacing.sm)
                            .background(Color.white)
                            .cornerRadius(CartoonMetrics.cardCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                        }

                        // 5. Form Input: Date & Time Picker + Deteksi Tabrakan Jadwal
                        VStack(alignment: .leading, spacing: HIGSpacing.xs) {
                            Text("DATE & TIME")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, HIGSpacing.xxs)

                            CartoonCalendarView(selectedDate: $dueDate)

                            // ⚠️ Peringatan Tabrakan Jadwal Otomatis
                            if let conflict = detectedConflicts.first {
                                CartoonConflictWarningBanner(conflict: conflict) { suggestedDate in
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        dueDate = suggestedDate
                                    }
                                }
                                .transition(.scale(scale: 0.95).combined(with: .opacity))
                            }
                        }

                        // 6. Checklist & Subtasks (dengan Smart AI Auto-Breakdown)
                        CartoonSubtaskSectionView(
                            subtasks: $subtasks,
                            taskTitle: taskTitle,
                            taskCategory: selectedCategory
                        )

                        // 7. Lampiran Foto / Gambar Referensi
                        CartoonImageAttachmentView(imageData: $imageAttachmentData)

                        // 8. Section Scheduler / Jadwal Rutin
                        schedulerSection

                        // 9. Pengaturan Tambahan (Toggles)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("PENGATURAN TAMBAHAN")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)

                            VStack(spacing: HIGSpacing.xs) {
                                CartoonToggleRow(
                                    icon: "bell.badge.fill",
                                    iconColor: .black,
                                    iconBgColor: Color.cartoonYellow,
                                    title: "Pengingat Notifikasi",
                                    subtitle: "Kirim pemberitahuan saat waktu tiba",
                                    isOn: $getAlert,
                                    activeColor: Color.cartoonMint
                                )

                                CartoonToggleRow(
                                    icon: "calendar.badge.plus",
                                    iconColor: .black,
                                    iconBgColor: Color.cartoonBlue,
                                    title: "Sinkronkan ke Kalender",
                                    subtitle: "Simpan ke aplikasi Kalender Apple",
                                    isOn: $syncToCalendar,
                                    activeColor: Color.cartoonBlue
                                )
                            }
                        }

                        // 10. Tombol Simpan (Create Task)
                        let isTitleValid = !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        Button {
                            createTask()
                        } label: {
                            HStack(spacing: HIGSpacing.xs) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16, weight: .black))
                                Text("Create Task")
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
    }

    // MARK: - Section Scheduler / Jadwal Rutin
    private var schedulerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("JADWAL RUTIN (SCHEDULER)")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            VStack(spacing: HIGSpacing.sm) {
                // Baris Switch Aktifkan Scheduler
                CartoonToggleRow(
                    icon: "repeat.circle.fill",
                    iconColor: .black,
                    iconBgColor: Color.cartoonLavender,
                    title: "Ulangi Tugas",
                    subtitle: "Buat tugas berulang secara otomatis",
                    isOn: $isSchedulerEnabled,
                    activeColor: Color.cartoonLavender
                )

                if isSchedulerEnabled {
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
    }

    // MARK: - Logic Create Task
    private func createTask() {
        let trimmedTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let newItem = Item(
            title: trimmedTitle,
            notes: taskDetails.trimmingCharacters(in: .whitespacesAndNewlines),
            timestamp: dueDate,
            isCompleted: false,
            completedAt: nil,
            priority: "Normal",
            category: selectedCategory,
            isRecurring: isSchedulerEnabled,
            recurrenceRule: isSchedulerEnabled ? selectedRecurrence.rawValue : "Sekali Saja",
            customSoundName: selectedCustomSound,
            subtasks: subtasks,
            imageAttachmentData: imageAttachmentData
        )

        modelContext.insert(newItem)

        do {
            try modelContext.save()

            // Jadwalkan notifikasi jika aktif
            if getAlert {
                Task {
                    await NotificationManager.shared.scheduleNotification(for: newItem)
                }
            }

            // Sync ke Apple Calendar jika diaktifkan
            if syncToCalendar {
                Task {
                    _ = try? await CalendarSyncManager.shared.addEventToCalendar(
                        title: newItem.title,
                        startDate: newItem.timestamp,
                        notes: newItem.notes
                    )
                }
            }

            // Reload Timeline Widget
            WidgetCenter.shared.reloadAllTimelines()

            HapticManager.shared.success()
            dismiss()
        } catch {
            print("Gagal menyimpan tugas baru: \(error.localizedDescription)")
        }
    }
}
