//
//  learningApp.swift
//  learning
//
//  Created by macbook on 8/29/26.
//

import SwiftUI
import SwiftData

@main
struct learningApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = true

    var body: some Scene {
        WindowGroup {
            Group {
                if isLoggedIn {
                    ContentView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)),
                            removal: .opacity
                        ))
                } else {
                    LoginView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 1.02)),
                            removal: .opacity
                        ))
                }
            }
            .preferredColorScheme(.light)
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isLoggedIn)
            .onAppear {
                // Inisialisasi Izin Notifikasi Sistem
                NotificationManager.shared.requestAuthorization()
            }
        }
        
        .modelContainer(for: Item.self)
    }
}
