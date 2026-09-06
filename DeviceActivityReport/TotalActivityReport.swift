//
//  TotalActivityReport.swift
//  DeviceActivityReportExtension
//
//  Created by macbook on 9/5/26.
//

import DeviceActivity
import ExtensionKit
import SwiftUI
import ManagedSettings

extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}

// Model data laporan aktivitas aplikasi target
struct AppUsageItem: Identifiable, Hashable {
    var id: String { token?.hashValue.description ?? name }
    let token: ApplicationToken?
    let name: String
    let duration: TimeInterval
}

struct AppActivityReportData {
    let totalTargetDuration: TimeInterval
    let appItems: [AppUsageItem]
    let formattedTotal: String
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    
    // View renderer
    let content: (AppActivityReportData) -> TotalActivityView
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> AppActivityReportData {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        formatter.zeroFormattingBehavior = .dropAll
        
        var appDurationMap: [ApplicationToken: (name: String, duration: TimeInterval)] = [:]
        var totalTargetDuration: TimeInterval = 0
        
        for await activityData in data {
            for await segment in activityData.activitySegments {
                for await categoryActivity in segment.categories {
                    for await appActivity in categoryActivity.applications {
                        let duration = appActivity.totalActivityDuration
                        if duration > 0 {
                            totalTargetDuration += duration
                            if let token = appActivity.application.token {
                                let appName = appActivity.application.localizedDisplayName ?? (appActivity.application.bundleIdentifier ?? "")
                                if let existing = appDurationMap[token] {
                                    let chosenName = !appName.isEmpty ? appName : existing.name
                                    appDurationMap[token] = (chosenName, existing.duration + duration)
                                } else {
                                    appDurationMap[token] = (appName, duration)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        let appItems = appDurationMap.map { token, value in
            AppUsageItem(token: token, name: value.name, duration: value.duration)
        }.sorted { $0.duration > $1.duration }
        
        let formattedTotal = totalTargetDuration > 0
            ? (formatter.string(from: totalTargetDuration) ?? "\(Int(totalTargetDuration / 60)) Menit")
            : "0 Menit"
        
        return AppActivityReportData(
            totalTargetDuration: totalTargetDuration,
            appItems: appItems,
            formattedTotal: formattedTotal
        )
    }
}
