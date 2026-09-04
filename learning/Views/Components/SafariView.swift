//
//  SafariView.swift
//  learning
//
//  Created by macbook on 9/3/26.
//

import SwiftUI
import SafariServices

// MARK: - 🌐 SafariView (In-App Browser / Custom Tab)
/// Wrapper SFSafariViewController untuk membuka halaman web di dalam aplikasi
/// yang langsung terhubung dengan sesi, autofill, dan cookies dari Safari utama.
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    var tintColor: Color = .black
    var entersReaderIfAvailable: Bool = false
    var dismissButtonStyle: SFSafariViewController.DismissButtonStyle = .done

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = entersReaderIfAvailable
        configuration.barCollapsingEnabled = true

        let safariVC = SFSafariViewController(url: url, configuration: configuration)
        safariVC.preferredControlTintColor = UIColor(tintColor)
        safariVC.dismissButtonStyle = dismissButtonStyle
        return safariVC
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - 🛠️ View Modifiers & Extensions untuk Kemudahan Penggunaan
extension View {
    /// Menampilkan Safari In-App Browser menggunakan binding URL opsional
    func safariSheet(url: Binding<URL?>, tintColor: Color = .black) -> some View {
        self.sheet(isPresented: Binding(
            get: { url.wrappedValue != nil },
            set: { if !$0 { url.wrappedValue = nil } }
        )) {
            if let targetURL = url.wrappedValue {
                SafariView(url: targetURL, tintColor: tintColor)
                    .ignoresSafeArea()
            }
        }
    }

    /// Menampilkan Safari In-App Browser menggunakan boolean trigger dan URL tetap
    func safariSheet(isPresented: Binding<Bool>, url: URL, tintColor: Color = .black) -> some View {
        self.sheet(isPresented: isPresented) {
            SafariView(url: url, tintColor: tintColor)
                .ignoresSafeArea()
        }
    }
}

// MARK: - 🚀 URL Launcher Helper
enum URLLauncher {
    /// Membuka URL di browser eksternal sistem (Safari / Chrome default pengguna)
    @MainActor
    static func openExternal(_ urlString: String) {
        guard let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) else {
            print("URLLauncher: URL tidak valid atau tidak dapat dibuka: \(urlString)")
            return
        }
        UIApplication.shared.open(url)
    }

    /// Membuka URL di browser eksternal sistem dengan objek URL
    @MainActor
    static func openExternal(_ url: URL) {
        guard UIApplication.shared.canOpenURL(url) else {
            print("URLLauncher: URL tidak dapat dibuka: \(url.absoluteString)")
            return
        }
        UIApplication.shared.open(url)
    }
}
