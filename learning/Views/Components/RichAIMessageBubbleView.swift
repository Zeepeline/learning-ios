//
//  RichAIMessageBubbleView.swift
//  learning
//
//  Created by macbook on 9/20/26.
//

import SwiftUI
import SwiftData
import WidgetKit

// MARK: - Markdown AST Block Types for AI Messages
enum AIMarkdownBlock: Identifiable, Equatable {
    var id: String {
        switch self {
        case .header(let level, let text): return "h-\(level)-\(text)"
        case .bullet(let text, let id): return "b-\(id)-\(text.prefix(20))"
        case .numbered(let num, let text): return "n-\(num)-\(text.prefix(20))"
        case .code(let code): return "c-\(code.prefix(20))"
        case .divider(let id): return "d-\(id)"
        case .paragraph(let text): return "p-\(text.prefix(20))"
        }
    }

    case header(level: Int, text: String)
    case bullet(text: String, id: String)
    case numbered(number: String, text: String)
    case code(code: String)
    case divider(id: String)
    case paragraph(text: String)
}

// MARK: - Parsed AI Action Item (Task vs Habit)
struct ParsedAIActionItem: Equatable {
    var title: String
    var notes: String
    var category: TaskCategory
    var priority: TaskPriority
    var isHabit: Bool
    var habitCategory: HabitCategory
    var habitFrequency: HabitFrequency
}

