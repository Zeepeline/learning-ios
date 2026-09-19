//
//  CartoonSubtaskSectionView.swift
//  learning
//
//  Created by macbook on 9/18/26.
//

import SwiftUI

// MARK: - 📋 Reusable Cartoon Subtask & Checklist Section
struct CartoonSubtaskSectionView: View {
    @Binding var subtasks: [SubtaskItem]
    var taskTitle: String
    var taskCategory: String

    @State private var newSubtaskText: String = ""
    @FocusState private var isInputFocused: Bool

    private var completedCount: Int {
        subtasks.filter { $0.isCompleted }.count
    }

    private var progress: Double {
        guard !subtasks.isEmpty else { return 0.0 }
        return Double(completedCount) / Double(subtasks.count)
    }

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            // Header Bar
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "checklist")
                        .font(.system(size: 11, weight: .black))
                    Text("CHECKLIST & SUBTASK")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.secondary)

                Spacer()

                // Tombol Smart AI Breakdown
                Button {
                    generateSmartSubtasks()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .heavy))
                        Text("Pecah Otomatis")
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cartoonYellow)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.black, lineWidth: 1.2)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 0, x: 1, y: 1)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }

            // Progress Bar (Jika ada subtask)
            if !subtasks.isEmpty {
                VStack(spacing: 4) {
                    HStack {
                        Text("\(completedCount) dari \(subtasks.count) selesai")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)

                        Spacer()

                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                    }

                    // Progress Track
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.08))
                                .frame(height: 8)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))

                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.cartoonMint)
                                .frame(width: max(0, geo.size.width * CGFloat(progress)), height: 8)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
                                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: progress)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(8)
                .background(Color.cartoonMint.opacity(0.12))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cartoonMint.opacity(0.4), lineWidth: 1.0))
            }

            // Daftar Subtask
            VStack(spacing: 6) {
                ForEach($subtasks) { $item in
                    HStack(spacing: 8) {
                        // Checkbox
                        Button {
                            HapticManager.shared.selection()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                item.isCompleted.toggle()
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(item.isCompleted ? Color.cartoonMint : Color.white)
                                    .frame(width: 20, height: 20)
                                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.black, lineWidth: 1.4))

                                if item.isCompleted {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(.black)
                                }
                            }
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                        // Judul Subtask
                        Text(item.title)
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .strikethrough(item.isCompleted, color: .black.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Tombol Hapus Subtask
                        Button {
                            HapticManager.shared.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                subtasks.removeAll { $0.id == item.id }
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.1))
                    .shadow(color: .black.opacity(0.08), radius: 0, x: 1, y: 1)
                }

                // Input Subtask Baru
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.cartoonLavender)

                    TextField("Tambah langkah subtask baru...", text: $newSubtaskText)
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .focused($isInputFocused)
                        .onSubmit {
                            addNewSubtask()
                        }

                    if !newSubtaskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button {
                            addNewSubtask()
                        } label: {
                            Text("Tambah")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.cartoonLavender)
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.1))
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.3), lineWidth: 1.0))
            }
        }
    }

    private func addNewSubtask() {
        let trimmed = newSubtaskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        HapticManager.shared.impact(style: .light)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            subtasks.append(SubtaskItem(title: trimmed))
            newSubtaskText = ""
        }
    }

    private func generateSmartSubtasks() {
        HapticManager.shared.impact(style: .medium)
        let suggestions = SmartTaskBreakdownService.shared.generateSuggestions(for: taskTitle, category: taskCategory)

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            for item in suggestions {
                // Hindari duplikasi jika sudah ada judul yang sama persis
                if !subtasks.contains(where: { $0.title.lowercased() == item.lowercased() }) {
                    subtasks.append(SubtaskItem(title: item))
                }
            }
        }
        HapticManager.shared.success()
    }
}
