//
//  AIAssistantSheetView.swift
//  learning
//
//  Created by macbook on 9/19/26.
//

import SwiftUI
import SwiftData
import GoogleSignIn

struct AIAssistantSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var assistantService = MCPAIAssistantService.shared

    @AppStorage("aiProviderType") private var selectedProviderRaw: String = AIProviderType.local.rawValue
    @AppStorage("geminiApiKey") private var geminiApiKey: String = ""
    @AppStorage("ninerouterApiKey") private var ninerouterApiKey: String = ""
    @AppStorage("ninerouterBaseUrl") private var ninerouterBaseUrl: String = "https://api.ninerouter.com/v1"
    @AppStorage("ninerouterModel") private var ninerouterModel: String = "deepseek/deepseek-chat"

    @State private var inputText: String = ""
    @State private var isShowingSettings: Bool = false
    @State private var isShowingGeminiWeb: Bool = false
    @State private var tempProvider: AIProviderType = .local
    @State private var tempGeminiApiKey: String = ""
    @State private var tempNinerouterApiKey: String = ""
    @State private var tempNinerouterBaseUrl: String = ""
    @State private var tempNinerouterModel: String = ""
    @State private var isGoogleSigningIn: Bool = false
    @FocusState private var isInputFocused: Bool

    private var currentProvider: AIProviderType {
        AIProviderType(rawValue: selectedProviderRaw) ?? .local
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

                VStack(spacing: 0) {
                    // MARK: - 🌐 Banner Akses Cepat Gemini.com
                    geminiWebQuickBanner

                    // MARK: - 💬 Chat Messages ScrollView
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: HIGSpacing.md) {
                                ForEach(assistantService.messages) { msg in
                                    chatBubbleView(for: msg)
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

                    // MARK: - ✍️ Bottom Message Input Bar
                    bottomInputBar
                }
            }
            .navigationTitle("AI Buddy (MCP)")
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
                        Text("AI Buddy (MCP)")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)

                        HStack(spacing: 4) {
                            Circle()
                                .fill(currentProvider == .local ? Color.cartoonMint : Color.cartoonBlue)
                                .frame(width: 6, height: 6)
                            Text(currentProvider.shortName)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        // Tombol Buka Gemini.com Web Resmi
                        Button {
                            HapticManager.shared.impact(style: .medium)
                            isShowingGeminiWeb = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 11, weight: .black))
                                Text("Gemini.com")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .frame(height: 32)
                            .background(Color.cartoonBlue)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.5))
                            .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

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
            .sheet(isPresented: $isShowingGeminiWeb) {
                SafariView(url: URL(string: "https://gemini.google.com")!)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - 🌐 Banner Akses Cepat Gemini.com
    private var geminiWebQuickBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.black)

            Text("Mau ngobrol langsung di akun Gemini biasa?")
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundColor(.black)

            Spacer()

            Button {
                HapticManager.shared.impact(style: .light)
                isShowingGeminiWeb = true
            } label: {
                Text("Buka Gemini.com ↗")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cartoonYellow)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
            }
        }
        .padding(.horizontal, HIGSpacing.md)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.85))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.black.opacity(0.1)), alignment: .bottom)
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

    // MARK: - 💬 Chat Bubble Component
    private func chatBubbleView(for msg: MCPAIChatMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if msg.role == .assistant {
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

            VStack(alignment: msg.role == .user ? .trailing : .leading, spacing: 6) {
                // Label Tool MCP (Jika Ada Eksekusi Alat)
                if let tool = msg.toolCall {
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 1.2)
                    )
                }

                // Teks Pesan
                Text(.init(msg.content))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.black)
                    .lineSpacing(4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(msg.role == .user ? Color.cartoonBlue : Color.white)
                    .cornerRadius(CartoonMetrics.cardCornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                            .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                    )
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
            }

            if msg.role == .user {
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

    // MARK: - ⏳ Typing Indicator
    private var typingIndicatorView: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.cartoonYellow)
                    .frame(width: 34, height: 34)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)

                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(.black)
            }

            HStack(spacing: 6) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.black.opacity(0.75))
                        .frame(width: 6, height: 6)
                }
                Text("Memproses...")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black, lineWidth: 1.5))
            .shadow(color: .black, radius: 0, x: 2, y: 2)

            Spacer()
        }
    }

    // MARK: - ⚡ Quick Prompt Chips Section
    private var quickPromptChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickPrompts, id: \.title) { prompt in
                    Button {
                        HapticManager.shared.impact(style: .light)
                        inputText = prompt.title
                        sendCurrentMessage()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: prompt.icon)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.black)
                            Text(prompt.title)
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(prompt.color)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 1.4)
                        )
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                }
            }
            .padding(.horizontal, HIGSpacing.md)
            .padding(.vertical, HIGSpacing.xs)
        }
        .background(Color.white.opacity(0.7))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.black.opacity(0.1)), alignment: .top)
    }

    // MARK: - ✍️ Bottom Input Bar
    private var bottomInputBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.cartoonTextPrimary)

                TextField("Diskusikan rencana atau minta aksi aplikasi...", text: $inputText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .focused($isInputFocused)
                    .onSubmit {
                        sendCurrentMessage()
                    }
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Color.white)
            .cornerRadius(CartoonMetrics.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
            )
            .shadow(color: .black, radius: 0, x: 2, y: 2)

            // Tombol Kirim
            Button {
                sendCurrentMessage()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.black)
                    .frame(width: 48, height: 48)
                    .background(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : Color.cartoonMint)
                    .cornerRadius(CartoonMetrics.cardCornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                            .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                    )
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || assistantService.isProcessing)
        }
        .padding(.horizontal, HIGSpacing.md)
        .padding(.vertical, HIGSpacing.sm)
        .background(Color.cartoonBg)
    }

    // MARK: - ⚙️ AI Provider & API Key Settings Sheet
    private var aiSettingsSheet: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: HIGSpacing.lg) {
                    
                    // Banner Buka Gemini.com
                    Button {
                        isShowingSettings = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isShowingGeminiWeb = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Buka Gemini Web Resmi (gemini.google.com)")
                                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                                    .foregroundColor(.black)
                                Text("Gunakan langsung akun Google konsumen tanpa API Key")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right.square.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                        }
                        .padding(12)
                        .background(Color.cartoonBlue.opacity(0.3))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.2))
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                    // 1. Pilihan Provider
                    VStack(alignment: .leading, spacing: HIGSpacing.xs) {
                        Text("PILIHAN ENGINE IN-APP")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)

                        VStack(spacing: 8) {
                            ForEach(AIProviderType.allCases) { prov in
                                Button {
                                    HapticManager.shared.selection()
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                        tempProvider = prov
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: providerIcon(for: prov))
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.black)

                                        Text(prov.rawValue)
                                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                                            .foregroundColor(.black)

                                        Spacer()

                                        if tempProvider == prov {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.cartoonMint)
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .frame(height: 48)
                                    .background(tempProvider == prov ? Color.cartoonYellow.opacity(0.4) : Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.black, lineWidth: tempProvider == prov ? 2.0 : 1.2)
                                    )
                                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                                }
                                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                            }
                        }
                    }

                    // 2. Form Spesifik Provider
                    if tempProvider == .gemini {
                        VStack(alignment: .leading, spacing: HIGSpacing.xs) {
                            Text("GOOGLE AI STUDIO API KEY (OPSIONAL)")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(.secondary)

                            CartoonInputField(
                                placeholder: "AIzaSy...",
                                text: $tempGeminiApiKey,
                                icon: "key.fill"
                            )
                        }
                    } else if tempProvider == .ninerouter {
                        VStack(alignment: .leading, spacing: HIGSpacing.xs) {
                            Text("PENGATURAN NINEROUTER")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(.secondary)

                            CartoonInputField(
                                placeholder: "Ninerouter API Key (nr-xxxx)",
                                text: $tempNinerouterApiKey,
                                icon: "key.fill"
                            )

                            CartoonInputField(
                                placeholder: "Model (cth: deepseek/deepseek-chat)",
                                text: $tempNinerouterModel,
                                icon: "cpu"
                            )

                            CartoonInputField(
                                placeholder: "Base URL (https://api.ninerouter.com/v1)",
                                text: $tempNinerouterBaseUrl,
                                icon: "link"
                            )
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("ℹ️ Smart Local Co-Planning Engine")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                            Text("Bekerja secara offline langsung di perangkat tanpa API Key. Mampu berdiskusi rencana dan merekomendasikan subtasks sebelum dibuat!")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.2))
                    }

                    // 3. Tombol Simpan
                    Button {
                        selectedProviderRaw = tempProvider.rawValue
                        geminiApiKey = tempGeminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        ninerouterApiKey = tempNinerouterApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        ninerouterBaseUrl = tempNinerouterBaseUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "https://api.ninerouter.com/v1" : tempNinerouterBaseUrl
                        ninerouterModel = tempNinerouterModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "deepseek/deepseek-chat" : tempNinerouterModel

                        HapticManager.shared.success()
                        isShowingSettings = false
                    } label: {
                        Text("Simpan Konfigurasi")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.cartoonMint)
                            .cornerRadius(CartoonMetrics.cardCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                }
                .padding(HIGSpacing.lg)
            }
            .background(Color.cartoonBg)
            .navigationTitle("Konfigurasi AI Engine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tutup") {
                        isShowingSettings = false
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                }
            }
        }
    }

    private func providerIcon(for prov: AIProviderType) -> String {
        switch prov {
        case .local: return "bolt.shield.fill"
        case .googleAccount: return "person.crop.circle.fill.badge.checkmark"
        case .gemini: return "sparkles"
        case .ninerouter: return "network"
        }
    }

    // MARK: - 📤 Action Kirim Pesan
    private func sendCurrentMessage() {
        let text = inputText
        inputText = ""
        isInputFocused = false

        Task {
            await assistantService.sendMessage(
                text,
                modelContext: modelContext,
                provider: currentProvider,
                apiKey: currentProvider == .gemini ? geminiApiKey : (currentProvider == .ninerouter ? ninerouterApiKey : ""),
                ninerouterBaseUrl: ninerouterBaseUrl,
                ninerouterModel: ninerouterModel
            )
        }
    }
}
