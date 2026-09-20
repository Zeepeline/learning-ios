//
//  RichAIMessageBubbleView.swift
//  learning
//
//  Created by macbook on 9/19/26.
//

import SwiftUI
import SwiftData

// MARK: - 💬 Cartoon Chat Bubble Shape (Sudut Lancip di Bagian Bawah)
struct CartoonChatBubbleShape: Shape {
    let isUser: Bool
    var cornerRadius: CGFloat = 16
    var pointedRadius: CGFloat = 3

    func path(in rect: CGRect) -> Path {
        let tl: CGFloat = cornerRadius
        let tr: CGFloat = cornerRadius
        let bl: CGFloat = isUser ? cornerRadius : pointedRadius
        let br: CGFloat = isUser ? pointedRadius : cornerRadius

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))

        // Top edge & Top-right
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr),
            radius: tr,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )

        // Right edge & Bottom-right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addArc(
            center: CGPoint(x: rect.maxX - br, y: rect.maxY - br),
            radius: br,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        // Bottom edge & Bottom-left
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl),
            radius: bl,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        // Left edge & Top-left
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addArc(
            center: CGPoint(x: rect.minX + tl, y: rect.minY + tl),
            radius: tl,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        path.closeSubpath()
        return path
    }
}

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

// MARK: - 💬 Rich AI Message Bubble (Dengan Sudut Lancip & Quick Action Buttons)
struct RichAIMessageBubbleView: View {
    let message: AIMessage
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var assistantService = MCPAIAssistantService.shared
    private var pomodoroManager = PomodoroManager.shared
    private var screenTimeManager = ScreenTimeManager.shared

    @State private var checkedSubtaskIndices: Set<Int> = []
    @State private var didScheduleReminder: Bool = false
    @State private var reminderSuccessMessage: String? = nil

