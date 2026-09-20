//
//  AIAssistantSheetView.swift
//  learning
//
//  Created by macbook on 9/19/26.
//

import SwiftUI
import SwiftData

// MARK: - Quick Prompt Item Model
struct QuickPromptItem: Identifiable {
    var id: String { title }
    let title: String
    let icon: String
    let color: Color
}

// MARK: - Reusable Quick Prompt Chip
struct QuickPromptChip: View {
    let item: QuickPromptItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: item.icon)
                    .font(.system(size: 11, weight: .bold))
                Text(item.title)
                    .font(.system(size: 11.5, weight: .heavy, design: .rounded))
            }
            .foregroundColor(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(item.color)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.4))
            .shadow(color: .black, radius: 0, x: 1, y: 1)
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
    }
}

struct AIAssistantSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var assistantService = MCPAIAssistantService.shared
    @ObservedObject private var voiceManager = VoiceInputManager.shared
    @ObservedObject private var headlessEngine = GeminiHeadlessEngine.shared

    @AppStorage("selectedAIProvider") private var selectedProviderRaw: String = AIProviderType.googleAccount.rawValue
    @AppStorage("geminiAPIKey") private var geminiAPIKey: String = ""
    @AppStorage("ninerouterAPIKey") private var ninerouterAPIKey: String = ""
    @AppStorage("ninerouterBaseUrl") private var ninerouterBaseUrl: String = "https://openrouter.ai/api/v1"
    @AppStorage("ninerouterModel") private var ninerouterModel: String = "google/gemini-flash-1.5"

    @State private var inputText: String = ""
    @State private var isShowingSettings: Bool = false
    @State private var isShowingGoogleLoginWeb: Bool = false
    @State private var tempApiKey: String = ""
    @State private var tempNinerouterModel: String = ""
    @FocusState private var isInputFocused: Bool

    private var currentProvider: AIProviderType {
        AIProviderType(rawValue: selectedProviderRaw) ?? .googleAccount
    }

    // Saran Prompt Cepat MCP Multi-Feature (Tanpa Karakter Emoticon)
    private let quickPrompts: [QuickPromptItem] = [
        QuickPromptItem(title: "Susun rencana hari ini (Morning Briefing)", icon: "sun.max.fill", color: .cartoonYellow),
        QuickPromptItem(title: "Evaluasi hari ini (Evening Review)", icon: "moon.stars.fill", color: .cartoonLavender),
        QuickPromptItem(title: "Tata ulang jadwal terlewat (AI Rebalance)", icon: "wand.and.stars", color: .cartoonOrange),
        QuickPromptItem(title: "Tambah tugas Coding besok jam 8 malam", icon: "bolt.fill", color: .cartoonMint),
        QuickPromptItem(title: "Mulai fokus 25 menit", icon: "timer", color: .cartoonCoral),
        QuickPromptItem(title: "Cek data kesehatan & langkah", icon: "heart.fill", color: .cartoonPink),
        QuickPromptItem(title: "Rangkum status aktivitas hari ini", icon: "chart.bar.fill", color: .cartoonBlue),
        QuickPromptItem(title: "Ceklis habit hari ini", icon: "flame.fill", color: .cartoonOrange),
        QuickPromptItem(title: "Kunci aplikasi pengganggu", icon: "shield.lefthalf.filled", color: .cartoonLavender),
        QuickPromptItem(title: "Bersihkan tugas selesai", icon: "trash.slash.fill", color: .cartoonMint)
    ]

    var body: some View {
        ZStack {
            Color.cartoonBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Solid Header Bar (Tetap di Atas, Tidak Menghalangi Scroll)
                customTopHeaderBar

                // MARK: - Chat Messages ScrollView
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: HIGSpacing.md) {
                            ForEach(assistantService.messages) { msg in
                                RichAIMessageBubbleView(message: msg) { prompt in
                                    sendPromptMessage(prompt)
                                }
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
                    audioLiveWaveIndicator
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Audio Recording Error / Permission Banner
                if let err = voiceManager.errorMessage {
                    audioErrorBanner(message: err)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // MARK: - Quick Prompt Suggestions Carousel
                quickPromptChipsSection

                // MARK: - Bottom Message Input Bar (Native In-App with Mic)
                bottomInputBar
            }
        }
        .background {
            // Invisible Background Engine
            InvisibleGeminiWebEngineView()
                .frame(width: 0, height: 0)
                .opacity(0.001)
                .allowsHitTesting(false)
        }
        .onAppear {
            Task { @MainActor in
                _ = await headlessEngine.checkLoginStatus()
            }
        }
        .onDisappear {
            voiceManager.stopRecording()
        }
        .sheet(isPresented: $isShowingSettings) {
            aiSettingsSheet
        }
        .sheet(isPresented: $isShowingGoogleLoginWeb) {
            GeminiWebMCPView()
                .onDisappear {
                    Task { @MainActor in
                        _ = await headlessEngine.checkLoginStatus()
                    }
                }
        }
    }

    // MARK: - Custom Top Header Bar (Solid, Sharp & Cartoonish)
    private var customTopHeaderBar: some View {
        HStack(spacing: 12) {
            // Tombol Tutup (X)
            Button {
                HapticManager.shared.impact(style: .light)
                voiceManager.stopRecording()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.black)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.5))
                            .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                    )
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

            Spacer()

            // Judul & Status Indikator AI
            VStack(spacing: 2) {
                Text("AI Assistant")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                HStack(spacing: 5) {
                    Circle()
                        .fill(voiceManager.isRecording ? Color.cartoonCoral : Color.cartoonMint)
                        .frame(width: 7, height: 7)
                    Text(voiceManager.isRecording ? "Mendengarkan..." : "Asisten Aktif")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(voiceManager.isRecording ? Color.cartoonCoral : Color.black.opacity(0.75))
                }
            }

            Spacer()

            // Tombol Aksi Kanan (Clear History & Pengaturan)
            HStack(spacing: 8) {
                // Clear Chat Button (Cartoonish Coral Style with Heavy Trash Icon)
                Button {
                    HapticManager.shared.impact(style: .medium)
                    assistantService.clearHistory()
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.black)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.cartoonCoral)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.5))
                                .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                        )
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                // Settings Button
                Button {
                    HapticManager.shared.impact(style: .light)
                    tempApiKey = (currentProvider == .geminiApiKey) ? geminiAPIKey : ninerouterAPIKey
                    tempNinerouterModel = ninerouterModel
                    isShowingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.cartoonYellow)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.5))
                                .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                        )
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
        }
        .padding(.horizontal, HIGSpacing.md)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(Color.cartoonBg)
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(Color.black.opacity(0.15))
        }
    }

    // MARK: - Quick Prompt Suggestions Carousel
    private var quickPromptChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickPrompts) { item in
                    QuickPromptChip(item: item) {
                        HapticManager.shared.selection()
                        sendDirectPrompt(item.title)
                    }
                }
            }
            .padding(.horizontal, HIGSpacing.md)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Bottom Message Input Bar (Native SwiftUI with Mic)
    private var bottomInputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color.black.opacity(0.2))

            HStack(spacing: 10) {
                // Input TextField
                HStack(spacing: 8) {
                    Image(systemName: "sparkle")
                        .foregroundColor(.black.opacity(0.6))
                        .font(.system(size: 14, weight: .bold))

                    TextField("Tanya AI / tambah tugas...", text: $inputText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                        .focused($isInputFocused)
                        .submitLabel(.send)
                        .onSubmit {
                            submitCurrentInput()
                        }

                    if !inputText.isEmpty {
                        Button {
                            inputText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.black.opacity(0.5))
                                .font(.system(size: 14))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 1.6)
                )
                .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)

                // Voice Recording Mic Button
                Button {
                    toggleVoiceRecording()
                } label: {
                    Image(systemName: voiceManager.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(.black)
                        .frame(width: 42, height: 42)
                        .background(voiceManager.isRecording ? Color.cartoonCoral : Color.cartoonLavender)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 1.6)
                        )
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                // Send Button
                Button {
                    submitCurrentInput()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.black)
                        .frame(width: 42, height: 42)
                        .background(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : Color.cartoonMint)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 1.6)
                        )
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, HIGSpacing.md)
            .padding(.vertical, 10)
            .background(Color.cartoonBg)
        }
    }

    // MARK: - Audio Live Wave Indicator
    private var audioLiveWaveIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
                .symbolEffect(.pulse, isActive: voiceManager.isRecording)

            Text("Mendengarkan... Bicaralah sekarang")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.black)

            Spacer()

            Button("Batal") {
                voiceManager.stopRecording()
            }
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundColor(.red)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.cartoonCoral.opacity(0.85))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.2))
        .padding(.horizontal, HIGSpacing.md)
        .padding(.bottom, 6)
    }

    // MARK: - Audio Error Banner
    private func audioErrorBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.black)
                .font(.system(size: 12, weight: .bold))

            Text(message)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .lineLimit(2)

            Spacer()

            Button {
                voiceManager.errorMessage = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.cartoonOrange.opacity(0.85))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
        .padding(.horizontal, HIGSpacing.md)
        .padding(.bottom, 6)
    }

    // MARK: - Typing Indicator View
    private var typingIndicatorView: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.black)
                .frame(width: 7, height: 7)
            Circle()
                .fill(Color.black.opacity(0.6))
                .frame(width: 7, height: 7)
            Circle()
                .fill(Color.black.opacity(0.3))
                .frame(width: 7, height: 7)

            if let activeTool = assistantService.activeToolName {
                Text("Menjalankan MCP: \(activeTool)...")
                    .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.black.opacity(0.8))
                    .padding(.leading, 4)
            } else {
                Text("AI sedang mengetik...")
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundColor(.black.opacity(0.8))
                    .padding(.leading, 4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.4))
        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - AI Settings Sheet
    private var aiSettingsSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Model AI & Provider"), footer: Text("Mode Akun Google Pribadi gratis tanpa API Key. Untuk API kencang, gunakan Gemini API Key.")) {
                    Picker("Provider AI", selection: $selectedProviderRaw) {
                        ForEach(AIProviderType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if currentProvider == .googleAccount {
                    Section(header: Text("Status Akun Google Gemini"), footer: Text("Mode ini gratis tanpa memerlukan API Key. Cukup login ke akun Google Anda satu kali.")) {
                        HStack {
                            Text("Status Sesi")
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(headlessEngine.isLoggedIn ? Color.cartoonMint : Color.cartoonCoral)
                                    .frame(width: 8, height: 8)
                                Text(headlessEngine.isLoggedIn ? "Terhubung" : "Belum Login")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(headlessEngine.isLoggedIn ? .green : .red)
                            }
                        }

                        Button {
                            isShowingSettings = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isShowingGoogleLoginWeb = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "safari.fill")
                                Text(headlessEngine.isLoggedIn ? "Perbarui / Ganti Akun Google" : "Login ke Akun Google Gemini")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                } else if currentProvider == .geminiApiKey {
                    Section(header: Text("Gemini API Key"), footer: Text("Dapatkan API Key gratis di https://aistudio.google.com")) {
                        SecureField("Masukkan Gemini API Key...", text: $tempApiKey)
                            .font(.system(size: 13, design: .monospaced))
                    }
                } else if currentProvider == .ninerouter {
                    Section(header: Text("OpenRouter / Ninerouter Settings")) {
                        SecureField("API Key...", text: $tempApiKey)
                            .font(.system(size: 13, design: .monospaced))
                        TextField("Base URL", text: $ninerouterBaseUrl)
                            .font(.system(size: 13, design: .monospaced))
                        TextField("Model Name", text: $tempNinerouterModel)
                            .font(.system(size: 13, design: .monospaced))
                    }
                }
            }
            .navigationTitle("Pengaturan AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Batal") {
                        isShowingSettings = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Simpan") {
                        if currentProvider == .geminiApiKey {
                            geminiAPIKey = tempApiKey
                        } else if currentProvider == .ninerouter {
                            ninerouterAPIKey = tempApiKey
                            ninerouterModel = tempNinerouterModel
                        }
                        isShowingSettings = false
                    }
                    .bold()
                }
            }
        }
    }

    // MARK: - Actions & Helpers
    private func submitCurrentInput() {
        let textToSend = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textToSend.isEmpty else { return }

        HapticManager.shared.impact(style: .medium)
        SoundManager.shared.playPop()
        inputText = ""

        Task { @MainActor in
            await assistantService.sendMessage(
                textToSend,
                provider: currentProvider,
                apiKey: (currentProvider == .geminiApiKey) ? geminiAPIKey : ninerouterAPIKey,
                ninerouterBaseUrl: ninerouterBaseUrl,
                ninerouterModel: ninerouterModel,
                modelContext: modelContext
            )
        }
    }

    private func sendDirectPrompt(_ prompt: String) {
        Task { @MainActor in
            await assistantService.sendMessage(
                prompt,
                provider: currentProvider,
                apiKey: (currentProvider == .geminiApiKey) ? geminiAPIKey : ninerouterAPIKey,
                ninerouterBaseUrl: ninerouterBaseUrl,
                ninerouterModel: ninerouterModel,
                modelContext: modelContext
            )
        }
    }

    private func sendPromptMessage(_ prompt: String) {
        sendDirectPrompt(prompt)
    }

    private func toggleVoiceRecording() {
        if voiceManager.isRecording {
            voiceManager.stopRecording()
        } else {
            HapticManager.shared.impact(style: .heavy)
            SoundManager.shared.playPop()
            Task { @MainActor in
                await voiceManager.startRecording { recognizedText in
                    self.inputText = recognizedText
                }
            }
        }
    }

    private func smoothScrollToBottom(proxy: ScrollViewProxy) {
        if let last = assistantService.messages.last {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    private func smoothScrollToIndicator(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo("typingIndicator", anchor: .bottom)
        }
    }
}
