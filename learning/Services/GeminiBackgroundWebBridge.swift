//
//  GeminiBackgroundWebBridge.swift
//  learning
//
//  Created by macbook on 9/19/26.
//

import Foundation
import WebKit
import SwiftUI
import Combine

// MARK: - 🌐 Gemini Background Bridge Manager (Headless WebKit Engine)
@MainActor
final class GeminiBackgroundBridgeManager: ObservableObject {
    static let shared = GeminiBackgroundBridgeManager()

    @Published var isBridgeReady: Bool = false
    @Published var isBusy: Bool = false
    @Published var statusText: String = "Engine Siap"
    @Published var lastExtractedText: String = ""

    weak var webView: WKWebView? = nil

    private init() {}

    /// Injeksi prompt ke chat box gemini.google.com dan ekstrak responsenya secara headless
    func sendPromptToGeminiWeb(_ prompt: String) async throws -> String {
        guard let wv = webView else {
            throw NSError(domain: "GeminiBridge", code: 404, userInfo: [NSLocalizedDescriptionKey: "WebView engine belum siap"])
        }

        self.isBusy = true
        self.statusText = "Mengirim prompt..."

        let escaped = prompt
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "")

        // 1. Injeksi prompt teks ke editor gemini.google.com
        let injectJS = """
        (function() {
            var target = document.querySelector('rich-textarea div[contenteditable="true"]') ||
                         document.querySelector('textarea') ||
                         document.querySelector('input[type="text"]') ||
                         document.querySelector('.ql-editor');

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

        // 2. Tunggu dan ekstrak teks balasan dari Gemini dengan mempertahankan struktur list & spasi
        return try await pollGeminiResponse(wv: wv)
    }

    private func pollGeminiResponse(wv: WKWebView) async throws -> String {
        self.statusText = "Menunggu balasan AI..."
        try? await Task.sleep(nanoseconds: 2_500_000_000)

        // JavaScript ekstraktor cerdas yang mempertahankan paragraf, enter, dan format list <li> / <br>
        let extractJS = """
        (function() {
            var bubbles = document.querySelectorAll('message-content, .model-response-text, [data-test-id="model-response"], .response-container-content, div.markdown');
            if (bubbles.length > 0) {
                var last = bubbles[bubbles.length - 1];
                var clone = last.cloneNode(true);

                // Format <br> jadi enter baru
                clone.querySelectorAll('br').forEach(function(el) {
                    var textNode = document.createTextNode('\\n');
                    el.parentNode.replaceChild(textNode, el);
                });

                // Format <li> jadi poin list
                clone.querySelectorAll('li').forEach(function(el) {
                    el.prepend(document.createTextNode('\\n• '));
                });

                // Format heading & paragraf dengan jarak spasi
                clone.querySelectorAll('p, h1, h2, h3, h4, h5, h6').forEach(function(el) {
                    el.append(document.createTextNode('\\n\\n'));
                });

                return clone.innerText || clone.textContent || "";
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

        throw NSError(domain: "GeminiBridge", code: 408, userInfo: [NSLocalizedDescriptionKey: "Timeout menunggu respons dari engine AI"])
    }
}

// MARK: - 👁️ Invisible Background Web Representable
struct InvisibleGeminiWebEngineView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        config.allowsInlineMediaPlayback = true

        let wv = WKWebView(frame: CGRect(x: 0, y: 0, width: 375, height: 667), configuration: config)
        wv.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        wv.navigationDelegate = context.coordinator

        GeminiBackgroundBridgeManager.shared.webView = wv

        if let url = URL(string: "https://gemini.google.com/app") {
            let req = URLRequest(url: url)
            wv.load(req)
        }

        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                GeminiBackgroundBridgeManager.shared.isBridgeReady = true
                GeminiBackgroundBridgeManager.shared.statusText = "Engine Siap"
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                GeminiBackgroundBridgeManager.shared.statusText = "Gagal memuat engine"
            }
        }
    }
}