    var body: some View {
        Group {
            if message.isUser {
                // MARK: - 👤 Bubble Pengguna (Kanan, Lancip di Sudut Kanan Bawah)
                HStack {
                    Spacer(minLength: 28)

                    Text(message.content)
                        .font(.system(size: 14.5, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .lineSpacing(3)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            CartoonChatBubbleShape(isUser: true)
                                .fill(Color.cartoonBlue)
                        )
                        .overlay(
                            CartoonChatBubbleShape(isUser: true)
                                .stroke(Color.black, lineWidth: 1.8)
                        )
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                }
            } else {
                // MARK: - 🤖 Bubble AI Asisten (Kiri, Lancip di Sudut Kiri Bawah, Lebar Penuh)
                VStack(alignment: .leading, spacing: 10) {
                    // 1. Tool Call Badge (Jika AI Mengeksekusi Alat MCP)
                    if let tool = message.toolCall {
                        HStack(spacing: 6) {
                            Image(systemName: tool.icon)
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.black)

                            Text("MCP Tool:")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundColor(Color.black.opacity(0.85))

                            Text(tool.name)
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundColor(.black)

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(Color.cartoonMint)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: tool.badgeColorHex).opacity(0.4))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                    }

                    // 2. Body Konten Assistant (Lebar Penuh & Teks Tajam)
                    renderAssistantRichBlocks()

                    // 3. Kartu Interactive Proposal (Jika AI Menawarkan Rancangan Rencana)
                    if let proposal = message.proposal {
                        interactiveProposalCard(proposal: proposal)
                    }

                    // 4. ⚡ In-Chat Quick Action Buttons (Pintasan Langsung)
                    inChatActionButtons
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - ⚡ In-Chat Quick Action Buttons
    @ViewBuilder
    private var inChatActionButtons: some View {
        let isTaskCreatedMessage = message.toolCall?.name == "create_activity" || message.content.contains("Berhasil Ditambahkan")
        let isFocusMessage = message.content.localizedCaseInsensitiveContains("pomodoro") || message.content.localizedCaseInsensitiveContains("fokus")

        if isTaskCreatedMessage || isFocusMessage {
            VStack(alignment: .leading, spacing: 8) {
                Divider()
                    .overlay(Color.black.opacity(0.3))

                Text("AKSI CEPAT:")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.black.opacity(0.85))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // ⏱️ Tombol Mulai Pomodoro Langsung
                        Button {
                            HapticManager.shared.impact(style: .medium)
                            SoundManager.shared.playPop()
                            pomodoroManager.selectPreset(.quickFocus)
                            pomodoroManager.startTimer()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: pomodoroManager.isRunning ? "timer" : "play.fill")
                                    .font(.system(size: 11, weight: .black))
                                Text(pomodoroManager.isRunning ? "Pomodoro Aktif" : "Mulai Pomodoro (25m)")
                                    .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(pomodoroManager.isRunning ? Color.cartoonMint : Color.cartoonCoral)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.4))
                            .shadow(color: .black, radius: 0, x: 1, y: 1)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                        // 🔔 Pasang Pengingat 1 Jam Lagi
                        Button {
                            HapticManager.shared.success()
                            SoundManager.shared.playSuccessChime()
                            scheduleQuickReminder()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: didScheduleReminder ? "bell.fill" : "bell.badge")
                                    .font(.system(size: 11, weight: .black))
                                Text(didScheduleReminder ? "Pengingat Disetel" : "Ingatkan 1 Jam Lagi")
                                    .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(didScheduleReminder ? Color.cartoonMint : Color.cartoonYellow)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.4))
                            .shadow(color: .black, radius: 0, x: 1, y: 1)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                        // 🛡️ Kunci Distraksi (Screen Time Shield)
                        Button {
                            HapticManager.shared.warning()
                            if screenTimeManager.isShieldActive {
                                screenTimeManager.disableAppShield()
                            } else {
                                screenTimeManager.enableAppShield()
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: screenTimeManager.isShieldActive ? "shield.fill" : "shield")
                                    .font(.system(size: 11, weight: .black))
                                Text(screenTimeManager.isShieldActive ? "Shield Aktif" : "Kunci Distraksi")
                                    .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.cartoonLavender)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.4))
                            .shadow(color: .black, radius: 0, x: 1, y: 1)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    }
                }

                if let reminderSuccess = reminderSuccessMessage {
                    Text(reminderSuccess)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.2))
                        .transition(.opacity)
                }
            }
        }
    }

    // MARK: - 📋 Interactive Proposal Card
    private func interactiveProposalCard(proposal: AIActionProposal) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.black)

                Text("Rancangan Tugas Siap Disimpan")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Spacer()

                Text(proposal.priority)
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.cartoonYellow)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(proposal.subtasks.enumerated()), id: \.offset) { idx, sub in
                    Button {
                        HapticManager.shared.selection()
                        if checkedSubtaskIndices.contains(idx) {
                            checkedSubtaskIndices.remove(idx)
                        } else {
                            checkedSubtaskIndices.insert(idx)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: checkedSubtaskIndices.contains(idx) ? "checkmark.square.fill" : "square")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.black)

                            Text(sub)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                                .strikethrough(checkedSubtaskIndices.contains(idx), color: Color.black.opacity(0.7))

                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.0))

            Button {
                HapticManager.shared.success()
                let subtaskItems = proposal.subtasks.map { SubtaskItem(title: $0, isCompleted: false) }
                let newItem = Item(
                    title: proposal.title,
                    notes: proposal.subtitle,
                    timestamp: proposal.targetDate,
                    isCompleted: false,
                    completedAt: nil,
                    priority: proposal.priority,
                    category: proposal.category,
                    isRecurring: false,
                    recurrenceRule: "Sekali Saja",
                    customSoundName: nil,
                    subtasks: subtaskItems,
                    imageAttachmentData: nil
                )
                modelContext.insert(newItem)
                try? modelContext.save()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .black))
                    Text("Setujui & Simpan ke Daftar Tugas")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.cartoonMint)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.5))
                .shadow(color: .black, radius: 0, x: 2, y: 2)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
        }
        .padding(12)
        .background(Color.cartoonPink.opacity(0.45))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.5))
    }

    // MARK: - 🔔 Helper Pasang Notifikasi Cepat
    private func scheduleQuickReminder() {
        didScheduleReminder = true
        reminderSuccessMessage = "✅ Pengingat dijadwalkan dalam 1 jam ke depan!"
        Task {
            try? await NotificationManager.shared.sendTestNotification(seconds: 3600)
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                withAnimation {
                    reminderSuccessMessage = nil
                }
            }
        }
    }

    // MARK: - 📝 Structured Assistant Content Parser & Renderer (Teks Tajam & Bold)
    @ViewBuilder
    private func renderAssistantRichBlocks() -> some View {
        let blocks = parseContentToBlocks(message.content)

        VStack(alignment: .leading, spacing: 10) {
            ForEach(blocks) { block in
                switch block {
                case .header(let text):
                    Text(.init(text))
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.top, 3)

                case .numberedItem(let num, let text):
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(num)")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(.black)
                            .frame(width: 22, height: 22)
                            .background(Color.cartoonYellow)
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.2))
                            .padding(.top, 1)

                        Text(.init(text))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.0))

                case .bulletItem(let text):
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.cartoonMint)
                            .frame(width: 9, height: 9)
                            .overlay(Circle().stroke(Color.black, lineWidth: 1.0))
                            .padding(.top, 6)

                        Text(.init(text))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.0))

                case .paragraph(let text):
                    Text(.init(text))
                        .font(.system(size: 14.5, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                case .infoBox(let title, let details):
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                        ForEach(details, id: \.self) { d in
                            Text("• \(d)")
                                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.black.opacity(0.85))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(red: 0.94, green: 0.94, blue: 0.96))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.0))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            CartoonChatBubbleShape(isUser: false)
                .fill(Color.white)
        )
        .overlay(
            CartoonChatBubbleShape(isUser: false)
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
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("### ") || trimmed.hasPrefix("## ") || trimmed.hasPrefix("# ") {
                let text = trimmed.replacingOccurrences(of: "^#{1,3}\\s*", with: "", options: .regularExpression)
                blocks.append(.header(text))
            } else if let match = trimmed.range(of: "^([0-9]+)[.)]\\s+", options: .regularExpression) {
                let numStr = String(trimmed[match]).trimmingCharacters(in: CharacterSet(charactersIn: "0123456789").inverted)
                let num = Int(numStr) ?? 1
                let text = String(trimmed[match.upperBound...])
                blocks.append(.numberedItem(number: num, text: text))
            } else if trimmed.hasPrefix("• ") || trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("🔹 ") || trimmed.hasPrefix("📌 ") {
                let text = trimmed.replacingOccurrences(of: "^[•\\-*🔹📌]\\s*", with: "", options: .regularExpression)
                blocks.append(.bulletItem(text: text))
            } else {
                blocks.append(.paragraph(trimmed))
            }
        }

        return blocks
    }
}
