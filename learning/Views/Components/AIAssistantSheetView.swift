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

    // Saran Prompt Cepat MCP Multi-Feature
    private let quickPrompts: [(title: String, icon: String, color: Color)] = [
        ("⚡ Buat tugas Coding prioritas tinggi", "bolt.fill", Color.cartoonYellow),
        ("⏱️ Mulai fokus 25 menit", "timer", Color.cartoonCoral),
        ("🏃‍♂️ Cek data kesehatan & langkah", "heart.fill", Color.cartoonPink),
        ("📊 Rangkum aktivitas hari ini", "chart.bar.fill", Color.cartoonMint),
        ("🔥 Ceklis habit hari ini", "flame.fill", Color.cartoonOrange),
        ("🚀 Buat rencana proyek Website", "folder.badge.plus", Color.cartoonBlue),
        ("🛡️ Kunci aplikasi pengganggu", "shield.lefthalf.filled", Color.cartoonLavender),
        ("📋 Lihat daftar tugas penting", "list.bullet.rectangle.portrait", Color.cartoonMint),
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
                        sendQuickPrompt(item.title)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: item.icon)
                                .font(.system(size: 10.5, weight: .heavy))
                            Text(item.title)
                                .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(item.color.opacity(0.9))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.4))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                }
            }
            .padding(.horizontal, HIGSpacing.md)
            .padding(.vertical, 6)
        }
    }

    // MARK: - ✍️ Bottom Native Input Bar (With Mic Voice-to-Task Button)
    private var bottomInputBar: some View {
        HStack(spacing: 8) {
            // Text Input Container
            HStack {
                TextField("Tanya jadwal, habit, atau ketik / bicara...", text: $inputText, axis: .vertical)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .background(Color.white)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 1.6))
            .shadow(color: .black, radius: 0, x: 2, y: 2)

            // 🎙️ Tombol Suara / Dikte (Voice-to-Task Dictation)
            Button {
                Task {
                    await voiceManager.toggleRecording { transcribed in
                        self.inputText = transcribed
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(voiceManager.isRecording ? Color.cartoonCoral : Color.cartoonYellow)
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.8))
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                        .scaleEffect(voiceManager.isRecording ? 1.0 + (voiceManager.audioLevel * 0.15) : 1.0)

                    Image(systemName: voiceManager.isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 17, weight: .black))
                        .foregroundColor(.black)
                }
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))

            // 🚀 Tombol Kirim Pesan
            Button {
                if voiceManager.isRecording {
                    voiceManager.stopRecording()
                }
                sendMessage()
            } label: {
                ZStack {
                    Circle()
                        .fill(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : Color.cartoonMint)
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.8))
                        .shadow(color: .black, radius: 0, x: 2, y: 2)

                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.black)
                }
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || assistantService.isProcessing)
        }
        .padding(.horizontal, HIGSpacing.md)
        .padding(.vertical, 8)
        .background(Color.cartoonBg)
    }

    // MARK: - ⚙️ Modal Pengaturan AI Provider & API Keys
    private var aiSettingsSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("PILIH SUMBER AI").font(.system(size: 11, weight: .heavy, design: .rounded))) {
                    Picker("Provider", selection: $tempProvider) {
                        ForEach(AIProviderType.allCases) { provider in
                            Text(provider.shortName).tag(provider)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)

                    Text(tempProvider.rawValue)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }

                if tempProvider == .gemini {
                    Section(header: Text("GEMINI API KEY").font(.system(size: 11, weight: .heavy, design: .rounded))) {
                        SecureField("Tempel Google AI Studio API Key", text: $tempGeminiApiKey)
                            .font(.system(size: 13, design: .monospaced))
                    }
                }

                if tempProvider == .ninerouter {
                    Section(header: Text("NINEROUTER CONFIGURATION").font(.system(size: 11, weight: .heavy, design: .rounded))) {
                        SecureField("API Key", text: $tempNinerouterApiKey)
                            .font(.system(size: 13, design: .monospaced))
                        TextField("Base URL", text: $tempNinerouterBaseUrl)
                            .font(.system(size: 13, design: .monospaced))
                        TextField("Model Name", text: $tempNinerouterModel)
                            .font(.system(size: 13, design: .monospaced))
                    }
                }

                Section(header: Text("INFO FITUR MCP").font(.system(size: 11, weight: .heavy, design: .rounded))) {
                    Text("Asisten terhubung langsung dengan sistem aplikasi (SwiftData, Pomodoro Timer, Apple Health, Habit Tracker, dan Screen Time) secara lokal via Model Context Protocol.")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
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

    // MARK: - 🚀 Actions
    private func sendMessage() {
        let textToSend = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textToSend.isEmpty else { return }

        inputText = ""
        isInputFocused = false

        Task {
            await assistantService.sendMessage(
                textToSend,
                modelContext: modelContext,
                provider: currentProvider,
                apiKey: currentProvider == .gemini ? geminiApiKey : ninerouterApiKey,
                ninerouterBaseUrl: ninerouterBaseUrl,
                ninerouterModel: ninerouterModel
            )
        }
    }

    private func sendQuickPrompt(_ prompt: String) {
        if voiceManager.isRecording {
            voiceManager.stopRecording()
        }
        isInputFocused = false
        Task {
            await assistantService.sendMessage(
                prompt,
                modelContext: modelContext,
                provider: currentProvider,
                apiKey: currentProvider == .gemini ? geminiApiKey : ninerouterApiKey,
                ninerouterBaseUrl: ninerouterBaseUrl,
                ninerouterModel: ninerouterModel
            )
        }
    }
}
