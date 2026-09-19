//
//  GeminiBackgroundWebBridge.swift
//  learning
//
//  Created by macbook on 9/19/26.
//

import SwiftUI
import WebKit
import Combine

// MARK: - 🧠 Background Gemini.com Engine Bridge
@MainActor
final class GeminiBackgroundBridgeManager: NSObject, ObservableObject {
    static let shared = GeminiBackgroundBridgeManager()

    @Published var isWebReady: Bool = false
    @Published var isBusy: Bool = false
    @Published var statusText: String = "Standby"

    var webView: WKWebView?

    override init() {
        super.init()
    }

    /// Mengirim prompt langsung ke mesin gemini.google.com di latar belakang dan mengembalikan teks jawabannya
    func sendPromptToGeminiWeb(_ prompt: String) async throws -> String {
        guard let wv = webView else {
            throw NSError(domain: "GeminiBridge", code: -1, userInfo: [NSLocalizedDescriptionKey: "Engine Gemini Web belum siap"])
        }

        self.isBusy = true
        self.statusText = "Mengirim pesan ke Gemini..."

        let escaped = prompt
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "")

        // 1. Injeksi teks ke textarea/rich-textarea gemini.google.com dan trigger submit
        let injectJS = """
        (function() {
            var target = document.querySelector('rich-textarea div[contenteditable="true"]') ||
                         document.querySelector('textarea.textarea') ||
                         document.querySelector('textarea') ||
                         document.querySelector('div[contenteditable="true"]');
            if (!target) return "NO_INPUT";

            target.focus();
            if (target.tagName.toLowerCase() === 'textarea') {
                target.value = "\(escaped)";
                target.dispatchEvent(new Event('input', { bubbles: true }));
                target.dispatchEvent(new Event('change', { bubbles: true }));
            } else {
                document.execCommand('selectAll', false, null);
                document.execCommand('insertText', false, "\(escaped)");
                target.dispatchEvent(new Event('input', { bubbles: true }));
            }

            setTimeout(function() {
                var btn = document.querySelector('button[aria-label*="Send"]') ||
                          document.querySelector('button[aria-label*="Kirim"]') ||
                          document.querySelector('.send-button') ||
                          document.querySelector('button.send-button-container');
                if (btn && !btn.disabled) {
                    btn.click();
                } else {
                    target.dispatchEvent(new KeyboardEvent('keydown', {
                        key: 'Enter',
                        code: 'Enter',
                        which: 13,
                        keyCode: 13,
                        bubbles: true
                    }));
                }
            }, 300);

            return "OK";
        })();
        """

        let res = try await wv.evaluateJavaScript(injectJS) as? String
        if res == "NO_INPUT" {
            self.isBusy = false
            throw NSError(domain: "GeminiBridge", code: 401, userInfo: [NSLocalizedDescriptionKey: "Input chat gemini.google.com tidak ditemukan"])
        }

        // 2. Tunggu dan ekstrak teks balasan dari Gemini
        return try await pollGeminiResponse(wv: wv)
    }

    private func pollGeminiResponse(wv: WKWebView) async throws -> String {
        self.statusText = "Menunggu balasan Gemini..."
        try? await Task.sleep(nanoseconds: 2_500_000_000)

        let extractJS = """
        (function() {
            var bubbles = document.querySelectorAll('message-content, .model-response-text, [data-test-id="model-response"], .response-container-content, div.markdown');
            if (bubbles.length > 0) {
                var last = bubbles[bubbles.length - 1];
                return last.innerText || last.textContent;
            }
            return "";
        })();
        """

        var previousText = ""
        var stableRounds = 0

        for _ in 0..<30 {
            try? await Task.sleep(nanoseconds: 500_000_000)

            if let current = try? await wv.evaluateJavaScript(extractJS) as? String {
                let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    if trimmed == previousText && trimmed.count > 10 {
                        stableRounds += 1
                        if stableRounds >= 3 {
                            self.isBusy = false
                            return trimmed
                        }
                    } else {
                        previousText = trimmed
                        stableRounds = 0
                    }
                }
            }
        }

        self.isBusy = false
        if !previousText.isEmpty {
            return previousText
        }

        throw NSError(domain: "GeminiBridge", code: 408, userInfo: [NSLocalizedDescriptionKey: "Timeout menunggu respons dari Gemini.com"])
    }
}

// MARK: - 👁️ Invisible Background Web Representable
struct InvisibleGeminiWebEngineView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default() // Share cookies / Google sessions
        config.allowsInlineMediaPlayback = true

        let wv = WKWebView(frame: CGRect(x: 0, y: 0, width: 375, height: 667), configuration: config)
        wv.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        wv.navigationDelegate = context.coordinator

        if let url = URL(string: "https://gemini.google.com/app") {
            wv.load(URLRequest(url: url))
        }

        DispatchQueue.main.async {
            GeminiBackgroundBridgeManager.shared.webView = wv
        }
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                GeminiBackgroundBridgeManager.shared.isWebReady = true
                GeminiBackgroundBridgeManager.shared.statusText = "Gemini AI Siap"
            }
        }
    }
}
