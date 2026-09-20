//
//  AIAssistantSheetView.swift
//  learning
//
//  Created by macbook on 9/19/26.
//

import SwiftUI
import SwiftData

struct AIAssistantSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var assistantService = MCPAIAssistantService.shared
    @StateObject private var geminiBridge = GeminiBackgroundBridgeManager.shared
    @StateObject private var voiceManager = VoiceInputManager.shared

    @AppStorage("aiProviderType") private var selectedProviderRaw: String = AIProviderType.googleAccount.rawValue
    @AppStorage("geminiApiKey") private var geminiApiKey: String = ""
    @AppStorage("ninerouterApiKey") private var ninerouterApiKey: String = ""
    @AppStorage("ninerouterBaseUrl") private var ninerouterBaseUrl: String = "https://api.ninerouter.com/v1"
    @AppStorage("ninerouterModel") private var ninerouterModel: String = "deepseek/deepseek-chat"

    @State private var inputText: String = ""
    @State private var isShowingSettings: Bool = false
    @State private var tempProvider: AIProviderType = .googleAccount
    @State private var tempGeminiApiKey: String = ""
    @State private var tempNinerouterApiKey: String = ""
    @State private var tempNinerouterBaseUrl: String = ""
    @State private var tempNinerouterModel: String = ""
    @FocusState private var isInputFocused: Bool

    private var currentProvider: AIProviderType {
        AIProviderType(rawValue: selectedProviderRaw) ?? .googleAccount
    }

    // Saran Prompt Cepat MCP Multi-Feature (Termasuk Daily Coach & Natural Time Parsing)
    private let quickPrompts: [(title: String, icon: String, color: Color)] = [
        ("🌅 Susun rencana hari ini (Morning Briefing)", "sun.max.fill", Color.cartoonYellow),
        ("🌙 Evaluasi hari ini (Evening Review)", "moon.stars.fill", Color.cartoonLavender),
        ("⚡ Tambah tugas Coding besok jam 8 malam", "bolt.fill", Color.cartoonMint),
        ("⏱️ Mulai fokus 25 menit", "timer", Color.cartoonCoral),
        ("🏃‍♂️ Cek data kesehatan & langkah", "heart.fill", Color.cartoonPink),
        ("📊 Rangkum status aktivitas hari ini", "chart.bar.fill", Color.cartoonMint),
        ("🔥 Ceklis habit hari ini", "flame.fill", Color.cartoonOrange),
        ("🛡️ Kunci aplikasi pengganggu", "shield.lefthalf.filled", Color.cartoonBlue),
        ("🧹 Bersihkan tugas selesai", "trash.slash.fill", Color.cartoonYellow)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cartoonBg
                    .ignoresSafeArea()

                // MARK: - 👁️ Invisible Background Engine
                InvisibleGeminiWebEngineView()
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
                    .allowsHitTesting(false)

                VStack(spacing: 0) {
                    // MARK: - 💬 Chat Messages ScrollView (Lebar Maksimal Bersih)
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: HIGSpacing.md) {
                                ForEach(assistantService.messages) { msg in
                                    RichAIMessageBubbleView(message: msg)
                                        .id(msg.id)
                                }

                                if assistantService.isProcessing {
                                    typingIndicatorView
                                        .id("typingIndicator")
                                }
                            }
                            .padding(.horizontal, HIGSpacing.md)
                            .padding(.vertical, HIGSpacing.md)
                        }
                        .onChange(of: assistantService.messages.count) {
                            smoothScrollToBottom(proxy: proxy)
                        }
                        .onChange(of: assistantService.isProcessing) {
                            if assistantService.isProcessing {
                                smoothScrollToIndicator(proxy: proxy)
                            }
                        }
                    }

                    // Audio Recording Live Bar Indicator
                    if voiceManager.isRecording {
                        recordingAudioBanner
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if let error = voiceManager.errorMessage {
                        voiceErrorBanner(error: error)
                            .transition(.opacity)
                    }

                    // MARK: - ⚡ Quick Prompt Chips
                    quickPromptChipsSection

                    // MARK: - ✍️ Bottom Message Input Bar (Native In-App with Mic)
                    bottomInputBar
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: voiceManager.isRecording)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: voiceManager.errorMessage)
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                voiceManager.stopRecording()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticManager.shared.impact(style: .light)
                        voiceManager.stopRecording()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.black)
                            .frame(width: 32, height: 32)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.5))
                            .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                }

                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("AI Assistant")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)

                        HStack(spacing: 4) {
                            Circle()
                                .fill(voiceManager.isRecording ? Color.cartoonCoral : Color.cartoonMint)
                                .frame(width: 6, height: 6)
                            Text(voiceManager.isRecording ? "Mendengarkan Suara..." : "Asisten Aktif")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(voiceManager.isRecording ? Color.cartoonCoral : .secondary)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        // Tombol Clear Chat
                        Button {
                            HapticManager.shared.selection()
                            assistantService.clearMessages()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 32, height: 32)
                                .background(Color.cartoonPink)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.5))
                                .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                        // Tombol Pengaturan AI Provider & API Key
                        Button {
                            HapticManager.shared.impact(style: .light)
                            tempProvider = currentProvider
                            tempGeminiApiKey = geminiApiKey
                            tempNinerouterApiKey = ninerouterApiKey
                            tempNinerouterBaseUrl = ninerouterBaseUrl
                            tempNinerouterModel = ninerouterModel
                            isShowingSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 32, height: 32)
                                .background(Color.cartoonYellow)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.5))
                                .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    }
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                aiSettingsSheet
            }
        }
    }

    // MARK: - 🌊 Audio Wave Indicator Banner
    private var recordingAudioBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.black)
                .symbolEffect(.variableColor.iterative.reversing, options: .repeating)

            Text("Mendengarkan suara Anda...")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(.black)

            Spacer()

            // Dynamic Animated Wave Bars based on microphone level
            HStack(spacing: 3) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black)
                        .frame(
                            width: 3.5,
                            height: max(6, CGFloat(10 + sin(Double(index) + Double(voiceManager.audioLevel * 10)) * 12 * voiceManager.audioLevel))
                        )
                }
            }

            Button {
                voiceManager.stopRecording()
            } label: {
                Text("Selesai")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black)
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.cartoonCoral)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.6))
        .shadow(color: .black, radius: 0, x: 2, y: 2)
        .padding(.horizontal, HIGSpacing.md)
        .padding(.top, 4)
    }

    // MARK: - ⚠️ Voice Error Banner
    private func voiceErrorBanner(error: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.black)

            Text(error)
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .lineLimit(2)

            Spacer()

            Button {
                voiceManager.errorMessage = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.cartoonYellow)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.4))
        .padding(.horizontal, HIGSpacing.md)
        .padding(.top, 4)
    }

    // MARK: - 🌊 Smooth Scrolling Helpers
    private func smoothScrollToBottom(proxy: ScrollViewProxy) {
        guard let lastId = assistantService.messages.last?.id else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 80_000_000)
            withAnimation(.easeInOut(duration: 0.45)) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }

    private func smoothScrollToIndicator(proxy: ScrollViewProxy) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 80_000_000)
            withAnimation(.easeInOut(duration: 0.45)) {
                proxy.scrollTo("typingIndicator", anchor: .bottom)
            }
        }
    }

    // MARK: - ⏳ Typing Indicator (Tanpa Avatar, Bersih & Lebar)
    private var typingIndicatorView: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(Color.black.opacity(0.8))

                Text("Sedang memproses...")
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(Color.black.opacity(0.7))

                ForEach(0..<3) { _ in
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 5, height: 5)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.5))
            .shadow(color: .black, radius: 0, x: 2, y: 2)

            Spacer()
        }
    }

    // MARK: - ⚡ Quick Prompt Chips Section
    private var quickPromptChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickPrompts, id: \.title) { item in
                    Button {
                        HapticManager.shared.impact(style: .light)
                        sendPrompt(item.title)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: item.icon)
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.black)

                            Text(item.title)
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(item.color)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.4))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                }
            }
            .padding(.horizontal, HIGSpacing.md)
            .padding(.vertical, 8)
        }
    }

    // MARK: - ⌨️ Bottom Message Input Bar (Native In-App with Mic)
    private var bottomInputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color.black.opacity(0.2))

            HStack(spacing: 10) {
                // 🎙️ Kartun Microphone Button
                Button {
                    handleVoiceButtonTap()
                } label: {
                    ZStack {
                        Circle()
                            .fill(voiceManager.isRecording ? Color.cartoonCoral : Color.cartoonYellow)
                            .frame(width: 42, height: 42)
                            .overlay(Circle().stroke(Color.black, lineWidth: 1.8))
                            .shadow(color: .black, radius: 0, x: 2, y: 2)

                        Image(systemName: voiceManager.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.black)
                            .scaleEffect(voiceManager.isRecording ? (1.0 + voiceManager.audioLevel * 0.3) : 1.0)
                    }
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.5))

                // Input Text Field
                TextField("Ketik tugas, 'besok jam 8', atau tanya...", text: $inputText)
                    .font(.system(size: 14.5, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.8))
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        sendCurrentText()
                    }

                // Tombol Kirim Teks
                Button {
                    sendCurrentText()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34, weight: .black))
                        .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary.opacity(0.4) : Color.cartoonBlue)
                        .background(Circle().fill(Color.white))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.8))
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || assistantService.isProcessing)
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.5))
            }
            .padding(.horizontal, HIGSpacing.md)
            .padding(.vertical, 10)
            .background(Color.cartoonBg)
        }
    }

    private func handleVoiceButtonTap() {
        Task {
            await voiceManager.toggleRecording { transcribed in
                self.inputText = transcribed
            }
        }
    }

    private func sendCurrentText() {
        let textToSend = inputText
        inputText = ""
        if voiceManager.isRecording {
            voiceManager.stopRecording()
        }
        sendPrompt(textToSend)
    }

    private func sendPrompt(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        Task {
            await assistantService.sendMessage(
                text,
                modelContext: modelContext,
                provider: currentProvider,
                apiKey: currentProvider == .gemini ? geminiApiKey : ninerouterApiKey,
                ninerouterBaseUrl: ninerouterBaseUrl,
                ninerouterModel: ninerouterModel
            )
        }
    }

    // MARK: - ⚙️ AI Settings Sheet
    private var aiSettingsSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Pilih Engine AI").font(.system(size: 12, weight: .heavy, design: .rounded))) {
                    Picker("AI Engine", selection: $tempProvider) {
                        ForEach(AIProviderType.allCases) { provider in
                            Text(provider.rawValue).tag(provider)
                        }
                    }
                    .pickerStyle(.inline)
                }

                if tempProvider == .gemini {
                    Section(
                        header: Text("Google AI Studio API Key").font(.system(size: 12, weight: .heavy, design: .rounded)),
                        footer: Text("Dapatkan API Key gratis di ai.google.dev").font(.caption)
                    ) {
                        SecureField("Masukkan Gemini API Key", text: $tempGeminiApiKey)
                    }
                } else if tempProvider == .ninerouter {
                    Section(
                        header: Text("Ninerouter API Gateway").font(.system(size: 12, weight: .heavy, design: .rounded)),
                        footer: Text("Gunakan gateway Ninerouter untuk DeepSeek, Claude, Llama dll.").font(.caption)
                    ) {
                        TextField("Base URL", text: $tempNinerouterBaseUrl)
                        TextField("Model Name", text: $tempNinerouterModel)
                        SecureField("API Key", text: $tempNinerouterApiKey)
                    }
                } else if tempProvider == .googleAccount {
                    Section(header: Text("Cloud AI Bridge").font(.system(size: 12, weight: .heavy, design: .rounded))) {
                        HStack {
                            Circle()
                                .fill(geminiBridge.isBridgeReady ? Color.cartoonMint : Color.cartoonYellow)
                                .frame(width: 8, height: 8)
                            Text(geminiBridge.isBridgeReady ? "Terhubung ke Akun Cloud" : "Memuat Sesi Browser...")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                    }
                }
            }
            .navigationTitle("Pengaturan AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") {
                        isShowingSettings = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        selectedProviderRaw = tempProvider.rawValue
                        geminiApiKey = tempGeminiApiKey
                        ninerouterApiKey = tempNinerouterApiKey
                        ninerouterBaseUrl = tempNinerouterBaseUrl
                        ninerouterModel = tempNinerouterModel
                        isShowingSettings = false
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}
