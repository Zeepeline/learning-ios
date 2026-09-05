//
//  device_activity_report.swift
//  DeviceActivityReportExtension
//
//  Created by macbook on 9/5/26.
//

import DeviceActivity
import ExtensionKit
import SwiftUI

@main
struct DeviceActivityReportMain: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        // Create a report for each DeviceActivityReport.Context that your app supports.
        TotalActivityReport { totalActivity in
            TotalActivityView(totalActivity: totalActivity)
        }
        // Add more reports here...
    }
}
