//
//  RichAIMessageBubbleView.swift
//  learning
//
//  Created by macbook on 9/19/26.
//

import SwiftUI
import SwiftData

// MARK: - 💬 Cartoon Chat Bubble Shape
struct CartoonChatBubbleShape: Shape {
    let isUser: Bool
    var cornerRadius: CGFloat = 14
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

// MARK: - 💬 Rich AI Message Bubble (Teks Tajam, Kontras Tinggi & Anti-Blur)
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
                // MARK: - 👤 Bubble Pengguna (Kanan, Biru Cartoon Tajam)
                HStack {
                    Spacer(minLength: 32)

                    Text(message.content)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .lineSpacing(3)
                        .textSelection(.enabled)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.cartoonBlue)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.black, lineWidth: 1.8)
                        )
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                }
            } else {
                // MARK: - 🤖 Bubble AI Asisten (Kiri, Putih Solid, Teks Super Jelas)
                VStack(alignment: .leading, spacing: 10) {
                    // 1. Tool Call Badge (Jika AI Mengeksekusi Alat MCP)
                    if let tool = message.toolCall {
                        HStack(spacing: 6) {
                            Image(systemName: tool.icon)
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.black)

                            Text("MCP Tool:")
                                .font(.system(size: 10.5, weight: .black, design: .monospaced))
                                .foregroundColor(.black)

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
                        .background(Color(hex: tool.badgeColorHex).opacity(0.45))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                    }

                    // 2. Body Teks AI Asisten (Native Markdown Renderer dengan Font Jernih)
                    aiMessageBodyContent
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.black, lineWidth: 1.8)
                        )
                        .shadow(color: .black, radius: 0, x: 2, y: 2)

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

    // MARK: - 📝 AI Message Body Content (Native Sharp Markdown)
    private var aiMessageBodyContent: some View {
        Text(LocalizedStringKey(formattedCleanMarkdown(message.content)))
            .font(.system(size: 14.5, weight: .semibold, design: .default))
            .foregroundColor(.black)
            .lineSpacing(4.5)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }

    // Membersihkan format markdown agar tidak ada karakter rusak atau baris renggang berlebihan
    private func formattedCleanMarkdown(_ text: String) -> String {
        var clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        clean = clean.replacingOccurrences(of: "\r\n", with: "\n")
        clean = clean.replacingOccurrences(of: "\r", with: "\n")
        return clean
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
}
