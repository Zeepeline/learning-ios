//
//  AppShortcutsProvider.swift
//  learning
//
//  Created by macbook on 9/6/26.
//

import AppIntents

// MARK: - 🗣️ Provider Frasa Suara Siri & Apple Shortcuts
struct LearningShortcutsProvider: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .orange

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: [
                "Tambah tugas di \(.applicationName)",
                "Catat tugas di \(.applicationName)",
                "Tambah aktivitas di \(.applicationName)",
                "Catat aktivitas di \(.applicationName)",
                "Buat jadwal di \(.applicationName)",
                "Add task in \(.applicationName)",
                "Create task in \(.applicationName)"
            ],
            shortTitle: "Tambah Tugas",
            systemImageName: "plus.circle.fill"
        )
    }
}
