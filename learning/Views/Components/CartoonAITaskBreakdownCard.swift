//
//  CartoonAITaskBreakdownCard.swift
//  learning
//
//  Created by macbook on 9/20/26.
//

import SwiftUI

struct CartoonAITaskBreakdownCard: View {
    let taskTitle: String
    let taskNotes: String
    var onAddSubtasks: ([String]) -> Void
    var onAutoTagApplied: ((TaskCategory, TaskPriority) -> Void)? = nil

    @State private var proposals: [AISubtaskProposal] = []
    @State private var isExpanded: Bool = false
    @State private var tagSuggestion: AITagSuggestion? = nil

    private var hasInputTitle: Bool {
        !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Action Buttons Header Row
            HStack(spacing: 8) {
                // Button 1: Pecah Subtask
                Button {
                    generateBreakdown()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 12, weight: .black))
                        Text(isExpanded ? "Tutup AI Breakdown" : "Pecah Tugas (AI)")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(hasInputTitle ? Color.cartoonLavender : Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.4))
                    .shadow(color: .black, radius: 0, x: hasInputTitle ? 1.5 : 0.5, y: hasInputTitle ? 1.5 : 0.5)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: hasInputTitle ? 1.0 : 0))
                .disabled(!hasInputTitle)

                // Button 2: Auto-Tag Kategori & Prioritas
                Button {
                    applyAutoTag()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("Auto-Tag")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(hasInputTitle ? Color.cartoonYellow : Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.4))
                    .shadow(color: .black, radius: 0, x: hasInputTitle ? 1.5 : 0.5, y: hasInputTitle ? 1.5 : 0.5)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: hasInputTitle ? 1.0 : 0))
                .disabled(!hasInputTitle)

                Spacer()
            }

            // Expanded Subtask Proposal List
            if isExpanded && !proposals.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("REKOMENDASI SUBTASK DARI AI")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)

                        Spacer()

                        let selectedCount = proposals.filter { $0.isSelected }.count
                        Text("\(selectedCount)/\(proposals.count) Dipilih")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                    }

                    ForEach($proposals) { $prop in
                        HStack(spacing: 8) {
                            Button {
                                HapticManager.shared.selection()
                                prop.isSelected.toggle()
                            } label: {
                                Image(systemName: prop.isSelected ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(prop.isSelected ? .black : .secondary)
                            }
                            .buttonStyle(.plain)

                            Text(prop.title)
                                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                                .foregroundColor(.black)
                                .lineLimit(2)

                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }

                    // Apply Button
                    Button {
                        confirmAndAddSubtasks()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 13, weight: .black))
                            Text("Tambahkan Subtask Terpilih")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.cartoonMint)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.4))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    .padding(.top, 4)
                }
                .padding(10)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.4))
                .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
    }

    private func generateBreakdown() {
        HapticManager.shared.impact(style: .medium)
        SoundManager.shared.playPop()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            if isExpanded {
                isExpanded = false
            } else {
                proposals = AITaskBreakdownService.shared.generateSubtasks(for: taskTitle, notes: taskNotes)
                isExpanded = true
            }
        }
    }

    private func applyAutoTag() {
        HapticManager.shared.success()
        SoundManager.shared.playSuccessChime()
        let suggestion = AITaskBreakdownService.shared.suggestTags(for: taskTitle, notes: taskNotes)
        onAutoTagApplied?(suggestion.category, suggestion.priority)
    }

    private func confirmAndAddSubtasks() {
        let selected = proposals.filter { $0.isSelected }.map { $0.title }
        guard !selected.isEmpty else { return }
        HapticManager.shared.success()
        SoundManager.shared.playSuccessChime()
        onAddSubtasks(selected)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            isExpanded = false
            proposals.removeAll()
        }
    }
}
