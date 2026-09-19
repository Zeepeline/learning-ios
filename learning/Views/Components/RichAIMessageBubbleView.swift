//
//  RichAIMessageBubbleView.swift
//  learning
//
//  Created by macbook on 9/19/26.
//

import SwiftUI
import SwiftData

// MARK: - 🎨 Rich AI Message Bubble with List Formatting & Action Cards
struct RichAIMessageBubbleView: View {
    let message: MCPAIChatMessage
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var assistantService = MCPAIAssistantService.shared

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if message.role == .assistant {
                // AI Avatar Icon
                ZStack {
                    Circle()
                        .fill(Color.cartoonMint)
                        .frame(width: 34, height: 34)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)

                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                }
            } else {
                Spacer(minLength: 40)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                // 1. Tool Call Badge (Jika AI Mengeksekusi Alat MCP)
                if let tool = message.toolCall {
                    HStack(spacing: 6) {
                        Image(systemName: tool.icon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)

                        Text("MCP Tool:")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.secondary)

                        Text(tool.name)
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(.black)

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.cartoonMint)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: tool.badgeColorHex).opacity(0.35))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                }

                // 2. Body Konten (Teks / Rich List / Subtask Cards)
                if message.role == .user {
                    Text(message.content)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.cartoonBlue)
                        .cornerRadius(CartoonMetrics.cardCornerRadius)
                        .overlay(RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius).stroke(Color.black, lineWidth: CartoonMetrics.borderWidth))
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                } else {
                    renderAssistantRichContent()
                }

                // 3. Interactive Confirmation Card (Jika Ada Proposal Jadwal)
                if let proposal = message.proposal {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "sparkles.rectangle.stack.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.black)
                            Text("Daftar Subtasks Siap Dijadwalkan:")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                        }

                        // List Subtasks Cards
                        VStack(spacing: 6) {
                            ForEach(Array(proposal.subtasks.enumerated()), id: \.offset) { index, task in
                                HStack(spacing: 8) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 11, weight: .black, design: .rounded))
                                        .foregroundColor(.black)
                                        .frame(width: 22, height: 22)
                                        .background(Color.cartoonYellow)
                                        .cornerRadius(6)
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))

                                    Text(task)
                                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                        .foregroundColor(.black)

                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.0))
                            }
                        }

                        // Action Buttons: 1-Tap Schedule & Pomodoro
                        HStack(spacing: 8) {
                            Button {
                                HapticManager.shared.impact(style: .medium)
                                Task {
                                    await assistantService.confirmProposalDirectly(modelContext: modelContext)
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("⚡ Jadwalkan Semua")
                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.cartoonMint)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                                .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                            }
                            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                            Button {
                                HapticManager.shared.impact(style: .light)
                                PomodoroManager.shared.selectPreset(.quickFocus)
                                PomodoroManager.shared.startTimer()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "timer")
                                        .font(.system(size: 11, weight: .bold))
                                    Text("Fokus 25m")
                                        .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.cartoonCoral)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                                .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                            }
                            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                        }
                    }
                    .padding(12)
                    .background(Color.cartoonBg)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.4))
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                }
            }

            if message.role == .user {
                // User Avatar Icon
                ZStack {
                    Circle()
                        .fill(Color.cartoonCoral)
                        .frame(width: 34, height: 34)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)

                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            } else {
                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - 📝 Structured Assistant Content Parser
    @ViewBuilder
    private func renderAssistantRichContent() -> some View {
        let lines = message.content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let isListHeavy = lines.filter { isListItem($0) }.count >= 2

        VStack(alignment: .leading, spacing: 8) {
            if isListHeavy {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    if isListItem(line) {
                        let cleanText = cleanListText(line)
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color.cartoonMint)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.black, lineWidth: 0.8))
                                .padding(.top, 5)

                            Text(.init(cleanText))
                                .font(.system(size: 13.5, weight: .medium, design: .rounded))
                                .foregroundColor(.black)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.cartoonBg.opacity(0.6))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.15), lineWidth: 1))
                    } else {
                        Text(.init(line))
                            .font(.system(size: 14, weight: line.hasPrefix("#") || line.hasPrefix("**") ? .heavy : .medium, design: .rounded))
                            .foregroundColor(.black)
                            .lineSpacing(3)
                    }
                }
            } else {
                Text(.init(message.content))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.black)
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius).stroke(Color.black, lineWidth: CartoonMetrics.borderWidth))
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }

    private func isListItem(_ line: String) -> Bool {
        return line.hasPrefix("1.") || line.hasPrefix("2.") || line.hasPrefix("3.") || line.hasPrefix("4.") ||
               line.hasPrefix("5.") || line.hasPrefix("6.") || line.hasPrefix("-") || line.hasPrefix("•") ||
               line.hasPrefix("*") || line.hasPrefix("🔹") || line.hasPrefix("📌")
    }

    private func cleanListText(_ line: String) -> String {
        return line.replacingOccurrences(of: "^([0-9]+[.\\s-]+|[•*\\-🔹📌]+\\s*)", with: "", options: .regularExpression)
    }
}
