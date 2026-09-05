//
//  PomodoroAttributes.swift
//  TaskWidget
//
//  Created by macbook on 9/5/26.
//

import Foundation
@preconcurrency import ActivityKit

public struct PomodoroAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        public var endTime: Date
        public var isPaused: Bool
        public var isBreak: Bool
        public var sessionTitle: String
        public var totalDurationSeconds: Double
        public var remainingSecondsWhenPaused: Double

        public init(
            endTime: Date,
            isPaused: Bool = false,
            isBreak: Bool = false,
            sessionTitle: String = "Sesi Fokus",
            totalDurationSeconds: Double = 25 * 60,
            remainingSecondsWhenPaused: Double = 0
        ) {
            self.endTime = endTime
            self.isPaused = isPaused
            self.isBreak = isBreak
            self.sessionTitle = sessionTitle
            self.totalDurationSeconds = totalDurationSeconds
            self.remainingSecondsWhenPaused = remainingSecondsWhenPaused
        }
    }

    public var taskName: String
    public var categoryIcon: String

    public init(taskName: String = "Fokus Belajar", categoryIcon: String = "timer") {
        self.taskName = taskName
        self.categoryIcon = categoryIcon
    }
}
