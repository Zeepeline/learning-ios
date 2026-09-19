//
//  GeminiWebMCPView.swift
//  learning
//
//  Created by macbook on 9/19/26.
//

import SwiftUI
import WebKit
import SwiftData

// MARK: - 🌐 Gemini.com Web & MCP Two-Way Bridge View
struct GeminiWebMCPView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var assistantService = MCPAIAssistantService.shared

    @State private var webView = WKWebView()
    @State private var lastExtractedText: String = ""
    @State private var showActionSuccessToast: Bool = false
    @State private var successToastMessage: String = ""
    @State private var isLoadingWeb: Bool = true

    dynamic var body: some View {
        NavigationStack {
            ZStack {
                Color.cartoonBg
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - 🛠️ Top MCP Quick Action Bar
                    mcpActionBar

                    // MARK: - 🌐 Gemini Webview Container
                    ZStack {
                        GeminiWKWebViewRepresentable(webView: $webView, isLoading: $isLoadingWeb)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.5))
                            .padding(.horizontal, HIGSpacing.xs)
                            .padding(.bottom, HIGSpacing.xs)

                        if isLoadingWeb {
                            VStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Menghubungkan ke gemini.google.com...")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.2))
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                        }
                    }
                }

                // MARK: - 🎉 Floating Success Toast
                if showActionSuccessToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.cartoonMint)
                            Text(successToastMessage)
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black, lineWidth: 2))
                        .shadow(color: .black, radius: 0, x: 3, y: 3)
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Gemini.com + MCP Bridge")
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

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        webView.reload()
                    } label: {
                        Image(systemName: "arrow.clockwise")
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
    }

    // MARK: - 🛠️ MCP Action Bar (Integrasi Aksi Nyata)
    private var mcpActionBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 1. Kirim Konteks Tugas Saat Ini ke Kolom Chat Gemini.com
                Button {
                    injectTodayContextIntoGeminiChat()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.doc.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("Kirim Data Jadwal ke Gemini")
                            .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.cartoonBlue)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                // 2. Eksekusi Jawaban Gemini Jadi Tugas MCP
                Button {
                    extractAndExecuteTaskFromGemini()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("⚡ Jadwalkan Hasil Gemini (MCP)")
                            .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.cartoonMint)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                // 3. Mulai Pomodoro Langsung
                Button {
                    PomodoroManager.shared.selectPreset(.quickFocus)
                    PomodoroManager.shared.startTimer()
                    showToast("⏱️ Sesi Pomodoro 25m Dimulai!")
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 11, weight: .bold))
                        Text("Mulai Fokus 25m")
                            .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.cartoonCoral)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
            .padding(.horizontal, HIGSpacing.md)
            .padding(.vertical, 8)
        }
        .background(Color.white)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.black.opacity(0.1)), alignment: .bottom)
    }

    // MARK: - 🧠 Two-Way Bridge Logic

    /// Menyalin ringkasan aktivitas app & memasukkannya langsung ke kotak ketik Gemini.com
    private func injectTodayContextIntoGeminiChat() {
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        let pending = items.filter { !$0.isCompleted }

        var prompt = "Halo Gemini! Ini konteks aktivitasku hari ini dari aplikasi:\\n"
        if pending.isEmpty {
            prompt += "- Belum ada tugas terjadwal.\\n"
        } else {
            for (i, it) in pending.prefix(5).enumerated() {
                prompt += "\(i+1). [\(it.category)] \(it.title)\\n"
            }
        }
        prompt += "\\nTolong berikan saran rencana produktivitas & subtasks yang perlu aku kerjakan!"

        let jsCode = """
        (function() {
            var textareas = document.querySelectorAll('textarea, div[contenteditable="true"], rich-textarea');
            if (textareas.length > 0) {
                var el = textareas[textareas.length - 1];
                if (el.tagName.toLowerCase() === 'textarea') {
                    el.value = "\(prompt)";
                    el.dispatchEvent(new Event('input', { bubbles: true }));
                } else {
                    el.innerText = "\(prompt)";
                    el.dispatchEvent(new Event('input', { bubbles: true }));
                }
                return "injected";
            }
            return "not_found";
        })();
        """

        webView.evaluateJavaScript(jsCode) { result, error in
            UIPasteboard.general.string = prompt.replacingOccurrences(of: "\\n", with: "\n")
            showToast("📋 Data jadwal siap ditempel di chat Gemini!")
            HapticManager.shared.success()
        }
    }

    /// Membaca jawaban respons terakhir dari Gemini.com dan otomatis menjadikannya Item SwiftData
    private func extractAndExecuteTaskFromGemini() {
        let extractJS = """
        (function() {
            var responses = document.querySelectorAll('.model-response-text, message-content, [data-test-id="model-response"]');
            if (responses.length > 0) {
                return responses[responses.length - 1].innerText;
            }
            return window.getSelection().toString() || document.body.innerText.substring(0, 500);
        })();
        """

        webView.evaluateJavaScript(extractJS) { result, error in
            let text = (result as? String) ?? ""
            guard !text.isEmpty else {
                showToast("⚠️ Belum ada respon yang terbaca dari Gemini")
                return
            }

            // Parsing baris teks untuk dijadikan subtasks & judul
            let lines = text.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && ($0.hasPrefix("1.") || $0.hasPrefix("2.") || $0.hasPrefix("3.") || $0.hasPrefix("4.") || $0.hasPrefix("-") || $0.hasPrefix("•") || $0.hasPrefix("*")) }

            let title = lines.first?.replacingOccurrences(of: "^[0-9]+[.\\s-]+", with: "", options: .regularExpression) ?? "Rencana dari Gemini.com"
            let subtaskItems = lines.prefix(4).map { line in
                let clean = line.replacingOccurrences(of: "^[0-9]+[.\\s-*•]+", with: "", options: .regularExpression)
                return SubtaskItem(title: clean, isCompleted: false)
            }

            let newItem = Item(
                title: title.isEmpty ? "Rencana Kerja Gemini" : title,
                notes: "Diekstrak otomatis dari percakapan gemini.google.com via MCP Bridge",
                timestamp: Date(),
                isCompleted: false,
                priority: "Tinggi",
                category: "Pekerjaan",
                subtasks: subtaskItems.isEmpty ? [SubtaskItem(title: "Langkah persiapan", isCompleted: false)] : Array(subtaskItems)
            )

            modelContext.insert(newItem)
            try? modelContext.save()

            HapticManager.shared.success()
            SoundManager.shared.playSuccessChime()
            showToast("✅ Berhasil dijadwalkan ke To-Do List!")
        }
    }

    private func showToast(_ msg: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            successToastMessage = msg
            showActionSuccessToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                showActionSuccessToast = false
            }
        }
    }
}

// MARK: - 📱 WKWebView Representable dengan Sesi Google
struct GeminiWKWebViewRepresentable: UIViewRepresentable {
    @Binding var webView: WKWebView
    @Binding var isLoading: Bool

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default() // Berbagi cookies/sesi Google
        config.allowsInlineMediaPlayback = true

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = context.coordinator
        wv.allowsBackForwardNavigationGestures = true

        if let url = URL(string: "https://gemini.google.com") {
            let request = URLRequest(url: url)
            wv.load(request)
        }

        DispatchQueue.main.async {
            self.webView = wv
        }
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: GeminiWKWebViewRepresentable

        init(_ parent: GeminiWKWebViewRepresentable) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
    }
}
