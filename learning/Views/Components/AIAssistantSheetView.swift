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

    // Saran Prompt Cepat MCP Multi-Feature (Termasuk Daily Coach, Rebalance, & Natural Time Parsing)
    private let quickPrompts: [(title: String, icon: String, color: Color)] = [
        ("🌅 Susun rencana hari ini (Morning Briefing)", "sun.max.fill", Color.cartoonYellow),
        ("🌙 Evaluasi hari ini (Evening Review)", "moon.stars.fill", Color.cartoonLavender),
        ("🤖 Tata ulang jadwal terlewat (AI Rebalance)", "wand.and.stars", Color.cartoonYellow),
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
                    // MARK: - 🔐 Login Notice Banner (Jika Google Account belum terhubung)
                    if currentProvider == .googleAccount && !headlessEngine.isLoggedIn {
                        googleLoginRequiredBanner
                    }

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
                        audioLiveWaveIndicator
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Audio Recording Error / Permission Banner
                    if let err = voiceManager.errorMessage {
                        audioErrorBanner(message: err)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // MARK: - 💡 Quick Prompt Suggestions Carousel
                    quickPromptChipsSection

                    // MARK: - ✍️ Bottom Message Input Bar (Native In-App with Mic)
                    bottomInputBar
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: voiceManager.isRecording)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: voiceManager.errorMessage)
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    _ = await headlessEngine.checkLoginStatus()
                }
            }
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
                            .shadow(color: .black, radius: 0, x: 1, y: 1)
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
                                .foregroundColor(voiceManager.isRecording ? Color.cartoonCoral : Color.black.opacity(0.75))
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        // Clear Chat Button
                        Button {
                            HapticManager.shared.impact(style: .medium)
                            assistantService.clearHistory()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 32, height: 32)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.5))
                                .shadow(color: .black, radius: 0, x: 1, y: 1)
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
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 32, height: 32)
                                .background(Color.cartoonYellow)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.5))
                                .shadow(color: .black, radius: 0, x: 1, y: 1)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    }
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                aiSettingsSheet
            }
            .sheet(isPresented: $isShowingGoogleLoginWeb) {
                GeminiWebMCPView()
                    .onDisappear {
                        Task {
                            _ = await headlessEngine.checkLoginStatus()
                        }
                    }
            }
        }
    }

    // MARK: - 🔐 Google Login Required Banner
    private var googleLoginRequiredBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.black)

            VStack(alignment: .leading, spacing: 2) {
                Text("Sesi Akun Google Belum Terhubung")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                Text("Login sekali untuk menggunakan AI Gemini gratis")
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.black.opacity(0.8))
            }

            Spacer()

            Button {
                HapticManager.shared.selection()
                isShowingGoogleLoginWeb = true
            } label: {
                Text("Login 🔑")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                    .shadow(color: .black, radius: 0, x: 1, y: 1)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.cartoonYellow)
        .overlay(Rectangle().frame(height: 1.2).foregroundColor(.black), alignment: .bottom)
    }

    // MARK: - 💡 Quick Prompt Suggestions Carousel
    private var quickPromptChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickPrompts, id: \.title) { item in
                    Button {
                        HapticManager.shared.selection()
                        sendDirectPrompt(item.title)
                    } label: {
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
            .padding(.horizontal, HIGSpacing.md)
            .padding(.vertical, 6)
        }
    }

    // MARK: - ✍️ Bottom Message Input Bar (Native In-App with Mic)
    private var bottomInputBar: some View {
        HStack(spacing: 8) {
            // Text Field Input
            HStack(spacing: 6) {
                TextField("Tanya AI, minta rangkuman, atau dikte tugas...", text: $inputText)
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .focused($isInputFocused)
                    .onSubmit {
                        submitCurrentInput()
                    }

                if !inputText.isEmpty {
                    Button {
                        inputText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 46)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
            )
            .shadow(color: .black, radius: 0, x: 2, y: 2)

            // Mic Dictation Button
            Button {
                toggleVoiceRecording()
            } label: {
                Image(systemName: voiceManager.isRecording ? "stop.circle.fill" : "mic.fill")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.black)
                    .frame(width: 46, height: 46)
                    .background(voiceManager.isRecording ? Color.cartoonCoral : Color.cartoonMint)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                    )
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))

            // Send Button
            let canSend = !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            Button {
                submitCurrentInput()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(.black)
                    .frame(width: 46, height: 46)
                    .background(canSend ? Color.cartoonYellow : Color.gray.opacity(0.3))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                    )
                    .shadow(color: .black, radius: 0, x: canSend ? 2 : 1, y: canSend ? 2 : 1)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: canSend ? 1.2 : 0))
            .disabled(!canSend || assistantService.isProcessing)
        }
        .padding(.horizontal, HIGSpacing.md)
        .padding(.vertical, 8)
        .background(Color.cartoonBg)
    }

    // MARK: - 🎙️ Audio Live Wave Indicator
    private var audioLiveWaveIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
            Text("Sedang merekam suara... Silakan bicara langsung")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.cartoonCoral)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.4))
        .shadow(color: .black, radius: 0, x: 1, y: 1)
        .padding(.horizontal, HIGSpacing.md)
        .padding(.top, 4)
    }

    // MARK: - ⚠️ Audio Error Banner
    private func audioErrorBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.black)
            Text(message)
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundColor(.black)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.cartoonYellow)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
        .padding(.horizontal, HIGSpacing.md)
        .padding(.top, 4)
    }

    // MARK: - ⏳ Typing Indicator
    private var typingIndicatorView: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.cartoonCoral)
                .frame(width: 7, height: 7)
            Circle()
                .fill(Color.cartoonYellow)
                .frame(width: 7, height: 7)
            Circle()
                .fill(Color.cartoonMint)
                .frame(width: 7, height: 7)

            Text("AI sedang berpikir & menyusun respons...")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(Color.black.opacity(0.8))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.2))
        .shadow(color: .black, radius: 0, x: 1, y: 1)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - ⚙️ AI Settings Sheet
    private var aiSettingsSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Penyedia Layanan AI")) {
                    Picker("Provider", selection: $selectedProviderRaw) {
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
                                Text(headlessEngine.isLoggedIn ? "Perbarui / Ganti Akun Google" : "Login ke Akun Google Gemini 🔑")
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

    // MARK: - 🚀 Actions
    private func toggleVoiceRecording() {
        if voiceManager.isRecording {
            voiceManager.stopRecording()
            if !voiceManager.transcribedText.isEmpty {
                inputText = voiceManager.transcribedText
                voiceManager.transcribedText = ""
                submitCurrentInput()
            }
        } else {
            HapticManager.shared.impact(style: .medium)
            Task {
                await voiceManager.startRecording { recognizedText in
                    self.inputText = recognizedText
                }
            }
        }
    }

    private func submitCurrentInput() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        isInputFocused = false

        Task {
            await assistantService.sendMessage(
                text,
                provider: currentProvider,
                apiKey: (currentProvider == .geminiApiKey) ? geminiAPIKey : ninerouterAPIKey,
                ninerouterBaseUrl: ninerouterBaseUrl,
                ninerouterModel: ninerouterModel,
                modelContext: modelContext
            )
        }
    }

    private func sendDirectPrompt(_ text: String) {
        Task {
            await assistantService.sendMessage(
                text,
                provider: currentProvider,
                apiKey: (currentProvider == .geminiApiKey) ? geminiAPIKey : ninerouterAPIKey,
                ninerouterBaseUrl: ninerouterBaseUrl,
                ninerouterModel: ninerouterModel,
                modelContext: modelContext
            )
        }
    }

    private func smoothScrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = assistantService.messages.last?.id {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }

    private func smoothScrollToIndicator(proxy: ScrollViewProxy) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            proxy.scrollTo("typingIndicator", anchor: .bottom)
        }
    }
}
