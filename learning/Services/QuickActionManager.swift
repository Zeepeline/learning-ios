//
//  QuickActionManager.swift
//  learning
//
//  Created by macbook on 9/6/26.
//

import UIKit
import SwiftUI
import Observation

// MARK: - ⚡ Quick Action Types dari Info.plist
enum QuickActionType: String {
    case newTask = "com.gmedia.learning.newTask"
    case startPomodoro = "com.gmedia.learning.startPomodoro"
}

// MARK: - ⚡ Quick Action Manager (Mengatur Deep Link Aksi Cepat Ikon Home Screen)
@Observable
@MainActor
final class QuickActionManager {
    static let shared = QuickActionManager()
    
    var selectedTab: Int = 0
    var isShowingAddActivity: Bool = false
    
    private init() {}
    
    /// Menangani item shortcut yang ditekan pengguna di Home Screen
    func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
        HapticManager.shared.impact(style: .medium)
        
        switch shortcutItem.type {
        case QuickActionType.newTask.rawValue:
            // Pindah ke tab jadwal dan langsung tampilkan lembar Tambah Aktivitas
            self.selectedTab = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.isShowingAddActivity = true
            }
            
        case QuickActionType.startPomodoro.rawValue:
            // Langsung arahkan ke Tab 3 (Fokus Hub / Pomodoro)
            self.isShowingAddActivity = false
            self.selectedTab = 3
            
        default:
            break
        }
    }
}

// MARK: - 📱 App Delegate & Scene Delegate untuk Menangkap Shortcut
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // Tangkap shortcut saat cold start (aplikasi dibuka dari keadaan mati)
        if let shortcutItem = options.shortcutItem {
            Task { @MainActor in
                QuickActionManager.shared.handleShortcutItem(shortcutItem)
            }
        }
        
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        // Tangkap shortcut saat hot start (aplikasi sedang berjalan di background)
        Task { @MainActor in
            QuickActionManager.shared.handleShortcutItem(shortcutItem)
            completionHandler(true)
        }
    }
}
