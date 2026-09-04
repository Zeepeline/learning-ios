//
//  learningApp.swift
//  learning
//
//  Created by macbook on 8/29/26.
//

import SwiftUI
import SwiftData
import WidgetKit
import GoogleSignIn

@main
struct learningApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = true

    // Shared ModelContainer untuk sinkronisasi data dengan Widget Extension via App Group
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let appGroupIdentifier = "group.com.irmintul.learning"
        
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let storeURL = containerURL.appendingPathComponent("learning.sqlite")
            let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                print("Failed to initialize App Group database: \(error.localizedDescription)")
            }
        }
        
        let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [fallbackConfig])
        } catch {
            fatalError("Could not create ModelContainer: \(error.localizedDescription)")
        }
    }()

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
            .onOpenURL { url in
                // ⬅️ Handle redirect callback login dari Google SDK di semua screen
                GIDSignIn.sharedInstance.handle(url)
            }
            .onAppear {
                // Inisialisasi Izin Notifikasi Sistem & Refresh Widget
                NotificationManager.shared.requestAuthorization()
                WidgetCenter.shared.reloadAllTimelines()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background || newPhase == .inactive {
                    try? sharedModelContainer.mainContext.save()
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
