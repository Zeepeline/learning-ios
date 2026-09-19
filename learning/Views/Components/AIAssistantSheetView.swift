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

    dynamic var body: some View {
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

                    // MARK: - ⚡ Quick Prompt Chips
                    quickPromptChipsSection

                    // MARK: - ✍️ Bottom Message Input Bar (Native In-App)
                    bottomInputBar
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticManager.shared.impact(style: .light)
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
                                .fill(Color.cartoonMint)
                                .frame(width: 6, height: 6)
                            Text("Asisten Aktif")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
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

    // MARK: - ✍️ Bottom Native Input Bar
    private var bottomInputBar: some View {
        HStack(spacing: 8) {
            HStack {
                TextField("Tanya jadwal, habit, atau ketik perintah...", text: $inputText, axis: .vertical)
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

            Button {
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
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                            HStack {
                                Text("Dapatkan API Key Gratis di AI Studio")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 11, weight: .bold))
                            }
                        }
                    }
                } else if tempProvider == .ninerouter {
                    Section(header: Text("NINEROUTER CONFIG").font(.system(size: 11, weight: .heavy, design: .rounded))) {
                        SecureField("Tempel 9Router / OpenRouter API Key", text: $tempNinerouterApiKey)
                            .font(.system(size: 13, design: .monospaced))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        TextField("Base URL (e.g. https://api.ninerouter.com/v1)", text: $tempNinerouterBaseUrl)
                            .font(.system(size: 13, design: .monospaced))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        TextField("Model (e.g. deepseek/deepseek-chat)", text: $tempNinerouterModel)
                            .font(.system(size: 13, design: .monospaced))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                } else {
                    Section(header: Text("AKUN GOOGLE").font(.system(size: 11, weight: .heavy, design: .rounded))) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Mode Headless Otomatis Aktif")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                            Text("Aplikasi otomatis menghubungkan sesi Google tanpa perlu menyalin API Key secara manual.")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
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
                        selectedProviderRaw = tempProvider.rawValue
                        geminiApiKey = tempGeminiApiKey
                        ninerouterApiKey = tempNinerouterApiKey
                        ninerouterBaseUrl = tempNinerouterBaseUrl.isEmpty ? "https://api.ninerouter.com/v1" : tempNinerouterBaseUrl
                        ninerouterModel = tempNinerouterModel.isEmpty ? "deepseek/deepseek-chat" : tempNinerouterModel
                        isShowingSettings = false
                        HapticManager.shared.success()
                    }
                    .font(.system(.body, design: .rounded).weight(.bold))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - 🚀 Actions
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        HapticManager.shared.impact(style: .light)
        inputText = ""

        Task {
            await assistantService.sendMessage(text, modelContext: modelContext)
        }
    }

    private func sendQuickPrompt(_ prompt: String) {
        let cleanPrompt = prompt.replacingOccurrences(of: "^[^a-zA-Z0-9]+", with: "", options: .regularExpression).trimmingCharacters(in: .whitespaces)
        HapticManager.shared.impact(style: .light)

        Task {
            await assistantService.sendMessage(cleanPrompt, modelContext: modelContext)
        }
    }
}
