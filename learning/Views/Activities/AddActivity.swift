//
//  AddActivity.swift
//  learning
//
//  Created by macbook on 8/29/26.
//

import SwiftUI
import SwiftData
import WidgetKit

struct AddActivity: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Form States
    @State private var taskTitle: String = ""
    @State private var taskDetails: String = ""
    @State private var dueDate: Date = Date()
    @State private var selectedCategory: String = "Design"
    @State private var getAlert: Bool = true
    @State private var syncToCalendar: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background Utama
                Color.cartoonBg
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: HIGSpacing.lg) {
                        
                        // 1. Header Judul
                        VStack(alignment: .leading, spacing: HIGSpacing.xxs) {
                            Text("New Activity")
                                .font(.system(size: 26, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                            Text("Create a new activity to boost your daily focus")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, HIGSpacing.xs)

                        // 2. Input Judul Tugas (Kartun Tebal)
                        VStack(alignment: .leading, spacing: HIGSpacing.xxs) {
                            Text("TASK TITLE")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, HIGSpacing.xxs)

                            TextField("e.g. Read Clean Architecture Ch. 3", text: $taskTitle)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .padding(.horizontal, HIGSpacing.md)
                                .frame(height: 52)
                                .background(Color.white)
                                .cornerRadius(CartoonMetrics.cardCornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                        .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                                )
                                .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
                        }

                        // 3. Pilihan Kategori Kartun
                        CartoonCategoryPicker(
                            selectedCategory: $selectedCategory
                        )

                        // 4. Input Catatan / Detail Tugas
                        VStack(alignment: .leading, spacing: HIGSpacing.xxs) {
                            Text("DETAILS & NOTES")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, HIGSpacing.xxs)

                            TextField("Add notes, URLs, or checklist...", text: $taskDetails, axis: .vertical)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .lineLimit(3...5)
                                .padding(HIGSpacing.md)
                                .background(Color.white)
                                .cornerRadius(CartoonMetrics.cardCornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                        .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                                )
                                .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
                        }

                        // 5. Kalender Kartun Lengkap (Bulan, Tanggal & Jam)
                        CartoonCalendarView(
                            selectedDate: $dueDate
                        )

                        // 6. Section Toggle Opsi Notifikasi & Kalender
                        VStack(spacing: HIGSpacing.sm) {
                            CartoonToggleRow(
                                icon: "bell.fill",
                                iconColor: .black,
                                iconBgColor: Color.cartoonYellow,
                                title: "Get alert",
                                subtitle: "Send local reminder before deadline",
                                isOn: $getAlert,
                                activeColor: Color.cartoonYellow
                            )

                            CartoonToggleRow(
                                icon: "calendar.badge.plus",
                                iconColor: .black,
                                iconBgColor: Color.cartoonMint,
                                title: "Sync to Calendar",
                                subtitle: "Add to Apple Calendar events",
                                isOn: $syncToCalendar,
                                activeColor: Color.cartoonMint
                            )
                        }

                        // 7. Tombol Simpan (Create Task)
                        Button {
                            createTask()
                        } label: {
                            HStack(spacing: HIGSpacing.xs) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16, weight: .black))
                                Text("Create Task")
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.cartoonYellow)
                            .cornerRadius(CartoonMetrics.cardCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                            .shadow(color: .black, radius: 0, x: 3, y: 3)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.5))
                        .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                        .padding(.top, HIGSpacing.xs)
                        .padding(.bottom, HIGSpacing.xxl)
                    }
                    .padding(.horizontal, HIGSpacing.md)
                }
            }
            .navigationTitle("Add Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticManager.shared.impact(style: .light)
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .heavy))
                            Text("Cancel")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.5))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                }
            }
        }
    }

    // MARK: - Helper Simpan Data
    private func createTask() {
        guard !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            let item = Item(
                title: taskTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: taskDetails.trimmingCharacters(in: .whitespacesAndNewlines),
                timestamp: dueDate,
                isCompleted: false,
                priority: "Normal",
                category: selectedCategory
            )

            modelContext.insert(item)
            try? modelContext.save()

            // 🔔 Jadwalkan Local Notification jika user memilih "Get alert"
            if getAlert {
                Task {
                    await NotificationManager.shared.scheduleNotification(for: item)
                }
            }

            // 📅 Sinkronisasi ke Apple Calendar jika diaktifkan
            if syncToCalendar {
                Task {
                    do {
                        try await CalendarSyncManager.shared.addEventToCalendar(
                            title: item.title,
                            startDate: item.timestamp,
                            notes: item.notes
                        )
                        print("✅ Tugas berhasil disinkronkan ke Apple Calendar.")
                    } catch {
                        print("❌ Gagal sinkronisasi kalender: \(error.localizedDescription)")
                    }
                }
            }

            // 🔄 Muat ulang widget
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