// MARK: - Block-Based Markdown Parser for AI Responses
struct AIMarkdownParser {
    static func parseBlocks(from rawText: String) -> [AIMarkdownBlock] {
        var blocks: [AIMarkdownBlock] = []
        var normalized = rawText
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        // Memisahkan bullet points inline yang digabung dalam satu baris panjang
        normalized = normalized.replacingOccurrences(of: " • ", with: "\n• ")
        normalized = normalized.replacingOccurrences(of: " - ", with: "\n- ")
        normalized = normalized.replacingOccurrences(of: " * ", with: "\n* ")

        let lines = normalized.components(separatedBy: "\n")
        var currentParagraphLines: [String] = []
        var isInCodeBlock = false
        var currentCodeLines: [String] = []

        func flushParagraph() {
            let joined = currentParagraphLines.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if !joined.isEmpty {
                blocks.append(.paragraph(text: joined))
            }
            currentParagraphLines.removeAll()
        }

        func flushCodeBlock() {
            let joined = currentCodeLines.joined(separator: "\n")
            blocks.append(.code(code: joined))
            currentCodeLines.removeAll()
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // 1. Code Block (```)
            if trimmed.hasPrefix("```") {
                if isInCodeBlock {
                    flushCodeBlock()
                    isInCodeBlock = false
                } else {
                    flushParagraph()
                    isInCodeBlock = true
                }
                continue
            }

            if isInCodeBlock {
                currentCodeLines.append(line)
                continue
            }

            // 2. Empty Line (Paragraph Separator)
            if trimmed.isEmpty {
                flushParagraph()
                continue
            }

            // 3. Horizontal Separator (---, ___, ***)
            if trimmed == "---" || trimmed == "___" || trimmed == "***" {
                flushParagraph()
                blocks.append(.divider(id: UUID().uuidString))
                continue
            }

            // 4. Headers (#, ##, ###, ####)
            if trimmed.hasPrefix("#### ") {
                flushParagraph()
                blocks.append(.header(level: 4, text: String(trimmed.dropFirst(5))))
                continue
            } else if trimmed.hasPrefix("### ") {
                flushParagraph()
                blocks.append(.header(level: 3, text: String(trimmed.dropFirst(4))))
                continue
            } else if trimmed.hasPrefix("## ") {
                flushParagraph()
                blocks.append(.header(level: 2, text: String(trimmed.dropFirst(3))))
                continue
            } else if trimmed.hasPrefix("# ") {
                flushParagraph()
                blocks.append(.header(level: 1, text: String(trimmed.dropFirst(2))))
                continue
            }

            // 5. Bullet Lists (•, -, *, +)
            if trimmed.hasPrefix("• ") || trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
                flushParagraph()
                let cleanText = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                blocks.append(.bullet(text: cleanText, id: UUID().uuidString))
                continue
            }

            // 6. Numbered Lists (1., 2., 3., 1), 2), dsb.)
            let numberedRegex = "^(\\d+)[\\.\\)]\\s+(.+)$"
            if let regex = try? NSRegularExpression(pattern: numberedRegex, options: []),
               let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count)) {
                flushParagraph()
                let numRange = Range(match.range(at: 1), in: trimmed)!
                let textRange = Range(match.range(at: 2), in: trimmed)!
                let numberStr = String(trimmed[numRange])
                let itemText = String(trimmed[textRange])
                blocks.append(.numbered(number: numberStr, text: itemText))
                continue
            }

            // 7. Regular paragraph line
            currentParagraphLines.append(trimmed)
        }

        flushParagraph()
        if isInCodeBlock {
            flushCodeBlock()
        }

        return blocks
    }

    // MARK: - Ekstraksi Judul & Catatan yang Cerdas
    static func extractTitleAndNotes(from rawText: String) -> (title: String, notes: String) {
        let raw = rawText.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Ambil seluruh bold matches
        var boldMatches: [String] = []
        if let regex = try? NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*") {
            let nsString = raw as NSString
            let matches = regex.matches(in: raw, range: NSRange(location: 0, length: nsString.length))
            for match in matches {
                if match.numberOfRanges > 1 {
                    let matchStr = nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !matchStr.isEmpty {
                        boldMatches.append(matchStr)
                    }
                }
            }
        }

        // 2. Bersihkan raw text dari format markdown
        var cleaned = raw
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "`", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Bersihkan bullet point prefix
        let bulletPrefixRegex = "^([•\\-\\+\\*]|\\d+[\\.\\)])\\s*"
        if let bRegex = try? NSRegularExpression(pattern: bulletPrefixRegex) {
            let range = NSRange(location: 0, length: cleaned.utf16.count)
            cleaned = bRegex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "")
        }

        // Deteksi label hari/tahap (misal "Hari 1", "Hari ke-2", "Step 1", "Langkah 1")
        var dayPrefix: String? = nil
        let dayRegex = "(?i)^(hari\\s*(ke-)?\\s*\\d+|tahap\\s*\\d+|step\\s*\\d+|langkah\\s*\\d+)"
        if let dRegex = try? NSRegularExpression(pattern: dayRegex) {
            let range = NSRange(location: 0, length: cleaned.utf16.count)
            if let match = dRegex.firstMatch(in: cleaned, options: [], range: range) {
                let matchStr = (cleaned as NSString).substring(with: match.range)
                dayPrefix = matchStr.capitalized
            }
        }

        // KASUS 1: Ada Bold Match yang bermakna (bukan sekadar "Hari 1")
        let nonDayBold = boldMatches.first { match in
            let lower = match.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let isJustDay = lower.range(of: "^(hari|tahap|step|langkah)\\s*(ke-)?\\s*\\d+$", options: .regularExpression) != nil
            return !isJustDay && lower.count >= 3
        }

        if let meaningfulBold = nonDayBold {
            var title = meaningfulBold
                .replacingOccurrences(of: ":", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // Jika ada prefix hari dan belum termasuk dalam title
            if let day = dayPrefix, !title.lowercased().contains("hari") {
                title = "\(day): \(title)"
            }

            // Ekstrak bagian sisa sebagai catatan deskripsi
            var notes = cleaned
            if let range = notes.range(of: meaningfulBold, options: .caseInsensitive) {
                notes = String(notes[range.upperBound...])
            }
            notes = notes.trimmingCharacters(in: CharacterSet(charactersIn: " :–—\t\n"))

            if notes.isEmpty || notes.count < 3 {
                notes = "Rekomendasi dari Asisten AI"
            }

            return (title, notes)
        }

        // KASUS 2: Parsing berdasarkan pemisah umum (": ", " - ", " – ")
        for separator in [": ", " - ", " – ", " — "] {
            if let sepRange = cleaned.range(of: separator) {
                let firstPart = String(cleaned[..<sepRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let secondPart = String(cleaned[sepRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)

                let isFirstPartJustDay = firstPart.lowercased().range(of: "^(hari|tahap|step|langkah)\\s*(ke-)?\\s*\\d+$", options: .regularExpression) != nil
                if isFirstPartJustDay {
                    for subSep in [" - ", " – ", " — ", ": "] {
                        if let subRange = secondPart.range(of: subSep) {
                            let subTitle = String(secondPart[..<subRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                            let subNotes = String(secondPart[subRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                            return ("\(firstPart.capitalized): \(subTitle)", subNotes.isEmpty ? "Rekomendasi dari Asisten AI" : subNotes)
                        }
                    }
                    return ("\(firstPart.capitalized): \(secondPart)", "Rekomendasi jadwal terstruktur dari AI Asisten")
                }

                if !firstPart.isEmpty && !secondPart.isEmpty {
                    return (firstPart, secondPart)
                }
            }
        }

        // KASUS 3: Fallback polos
        let trimmedClean = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmedClean.isEmpty ? "Tugas AI Baru" : trimmedClean, "Rekomendasi tindakan dari Asisten AI")
    }

    // MARK: - Ekstraksi Lengkap Item Rekomendasi (Task vs Habit dengan Kategori & Prioritas)
    static func extractActionItem(from rawText: String) -> ParsedAIActionItem {
        let (extractedTitle, extractedNotes) = extractTitleAndNotes(from: rawText)
        let lower = rawText.lowercased()

        // 1. Deteksi apakah ini Habit
        let isHabitText = lower.contains("habit") || lower.contains("kebiasaan") || lower.contains("rutinitas") || lower.contains("frekuensi:") || lower.contains("target:")
        
        // 2. Deteksi Prioritas Eksplisit
        var detectedPriority: TaskPriority = .normal
        if lower.contains("prioritas: tinggi") || lower.contains("prioritas tinggi") || lower.contains("urgent") || lower.contains("penting") {
            detectedPriority = .high
        } else if lower.contains("prioritas: rendah") || lower.contains("prioritas rendah") || lower.contains("santai") {
            detectedPriority = .low
        } else if lower.contains("prioritas: normal") || lower.contains("prioritas normal") {
            detectedPriority = .normal
        } else {
            // Gunakan AI Auto-Tag logic
            let tags = AITaskBreakdownService.shared.suggestTags(for: extractedTitle, notes: extractedNotes)
            detectedPriority = tags.priority
        }

        // 3. Deteksi TaskCategory Eksplisit
        var detectedCategory: TaskCategory = .general
        var foundExplicitCat = false
        for cat in TaskCategory.allCases {
            if lower.contains("kategori: \(cat.rawValue.lowercased())") || lower.contains("kategori \(cat.rawValue.lowercased())") {
                detectedCategory = cat
                foundExplicitCat = true
                break
            }
        }
        if !foundExplicitCat {
            let tags = AITaskBreakdownService.shared.suggestTags(for: extractedTitle, notes: extractedNotes)
            detectedCategory = tags.category
        }

        // 4. Deteksi HabitCategory & HabitFrequency
        var detectedHabitCat: HabitCategory = .productivity
        for hCat in HabitCategory.allCases {
            if lower.contains(hCat.rawValue.lowercased()) {
                detectedHabitCat = hCat
                break
            }
        }

        var detectedFrequency: HabitFrequency = .daily
        if lower.contains("hari kerja") || lower.contains("senin-jumat") {
            detectedFrequency = .weekdays
        } else if lower.contains("akhir pekan") || lower.contains("sabtu-minggu") {
            detectedFrequency = .weekends
        } else {
            detectedFrequency = .daily
        }

        // Bersihkan label metadata dari deskripsi notes agar notes bersih
        var cleanedNotes = extractedNotes
        let metadataPatterns = [
            "\\(kategori:[^\\)]+\\)",
            "\\(prioritas:[^\\)]+\\)",
            "\\(frekuensi:[^\\)]+\\)",
            "\\(kategori[^\\)]+\\)"
        ]
        for p in metadataPatterns {
            if let regex = try? NSRegularExpression(pattern: p, options: [.caseInsensitive]) {
                let range = NSRange(location: 0, length: cleanedNotes.utf16.count)
                cleanedNotes = regex.stringByReplacingMatches(in: cleanedNotes, options: [], range: range, withTemplate: "")
            }
        }
        cleanedNotes = cleanedNotes.trimmingCharacters(in: CharacterSet(charactersIn: " :-–—\t\n()"))
        if cleanedNotes.isEmpty {
            cleanedNotes = isHabitText ? "Kebiasaan positif yang direkomendasikan AI" : "Rekomendasi dari Asisten AI"
        }

        return ParsedAIActionItem(
            title: extractedTitle,
            notes: cleanedNotes,
            category: detectedCategory,
            priority: detectedPriority,
            isHabit: isHabitText,
            habitCategory: detectedHabitCat,
            habitFrequency: detectedFrequency
        )
    }
}

// MARK: - Rich AI Message Bubble View
struct RichAIMessageBubbleView: View {
    let message: AIMessage
    let onQuickActionTap: (String) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var copiedToClipboard: Bool = false
    @State private var savedTaskBlockIds: Set<String> = []

    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 40)
                userBubble
            } else {
                aiBubble
                Spacer(minLength: 20)
            }
        }
    }

    // MARK: - User Message Bubble
    private var userBubble: some View {
        Text(message.content)
            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
            .foregroundColor(.black)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.cartoonYellow)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black, lineWidth: 1.6)
            )
            .shadow(color: .black, radius: 0, x: 2, y: 2)
    }

    // MARK: - AI Assistant Response Bubble
    private var aiBubble: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Bar: AI Identity & Active MCP Tool Badge
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.cartoonCoral)
                        .frame(width: 22, height: 22)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.2))

                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.black)
                }

                Text("Asisten Produktivitas")
                    .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Spacer()

                if let tool = message.toolCall {
                    mcpToolBadge(tool)
                }
            }

            // Message Content
            aiMessageBodyContent

            // Proposal Card (Interactive Confirmation)
            if let proposal = message.proposal {
                proposalCard(proposal)
            }

            // Quick Action Buttons
            if let actions = message.quickActionButtons, !actions.isEmpty {
                VStack(spacing: 6) {
                    ForEach(actions) { act in
                        Button {
                            HapticManager.shared.selection()
                            onQuickActionTap(act.prompt)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: act.icon)
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.black)

                                Text(act.title)
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                                    .foregroundColor(.black)

                                Spacer()

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color(hex: act.colorHex))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.3))
                            .shadow(color: .black, radius: 0, x: 1, y: 1)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))
                    }
                }
                .padding(.top, 4)
            }

            // Footer: Timestamp & Copy Button
            HStack {
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.black.opacity(0.6))

                Spacer()

                if !message.content.isEmpty {
                    Button {
                        UIPasteboard.general.string = message.content
                        HapticManager.shared.impact(style: .light)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            copiedToClipboard = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation { copiedToClipboard = false }
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 10, weight: .bold))
                            if copiedToClipboard {
                                Text("Tersalin")
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                            }
                        }
                        .foregroundColor(.black.opacity(0.7))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.7))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black.opacity(0.3), lineWidth: 0.8))
                    }
                }
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black, lineWidth: 1.6)
        )
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }

    // MARK: - MCP Tool Execution Badge
    private func mcpToolBadge(_ tool: MCPToolInvocation) -> some View {
        HStack(spacing: 6) {
            Image(systemName: tool.icon)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.black)

            Text("MCP: \(tool.name)")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(.black)

            Spacer()

            Text(tool.argumentsSummary)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(Color.black.opacity(0.75))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(hex: tool.badgeColorHex))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
        .shadow(color: .black, radius: 0, x: 1, y: 1)
    }

    // MARK: - Block-Based Message Body Content
    private var aiMessageBodyContent: some View {
        let blocks = AIMarkdownParser.parseBlocks(from: message.content)
        let actionableBlocks = blocks.filter { isActionableBlock($0) }

        return VStack(alignment: .leading, spacing: 9) {
            ForEach(blocks) { block in
                switch block {
                case .header(let level, let text):
                    Text(parseInlineMarkdown(text))
                        .font(.system(size: level == 1 ? 16.5 : (level == 2 ? 15.5 : 14.5), weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.top, 4)

                case .paragraph(let text):
                    Text(parseInlineMarkdown(text))
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(Color.black)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                case .bullet(let text, let id):
                    HStack(alignment: .top, spacing: 8) {
                        // Pointy Cartoon Mint Bullet Dot
                        ZStack {
                            Circle()
                                .fill(Color.cartoonMint)
                                .frame(width: 14, height: 14)
                                .overlay(Circle().stroke(Color.black, lineWidth: 1.2))
                                .shadow(color: .black, radius: 0, x: 1, y: 1)

                            Circle()
                                .fill(Color.black)
                                .frame(width: 4.5, height: 4.5)
                        }
                        .padding(.top, 3)

                        Text(parseInlineMarkdown(text))
                            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.black)
                            .lineSpacing(2.5)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 4)

                        // Quick Add Action Button per Bullet Item (Task or Habit)
                        quickAddActionButton(rawText: text, blockId: id)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.cartoonBg.opacity(0.6))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.18), lineWidth: 1.0))

                case .numbered(let number, let text):
                    HStack(alignment: .top, spacing: 8) {
                        // Pointy Cartoon Number Badge
                        Text("\(number)")
                            .font(.system(size: 11.5, weight: .black, design: .rounded))
                            .foregroundColor(Color.black)
                            .frame(width: 20, height: 20)
                            .background(Color.cartoonYellow)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.black, lineWidth: 1.2))
                            .shadow(color: .black, radius: 0, x: 1, y: 1)
                            .padding(.top, 1)

                        Text(parseInlineMarkdown(text))
                            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.black)
                            .lineSpacing(2.5)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 4)

                        // Quick Add Action Button per Numbered Item (Task or Habit)
                        quickAddActionButton(rawText: text, blockId: "n-\(number)")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.cartoonBg.opacity(0.6))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.18), lineWidth: 1.0))

                case .code(let code):
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("KODE / CONTOH")
                                .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        Text(code)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(white: 0.95))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                    }

                case .divider:
                    Rectangle()
                        .fill(Color.black.opacity(0.15))
                        .frame(height: 1.5)
                        .padding(.vertical, 3)
                }
            }

            // Bulk Save All Recommendations Button (Muncul jika ada 2+ rekomendasi)
            if actionableBlocks.count >= 2 && !message.isStreaming {
                Button {
                    saveAllActionableBlocks(actionableBlocks)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .black))
                        Text(bulkButtonTitle(for: actionableBlocks))
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.cartoonYellow)
                    .cornerRadius(9)
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.black, lineWidth: 1.4))
                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))
                .padding(.top, 4)
            }
        }
    }

    private func bulkButtonTitle(for blocks: [AIMarkdownBlock]) -> String {
        var habitCount = 0
        var taskCount = 0
        for b in blocks {
            let text: String
            switch b {
            case .bullet(let t, _): text = t
            case .numbered(_, let t): text = t
            default: continue
            }
            let item = AIMarkdownParser.extractActionItem(from: text)
            if item.isHabit {
                habitCount += 1
            } else {
                taskCount += 1
            }
        }

        if habitCount > 0 && taskCount == 0 {
            return "Simpan Semua Rekomendasi ke Habit (+\(blocks.count))"
        } else if taskCount > 0 && habitCount == 0 {
            return "Simpan Semua Rekomendasi ke Tugas (+\(blocks.count))"
        } else {
            return "Simpan Semua Rekomendasi ke Agenda (+\(blocks.count))"
        }
    }

    // MARK: - Tombol Quick Add Action Per Item (Tugas vs Habit)
    private func quickAddActionButton(rawText: String, blockId: String) -> some View {
        let isSaved = savedTaskBlockIds.contains(blockId)
        let actionItem = AIMarkdownParser.extractActionItem(from: rawText)

        return Button {
            if !isSaved {
                saveActionItem(rawText: rawText, blockId: blockId)
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: isSaved ? "checkmark" : (actionItem.isHabit ? "flame.fill" : "plus"))
                    .font(.system(size: 9.5, weight: .black))
                Text(isSaved ? "Tersimpan" : (actionItem.isHabit ? "+ Habit" : "+ Tugas"))
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
            }
            .foregroundColor(.black)
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
            .background(isSaved ? Color.cartoonMint : (actionItem.isHabit ? Color.cartoonOrange.opacity(0.85) : Color.cartoonYellow.opacity(0.9)))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.black, lineWidth: 1.1)
            )
            .shadow(color: .black, radius: 0, x: 1, y: 1)
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.6))
        .disabled(isSaved)
    }

    private func isActionableBlock(_ block: AIMarkdownBlock) -> Bool {
        switch block {
        case .bullet(let text, _), .numbered(_, let text):
            let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned.count >= 3
        default:
            return false
        }
    }

    // Simpan 1 Rekomendasi ke SwiftData Lokal (Otomatis Deteksi Task vs Habit)
    private func saveActionItem(rawText: String, blockId: String) {
        HapticManager.shared.success()
        SoundManager.shared.playSuccessChime()

        let actionItem = AIMarkdownParser.extractActionItem(from: rawText)

        if actionItem.isHabit {
            let newHabit = Habit(
                title: actionItem.title,
                icon: actionItem.habitCategory.defaultIcon,
                colorHex: actionItem.habitCategory.defaultColorHex,
                category: actionItem.habitCategory.rawValue,
                targetFrequency: actionItem.habitFrequency.rawValue
            )
            modelContext.insert(newHabit)
        } else {
            let newItem = Item(
                title: actionItem.title,
                notes: actionItem.notes,
                timestamp: Date().addingTimeInterval(3600),
                isCompleted: false,
                completedAt: nil,
                priority: actionItem.priority.rawValue,
                category: actionItem.category.rawValue,
                isRecurring: false,
                recurrenceRule: "Sekali Saja",
                customSoundName: "cartoon_bell.caf",
                subtasks: [],
                imageAttachmentData: nil
            )
            modelContext.insert(newItem)
        }

        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            savedTaskBlockIds.insert(blockId)
        }
    }

    // Simpan Semua Rekomendasi ke SwiftData Lokal
    private func saveAllActionableBlocks(_ blocks: [AIMarkdownBlock]) {
        HapticManager.shared.success()
        SoundManager.shared.playSuccessChime()

        var offsetSeconds: TimeInterval = 3600

        for block in blocks {
            let blockId = block.id
            guard !savedTaskBlockIds.contains(blockId) else { continue }

            let rawText: String
            switch block {
            case .bullet(let text, _): rawText = text
            case .numbered(_, let text): rawText = text
            default: continue
            }

            let actionItem = AIMarkdownParser.extractActionItem(from: rawText)

            if actionItem.isHabit {
                let newHabit = Habit(
                    title: actionItem.title,
                    icon: actionItem.habitCategory.defaultIcon,
                    colorHex: actionItem.habitCategory.defaultColorHex,
                    category: actionItem.habitCategory.rawValue,
                    targetFrequency: actionItem.habitFrequency.rawValue
                )
                modelContext.insert(newHabit)
            } else {
                let newItem = Item(
                    title: actionItem.title,
                    notes: actionItem.notes,
                    timestamp: Date().addingTimeInterval(offsetSeconds),
                    isCompleted: false,
                    completedAt: nil,
                    priority: actionItem.priority.rawValue,
                    category: actionItem.category.rawValue,
                    isRecurring: false,
                    recurrenceRule: "Sekali Saja",
                    customSoundName: "cartoon_bell.caf",
                    subtasks: [],
                    imageAttachmentData: nil
                )
                modelContext.insert(newItem)
                offsetSeconds += 1800 // Beri jeda 30 menit per tugas berikutnya
            }

            savedTaskBlockIds.insert(blockId)
        }

        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        let clean = formattedCleanMarkdown(text)
        if let attributed = try? AttributedString(markdown: clean, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return attributed
        }
        return AttributedString(clean)
    }

    // Membersihkan format markdown agar tidak ada karakter rusak atau baris kosong bertumpuk
    private func formattedCleanMarkdown(_ text: String) -> String {
        var clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        clean = clean.replacingOccurrences(of: "\r\n", with: "\n")
        clean = clean.replacingOccurrences(of: "\r", with: "\n")
        return clean
    }

    // MARK: - Proposal Card (Interactive Decision)
    private func proposalCard(_ proposal: AIActionProposal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.black)

                Text(proposal.title)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Spacer()

                Text(proposal.category)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.cartoonYellow)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1))
            }

            Text(proposal.subtitle)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.black.opacity(0.8))

            if !proposal.subtasks.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(proposal.subtasks, id: \.self) { sub in
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color.cartoonCoral)
                            Text(sub)
                                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                                .foregroundColor(.black)
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color(white: 0.95))
                .cornerRadius(8)
            }
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.2))
        .shadow(color: .black, radius: 0, x: 1, y: 1)
    }
}
