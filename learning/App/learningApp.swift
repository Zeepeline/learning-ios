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

    // Shared ModelContainer dengan dukungan App Group & iCloud CloudKit
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Habit.self,
        ])
        let appGroupIdentifier = "group.com.gmedia.xlearning"
        let cloudContainerId = "iCloud.com.gmedia.xlearning"
        
        // 1. Coba inisialisasi App Group Container dengan CloudKit
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let storeURL = containerURL.appendingPathComponent("learning.sqlite")
            let appGroupCloudConfig = ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .private(cloudContainerId)
            )
            if let container = try? ModelContainer(for: schema, configurations: [appGroupCloudConfig]) {
                return container
            }
            
            // 1b. Fallback App Group Container tanpa CloudKit (jika iCloud belum aktif / simulator offline)
            let appGroupLocalConfig = ModelConfiguration(schema: schema, url: storeURL)
            if let container = try? ModelContainer(for: schema, configurations: [appGroupLocalConfig]) {
                print("⚠️ Initialized local App Group container without CloudKit")
                return container
            }
        }
        
        // 2. Coba Default Local Storage dengan CloudKit
        let defaultCloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private(cloudContainerId)
        )
        if let container = try? ModelContainer(for: schema, configurations: [defaultCloudConfig]) {
            return container
        }

        // 3. Fallback Standard Local Storage
        let standardConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let container = try? ModelContainer(for: schema, configurations: [standardConfig]) {
            return container
        }

        // 4. In-Memory Container Darurat
        let inMemoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [inMemoryConfig])
        } catch {
            fatalError("Could not initialize any ModelContainer: \(error.localizedDescription)")
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
