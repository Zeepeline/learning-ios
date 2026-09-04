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

    // Binding item yang sedang diedit
    @Bindable var item: Item
    var onDelete: (() -> Void)?

    // State form
    @State private var taskTitle: String = ""
    @State private var dueDate: Date = Date()
    @State private var taskDetails: String = ""
    @State private var selectedCategory: String = "Design"
    @State private var selectedPriority: String = "Normal"
    @State private var isCompleted: Bool = false
    @State private var isShowingDatePicker: Bool = false

    private let priorities = ["Tinggi", "Normal", "Rendah"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cartoonBg
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: HIGSpacing.lg) {
                        
                        // 1. Header Toolbar (Tombol Tutup & Hapus)
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

                            CartoonIconButton(icon: "trash.fill", iconColor: .red) {
                                HapticManager.shared.warning()
                                dismiss()
                                onDelete?()
                            }
                        }
                        .padding(.top, HIGSpacing.md)

                        // 2. Status Selesai / Belum Selesai (Toggle Box Kartun)
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isCompleted.toggle()
                                if isCompleted {
                                    HapticManager.shared.success()
                                } else {
                                    HapticManager.shared.impact(style: .medium)
                                }
                            }
                        } label: {
                            HStack(spacing: HIGSpacing.sm) {
                                ZStack {
                                    Circle()
                                        .fill(isCompleted ? Color.cartoonMint : Color.white)
                                        .frame(width: 32, height: 32)
                                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
                                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)

                                    if isCompleted {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 15, weight: .black))
                                            .foregroundColor(.black)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(isCompleted ? "Status: Selesai ✨" : "Status: Belum Selesai ⏳")
                                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                                        .foregroundColor(.black)

                                    Text("Ketuk untuk mengubah status pengerjaan")
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding(HIGSpacing.md)
                            .background(isCompleted ? Color.cartoonMint.opacity(0.3) : Color.white)
                            .cornerRadius(CartoonMetrics.cardCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                            .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
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
                            .background(Color.white)
                            .cornerRadius(CartoonMetrics.cardCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                            .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
                        }

                        // 4. Prioritas Selector Kartun (Tinggi, Normal, Rendah)
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
                                        .background(priorityBgColor(for: priority, isSelected: isSelected))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.black, lineWidth: isSelected ? 2.0 : 1.4)
                                        )
                                        .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                                    }
                                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                                }
                            }
                        }

                        // 5. 🎨 Reusable Category Picker Component
                        CartoonCategoryPicker(selectedCategory: $selectedCategory)
                            .padding(.top, HIGSpacing.xxs)

                        // 6. Tombol Simpan Perubahan
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
            selectedCategory = item.category.isEmpty ? "Design" : item.category
            selectedPriority = item.priority.isEmpty ? "Normal" : item.priority
            isCompleted = item.isCompleted
        }
    }

    private func priorityBgColor(for priority: String, isSelected: Bool) -> Color {
        guard isSelected else { return Color.white }
        switch priority {
        case "Tinggi": return Color.cartoonPink
        case "Normal": return Color.cartoonYellow
        case "Rendah": return Color.cartoonMint
        default: return Color.white
        }
    }

    private func saveChanges() {
        withAnimation {
            item.title = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            item.timestamp = dueDate
            item.notes = taskDetails
            item.category = selectedCategory
            item.priority = selectedPriority
            item.isCompleted = isCompleted

            // Perbarui jadwal notifikasi lokal
            if !isCompleted && item.timestamp > Date() {
                NotificationManager.shared.scheduleNotification(for: item)
            } else {
                NotificationManager.shared.cancelNotification(for: item)
            }

            // Simpan perubahan ke SQLite shared container secara instan
            try? modelContext.save()

            // Perbarui Widget di Home Screen
            WidgetCenter.shared.reloadAllTimelines()

            HapticManager.shared.success()
            dismiss()
        }
    }
}
