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
        TotalActivityReport { reportData in
            TotalActivityView(reportData: reportData)
        }
    }
}
