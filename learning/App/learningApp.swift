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

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
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
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isLoggedIn)
        }
        .modelContainer(sharedModelContainer)
    }
}
