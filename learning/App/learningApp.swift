//
//  learningApp.swift
//  learning
//
//  Created by macbook on 8/29/26.
//

import AppIntents
import GoogleSignIn
import SwiftData
import SwiftUI
import WidgetKit

@main
struct learningApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = true

    let sharedModelContainer: ModelContainer

    init() {
        self.sharedModelContainer = Self.createModelContainer()
    }

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
                Task {
                    await NotificationManager.shared.requestAuthorization()
                }
                WidgetCenter.shared.reloadAllTimelines()

                // Daftarkan Pintasan Suara Siri ke Sistem iOS
                LearningShortcutsProvider.updateAppShortcutParameters()
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

    // MARK: - ModelContainer Setup & Fallbacks

    private static func createModelContainer() -> ModelContainer {
        let schema = Schema([
            Item.self,
            Habit.self,
        ])
        let appGroupIdentifier = "group.com.gmedia.xlearning"

        // 1. Coba inisialisasi App Group Shared Container
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let storeURL = containerURL.appendingPathComponent("learning.sqlite")
            let config = ModelConfiguration(schema: schema, url: storeURL)

            if let container = try? ModelContainer(for: schema, configurations: [config]) {
                if isContainerHealthy(container) {
                    return container
                } else {
                    print("⚠️ SQLite lama tidak memiliki tabel baru (ZHABIT). Memulihkan database...")
                    cleanCorruptStore(at: containerURL)
                    if let freshContainer = try? ModelContainer(for: schema, configurations: [config]),
                       isContainerHealthy(freshContainer)
                    {
                        print("✅ Berhasil membuat ulang SQLite database dengan skema lengkap (Item & Habit).")
                        return freshContainer
                    }
                }
            } else {
                cleanCorruptStore(at: containerURL)
                if let freshContainer = try? ModelContainer(for: schema, configurations: [config]) {
                    return freshContainer
                }
            }
        }

        // 2. Fallback Standard Local Storage
        let standardConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let container = try? ModelContainer(for: schema, configurations: [standardConfig]),
           isContainerHealthy(container)
        {
            return container
        }

        // 3. In-Memory Container Darurat
        let inMemoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [inMemoryConfig])
        } catch {
            fatalError("Could not initialize any ModelContainer: \(error.localizedDescription)")
        }
    }

    private static func cleanCorruptStore(at containerURL: URL) {
        let fileManager = FileManager.default
        let storeURL = containerURL.appendingPathComponent("learning.sqlite")
        let shmURL = containerURL.appendingPathComponent("learning.sqlite-shm")
        let walURL = containerURL.appendingPathComponent("learning.sqlite-wal")
        try? fileManager.removeItem(at: storeURL)
        try? fileManager.removeItem(at: shmURL)
        try? fileManager.removeItem(at: walURL)
    }

    @MainActor
    private static func isContainerHealthy(_ container: ModelContainer) -> Bool {
        let context = ModelContext(container)
        do {
            _ = try context.fetch(FetchDescriptor<Item>())
            _ = try context.fetch(FetchDescriptor<Habit>())
            return true
        } catch {
            print("⚠️ SwiftData health probe failed: \(error.localizedDescription)")
            return false
        }
    }
}
