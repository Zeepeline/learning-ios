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

// MARK: - 🎨 Rich AI Message Bubble (Lebar Penuh, Bersih Tanpa Avatar)
struct RichAIMessageBubbleView: View {
    let message: MCPAIChatMessage
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var assistantService = MCPAIAssistantService.shared

    var body: some View {
        Group {
            if message.role == .user {
                // MARK: - Bubble Pengguna (Kanan, Lebar Proporsional, Tanpa Avatar)
                HStack {
                    Spacer(minLength: 28)

                    Text(message.content)
                        .font(.system(size: 14.5, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .lineSpacing(3)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.cartoonBlue)
                        .cornerRadius(CartoonMetrics.cardCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                        )
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                }
            } else {
                // MARK: - Bubble AI Asisten (Lebar Penuh Maksimal, Tanpa Avatar)
                VStack(alignment: .leading, spacing: 8) {
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
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: tool.badgeColorHex).opacity(0.35))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                    }

                    // 2. Body Konten Assistant (Lebar Penuh)
                    renderAssistantRichBlocks()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
                        .font(.system(size: 14.5, weight: .heavy, design: .rounded))
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

                        Spacer(minLength: 0)
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

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.cartoonBg.opacity(0.65))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.12), lineWidth: 1.0))

                case .paragraph(let text):
                    Text(.init(text))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                case .infoBox(let title, let details):
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                        ForEach(details, id: \.self) { d in
                            Text("• \(d)")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.cartoonBg)
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }

    // MARK: - 🧩 Smart Block Parsing Algorithm
    private func parseContentToBlocks(_ rawContent: String) -> [AIContentBlock] {
        var normalized = rawContent
        normalized = normalized.replacingOccurrences(of: "([a-zA-Z0-9.,!?])\\s+([0-9]+\\.\\s+)", with: "$1\n$2", options: .regularExpression)
        normalized = normalized.replacingOccurrences(of: "([a-zA-Z0-9.,!?])\\s+([•*\\-🔹📌]\\s+)", with: "$1\n$2", options: .regularExpression)

        let rawLines = normalized.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var blocks: [AIContentBlock] = []

        for line in rawLines {
            if let match = line.range(of: #"^\d+[\.\)]\s*"#, options: .regularExpression) {
                let numPrefix = line[match]
                let numStr = numPrefix.filter { $0.isNumber }
                let itemNum = Int(numStr) ?? (blocks.count + 1)
                let itemBody = String(line[match.upperBound...]).trimmingCharacters(in: .whitespaces)
                blocks.append(.numberedItem(number: itemNum, text: itemBody))
            } else if line.hasPrefix("• ") || line.hasPrefix("- ") || line.hasPrefix("* ") {
                let body = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                blocks.append(.bulletItem(text: body))
            } else if line.hasPrefix("### ") || line.hasPrefix("## ") || line.hasPrefix("# ") {
                let heading = line.replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)
                blocks.append(.header(heading))
            } else if line.hasPrefix("**") && line.hasSuffix("**") && line.count < 60 {
                let cleanHeader = line.replacingOccurrences(of: "**", with: "")
                blocks.append(.header(cleanHeader))
            } else {
                blocks.append(.paragraph(line))
            }
        }

        return blocks.isEmpty ? [.paragraph(rawContent)] : blocks
    }
}
