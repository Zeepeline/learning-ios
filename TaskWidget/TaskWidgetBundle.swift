//
//  TaskWidgetBundle.swift
//  TaskWidget
//
//  Created by macbook on 9/3/26.
//

import WidgetKit
import SwiftUI

@main
struct TaskWidgetBundle: WidgetBundle {
    var body: some Widget {
        TaskWidget()
        TaskWidgetLiveActivity()
    }
}
