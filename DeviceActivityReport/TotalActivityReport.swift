//
//  TotalActivityReport.swift
//  DeviceActivityReportExtension
//
//  Created by macbook on 9/5/26.
//

import DeviceActivity
import ExtensionKit
import SwiftUI

extension DeviceActivityReport.Context {
    // If your app initializes a DeviceActivityReport with this context, then the system will use
    // your extension's corresponding DeviceActivityReportScene to render the contents of the
    // report.
    static let totalActivity = Self("Total Activity")
}

struct TotalActivityReport: DeviceActivityReportScene {
    // Define which context your scene will represent.
    let context: DeviceActivityReport.Context = .totalActivity
    
    // Define the custom configuration and the resulting view for this report.
    let content: (String) -> TotalActivityView
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> String {
        // Reformat the data into a configuration that can be used to create
        // the report's view.
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        formatter.zeroFormattingBehavior = .dropAll
        
        var totalActivityDuration: TimeInterval = 0
        
        for await activityData in data {
            for await segment in activityData.activitySegments {
                totalActivityDuration += segment.totalActivityDuration
            }
        }
        
        if totalActivityDuration <= 0 {
            return "0 Menit (Belum ada aktivitas tercatat)"
        }
        
        return formatter.string(from: totalActivityDuration) ?? "0 Menit"
    }
}
