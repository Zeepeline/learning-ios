//
//  GeminiBackgroundWebBridge.swift
//  learning
//
//  Created by macbook on 9/19/26.
//

import SwiftUI
import WebKit
import Combine

// MARK: - 🤖 Gemini Background Bridge Manager
@MainActor
final class GeminiBackgroundBridgeManager: ObservableObject {
    static let shared = GeminiBackgroundBridgeManager()

    @Published var isBridgeReady: Bool = false
    @Published var isProcessing: Bool = false
    @Published var statusText: String = "Memuat AI Bridge..."
    @Published var lastResponseText: String = ""

    weak var activeWebView: WKWebView?

    private init() {}

    func executePrompt(prompt: String) async -> String {
        guard let webView = activeWebView else {
            return "⚠️ WebView bridge belum siap. Silakan buka tab Pengaturan AI."
        }

        self.isProcessing = true
        self.statusText = "Mengirim prompt ke Gemini..."

        let escaped = prompt
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")

        let js = """
        (function() {
            var input = document.querySelector('rich-textarea div[contenteditable="true"]') ||
                        document.querySelector('textarea');
            if (!input) return "INPUT_NOT_FOUND";

            input.focus();
            document.execCommand('selectAll', false, null);
            document.execCommand('insertText', false, "\(escaped)");
            input.dispatchEvent(new Event('input', { bubbles: true }));

            setTimeout(function() {
                var btn = document.querySelector('button[aria-label*="Send"]') ||
                          document.querySelector('button[aria-label*="Kirim"]') ||
                          document.querySelector('.send-button');
                if (btn && !btn.disabled) {
                    btn.click();
                }
            }, 250);

            return "OK";
        })();
        """

        _ = try? await webView.evaluateJavaScript(js)

        // Polling response
        var resultText = ""
        var attempts = 0
        while attempts < 25 {
            attempts += 1
            try? await Task.sleep(nanoseconds: 600_000_000)

            let pollJS = """
            (function() {
                var responses = document.querySelectorAll('message-content, .model-response-text, [data-test-id="model-response"]');
                if (responses.length > 0) {
                    var last = responses[responses.length - 1];
                    return last.innerText || last.textContent;
                }
                return "";
            })();
            """

            if let text = try? await webView.evaluateJavaScript(pollJS) as? String,
               !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if text == resultText && text.count > 10 {
                    break
                }
                resultText = text
            }
        }

        self.isProcessing = false
        self.statusText = "Selesai"
        self.lastResponseText = resultText
        return resultText.isEmpty ? "Tidak ada respon dari Gemini." : resultText
    }
}

// MARK: - 🌐 Background WKWebView SwiftUI Container
struct GeminiBackgroundWebViewRepresentable: UIViewRepresentable {
    @ObservedObject var bridgeManager = GeminiBackgroundBridgeManager.shared

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default() // Share cookies with Safari/Google Login
        config.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        webView.navigationDelegate = context.coordinator

        bridgeManager.activeWebView = webView

        if let url = URL(string: "https://gemini.google.com/app") {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
            Task { @MainActor in
                GeminiBackgroundBridgeManager.shared.isBridgeReady = true
                GeminiBackgroundBridgeManager.shared.statusText = "Engine Siap"
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: Error) {
            Task { @MainActor in
                GeminiBackgroundBridgeManager.shared.statusText = "Gagal memuat engine"
            }
        }
    }
}

// MARK: - 👁️ Invisible Gemini Web Engine View
struct InvisibleGeminiWebEngineView: View {
    var body: some View {
        GeminiBackgroundWebViewRepresentable()
    }
}
