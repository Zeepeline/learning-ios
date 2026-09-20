//
//  GeminiHeadlessEngine.swift
//  learning
//
//  Created by macbook on 9/19/26.
//

import Foundation
import WebKit
import SwiftUI
import Combine

// MARK: - 🌐 Gemini.com Background Headless Bridge
/// Jembatan webview tersembunyi yang menghubungkan UI Chat Native aplikasi
/// dengan gemini.google.com tanpa perlu API Key, memanfaatkan akun Google pengguna.
@MainActor
final class GeminiHeadlessEngine: NSObject, ObservableObject {
    static let shared = GeminiHeadlessEngine()

    @Published var isReady: Bool = false
    @Published var isGenerating: Bool = false
    @Published var lastError: String? = nil
    @Published var isLoggedIn: Bool = false

    private var webView: WKWebView?
    private var responseContinuation: CheckedContinuation<String, Error>?
    private var pollTimer: Timer?
    private var lastExtractedLength: Int = 0
    private var stableCount: Int = 0

    private override init() {
        super.init()
        setupHeadlessWebView()
    }

    func setupHeadlessWebView() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default() // Berbagi cookies akun Google
        config.allowsInlineMediaPlayback = true

        let userContent = WKUserContentController()
        config.userContentController = userContent

        let wv = WKWebView(frame: CGRect(x: 0, y: 0, width: 375, height: 667), configuration: config)
        wv.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        wv.navigationDelegate = self

        self.webView = wv

        if let url = URL(string: "https://gemini.google.com/app") {
            wv.load(URLRequest(url: url))
        }
    }

    /// Cek apakah pengguna sudah login di gemini.google.com
    func checkLoginStatus() async -> Bool {
        guard let wv = webView else { return false }
        let js = """
        (function() {
            var url = window.location.href;
            if (url.includes("accounts.google.com")) return false;
            var textareas = document.querySelectorAll('textarea, rich-textarea, div[contenteditable="true"], .ql-editor');
            return textareas.length > 0;
        })();
        """
        if let result = try? await wv.evaluateJavaScript(js) as? Bool {
            self.isLoggedIn = result
            return result
        }
        return false
    }

    /// Kirim pesan dari UI native ke gemini.google.com dan ekstrak balasannya
    func queryGemini(prompt: String) async throws -> String {
        guard let wv = webView else {
            throw NSError(domain: "GeminiEngine", code: -1, userInfo: [NSLocalizedDescriptionKey: "WebView belum siap"])
        }

        self.isGenerating = true
        self.lastError = nil

        // 1. Injeksi teks dan tekan tombol kirim di gemini.google.com
        let escapedPrompt = prompt
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "")

        let injectionScript = """
        (function() {
            var input = document.querySelector('rich-textarea div[contenteditable="true"]') ||
                        document.querySelector('textarea.textarea') ||
                        document.querySelector('textarea') ||
                        document.querySelector('div[contenteditable="true"]');
            if (!input) return "INPUT_NOT_FOUND";

            // Injeksi teks
            if (input.tagName.toLowerCase() === 'textarea') {
                input.value = "\(escapedPrompt)";
                input.dispatchEvent(new Event('input', { bubbles: true }));
                input.dispatchEvent(new Event('change', { bubbles: true }));
            } else {
                input.focus();
                document.execCommand('selectAll', false, null);
                document.execCommand('insertText', false, "\(escapedPrompt)");
                input.dispatchEvent(new Event('input', { bubbles: true }));
            }

            // Tekan tombol kirim
            setTimeout(function() {
                var sendBtn = document.querySelector('button[aria-label*="Send"]') ||
                              document.querySelector('button[aria-label*="Kirim"]') ||
                              document.querySelector('.send-button') ||
                              document.querySelector('button.send-button-container');
                if (sendBtn && !sendBtn.disabled) {
                    sendBtn.click();
                } else {
                    var enterEvent = new KeyboardEvent('keydown', {
                        key: 'Enter',
                        code: 'Enter',
                        which: 13,
                        keyCode: 13,
                        bubbles: true
                    });
                    input.dispatchEvent(enterEvent);
                }
            }, 300);

            return "INJECTED";
        })();
        """

        let injectResult = try await wv.evaluateJavaScript(injectionScript) as? String
        if injectResult == "INPUT_NOT_FOUND" {
            self.isGenerating = false
            throw NSError(domain: "GeminiEngine", code: 401, userInfo: [NSLocalizedDescriptionKey: "Sesi login gemini.google.com belum aktif. Silakan login terlebih dahulu."])
        }

        // 2. Tunggu respon selesai di-generate (polling DOM)
        return try await waitForResponse(wv: wv)
    }

    private func waitForResponse(wv: WKWebView) async throws -> String {
        let maxAttempts = 35
        var attempts = 0
        var previousText = ""
        var unchangedCount = 0

        // Tunggu respon mulai muncul
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        let extractScript = """
        (function() {
            var responses = document.querySelectorAll('message-content, .model-response-text, [data-test-id="model-response"], .response-container-content, div.markdown');
            if (responses.length > 0) {
                var last = responses[responses.length - 1];
                return last.innerText || last.textContent;
            }
            return "";
        })();
        """

        while attempts < maxAttempts {
            attempts += 1
            try? await Task.sleep(nanoseconds: 600_000_000)

            if let currentText = try? await wv.evaluateJavaScript(extractScript) as? String,
               !currentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {

                let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

                // Jika panjang teks sudah stabil selama 3 kali berturut-turut, berarti Gemini selesai menjawab
                if trimmed == previousText && trimmed.count > 10 {
                    unchangedCount += 1
                    if unchangedCount >= 3 {
                        self.isGenerating = false
                        return trimmed
                    }
                } else {
                    previousText = trimmed
                    unchangedCount = 0
                }
            }
        }

        self.isGenerating = false
        if !previousText.isEmpty {
            return previousText
        }
        throw NSError(domain: "GeminiEngine", code: 408, userInfo: [NSLocalizedDescriptionKey: "Waktu tunggu jawaban Gemini habis."])
    }
}

// MARK: - 🌐 WKNavigationDelegate
extension GeminiHeadlessEngine: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        Task {
            _ = await checkLoginStatus()
            self.isReady = true
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: Error) {
        self.lastError = error.localizedDescription
    }
}
