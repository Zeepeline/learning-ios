//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitor
//
//  Created by macbook on 9/5/26.
//

import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

// MARK: - Activity & Event Names
extension DeviceActivityName {
    static let dailyLimitActivity = Self("dailyLimitActivity")
}

extension DeviceActivityEvent.Name {
    static let dailyLimitThresholdEvent = Self("dailyLimitThresholdEvent")
}

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()
    private let sharedDefaults = UserDefaults(suiteName: "group.com.gmedia.xlearning")

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        // Reset shield di awal interval harian (00:00 tengah malam)
        if activity == .dailyLimitActivity {
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            sharedDefaults?.set(false, forKey: "isDailyLimitReached")
        }
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        // Terjadi seketika saat durasi akumulasi pemakaian mencapai batas yang ditentukan
        if event == .dailyLimitThresholdEvent {
            if let data = sharedDefaults?.data(forKey: "ScreenTimeActivitySelection"),
               let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                
                store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
                store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
                
                sharedDefaults?.set(true, forKey: "isDailyLimitReached")
            }
        }
    }
}
