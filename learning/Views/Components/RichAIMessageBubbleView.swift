//
//  RichAIMessageBubbleView.swift
//  learning
//
//  Created by macbook on 9/19/26.
//

import SwiftUI
import SwiftData

// MARK: - 🎨 Parsed Content Block Type
enum AIContentBlock: Identifiable {
    case paragraph(String)
    case header(String)
    case numberedItem(number: Int, text: String)
    case bulletItem(text: String)
    case infoBox(title: String, details: [String])

    var id: String {
        switch self {
        case .paragraph(let text): return "p_\(text.hashValue)"
        case .header(let text): return "h_\(text.hashValue)"
        case .numberedItem(let num, let text): return "num_\(num)_\(text.hashValue)"
        case .bulletItem(let text): return "bullet_\(text.hashValue)"
        case .infoBox(let title, let details): return "info_\(title)_\(details.count)"
        }
    }
}

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

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 10) {
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

                // 2. Body Konten (User Bubble / Assistant Rich Blocks)
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
                    renderAssistantRichBlocks()
                }

                // 3. Interactive Confirmation Card (Jika Ada Proposal Subtasks)
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
                                .padding(.vertical, 7)
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
                                .padding(.vertical, 9)
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
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
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

    // MARK: - 📝 Structured Assistant Content Parser & Renderer
    @ViewBuilder
    private func renderAssistantRichBlocks() -> some View {
        let blocks = parseContentToBlocks(message.content)

        VStack(alignment: .leading, spacing: 10) {
            ForEach(blocks) { block in
                switch block {
                case .header(let text):
                    Text(.init(text))
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.top, 2)

                case .numberedItem(let num, let text):
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(num)")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(.black)
                            .frame(width: 22, height: 22)
                            .background(Color.cartoonYellow)
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
                            .padding(.top, 1)

                        Text(.init(text))
                            .font(.system(size: 13.5, weight: .medium, design: .rounded))
                            .foregroundColor(.black)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.cartoonBg.opacity(0.85))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.18), lineWidth: 1.0))

                case .bulletItem(let text):
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.cartoonMint)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(Color.black, lineWidth: 0.8))
                            .padding(.top, 6)

                        Text(.init(text))
                            .font(.system(size: 13.5, weight: .medium, design: .rounded))
                            .foregroundColor(.black)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.cartoonBg.opacity(0.65))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.12), lineWidth: 1.0))

                case .paragraph(let text):
                    Text(.init(text))
                        .font(.system(size: 13.5, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                case .infoBox(let title, let details):
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                        ForEach(details, id: \.self) { d in
                            Text("• \(d)")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(10)
                    .background(Color.cartoonBg)
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius).stroke(Color.black, lineWidth: CartoonMetrics.borderWidth))
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }

    // MARK: - 🧩 Smart Block Parsing Algorithm
    private func parseContentToBlocks(_ rawContent: String) -> [AIContentBlock] {
        // 1. Normalisasi teks jika ada baris nomor yang tersambung (cth: "1. Teks 2. Teks")
        var normalized = rawContent
        normalized = normalized.replacingOccurrences(of: "([a-zA-Z0-9.,!?])\\s+([0-9]+\\.\\s+)", with: "$1\n$2", options: .regularExpression)
        normalized = normalized.replacingOccurrences(of: "([a-zA-Z0-9.,!?])\\s+([•*\\-🔹📌]\\s+)", with: "$1\n$2", options: .regularExpression)

        let rawLines = normalized.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var blocks: [AIContentBlock] = []

        for line in rawLines {
            // Check Header
            if line.hasPrefix("#") || (line.hasPrefix("**") && line.hasSuffix("**") && line.count < 60) {
                let cleanHeader = line.replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)
                blocks.append(.header(cleanHeader))
                continue
            }

            // Check Numbered List (1. , 2. , 3. ...)
            if let numMatch = line.range(of: "^[0-9]+[.)]\\s*", options: .regularExpression) {
                let numStr = String(line[numMatch]).filter { $0.isNumber }
                let num = Int(numStr) ?? (blocks.count + 1)
                let text = String(line[numMatch.upperBound...]).trimmingCharacters(in: .whitespaces)
                blocks.append(.numberedItem(number: num, text: text))
                continue
            }

            // Check Bullet List (•, -, *, 🔹, 📌, 🎯, 👟, 🔥, 😴)
            if let bulletMatch = line.range(of: "^([•*\\-🔹📌🎯👟🔥😴]|\\*\\s+)\\s*", options: .regularExpression) {
                let text = String(line[bulletMatch.upperBound...]).trimmingCharacters(in: .whitespaces)
                blocks.append(.bulletItem(text: text))
                continue
            }

            // Fallback: Paragraph
            blocks.append(.paragraph(line))
        }

        return blocks
    }
}
