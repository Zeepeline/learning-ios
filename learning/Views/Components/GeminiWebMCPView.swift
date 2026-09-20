//
//  GeminiWebMCPView.swift
//  learning
//
//  Created by macbook on 9/19/26.
//

import SwiftUI
import WebKit

struct GeminiWebMCPView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var headlessEngine = GeminiHeadlessEngine.shared

    @State private var webURLString: String = "https://gemini.google.com/app"
    @State private var canGoBack: Bool = false
    @State private var canGoForward: Bool = false
    @State private var isLoading: Bool = true
    @State private var pageTitle: String = "Google Gemini"
    @State private var reloadTrigger: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cartoonBg
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Status Banner
                    HStack(spacing: 8) {
                        Circle()
                            .fill(headlessEngine.isLoggedIn ? Color.cartoonMint : Color.cartoonYellow)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(Color.black, lineWidth: 1.0))

                        Text(headlessEngine.isLoggedIn ? "Sesi Gemini Terhubung (Mode Gratis Aktif)" : "Silakan Login Akun Google Anda")
                            .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)

                        Spacer()

                        Button {
                            HapticManager.shared.impact(style: .light)
                            reloadTrigger.toggle()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .overlay(Rectangle().frame(height: 1.2).foregroundColor(.black), alignment: .bottom)

                    // WebView Container
                    GeminiWKWebViewRepresentable(
                        urlString: webURLString,
                        canGoBack: $canGoBack,
                        canGoForward: $canGoForward,
                        isLoading: $isLoading,
                        pageTitle: $pageTitle,
                        reloadTrigger: $reloadTrigger
                    )
                }
            }
            .navigationTitle("Login Akun Google Gemini")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CartoonIconButton(icon: "xmark") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.shared.success()
                        Task {
                            _ = await headlessEngine.checkLoginStatus()
                            dismiss()
                        }
                    } label: {
                        Text("Selesai")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.cartoonYellow)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
                    }
                }
            }
        }
    }
}

// MARK: - 🌐 Interactive WKWebView Representable
struct GeminiWKWebViewRepresentable: UIViewRepresentable {
    let urlString: String
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool
    @Binding var pageTitle: String
    @Binding var reloadTrigger: Bool

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default() // Berbagi session cookies
        config.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        webView.navigationDelegate = context.coordinator

        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if reloadTrigger != context.coordinator.lastReloadTrigger {
            context.coordinator.lastReloadTrigger = reloadTrigger
            uiView.reload()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: GeminiWKWebViewRepresentable
        var lastReloadTrigger: Bool = false

        init(_ parent: GeminiWKWebViewRepresentable) {
            self.parent = parent
            self.lastReloadTrigger = parent.reloadTrigger
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation?) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
    }
}
