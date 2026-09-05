//
//  TaskWidgetLiveActivity.swift
//  TaskWidget
//
//  Created by macbook on 9/3/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TaskWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroAttributes.self) { context in
            // MARK: - Lock Screen & StandBy Mode Banner
            HStack(spacing: 12) {
                // 1. Icon Badge Kartun
                ZStack {
                    Circle()
                        .fill(context.state.isBreak ? Color(red: 0.84, green: 0.95, blue: 0.84) : Color(red: 0.99, green: 0.88, blue: 0.55))
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.8))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)

                    Image(systemName: context.attributes.categoryIcon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                }

                // 2. Info Sesi & Nama Tugas
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(context.state.isBreak ? "WAKTU ISTIRAHAT" : "MODE FOKUS")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(context.state.isBreak ? Color(red: 0.84, green: 0.95, blue: 0.84) : Color(red: 1.0, green: 0.72, blue: 0.45))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.black, lineWidth: 1))

                        if context.state.isPaused {
                            Text("DIJEDA")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .foregroundColor(.red)
                        }
                    }

                    Text(context.attributes.taskName)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .lineLimit(1)
                }

                Spacer()

                // 3. Countdown Timer Otomatis
                VStack(alignment: .trailing, spacing: 2) {
                    if context.state.isPaused {
                        let mins = Int(context.state.remainingSecondsWhenPaused) / 60
                        let secs = Int(context.state.remainingSecondsWhenPaused) % 60
                        Text(String(format: "%02d:%02d", mins, secs))
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(.black)
                    } else {
                        Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.trailing)
                    }

                    Text("Sisa Waktu")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.black.opacity(0.6))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.4))
                .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
            }
            .padding(14)
            .background(Color(red: 0.98, green: 0.96, blue: 0.92))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black, lineWidth: 2))
            .activityBackgroundTint(Color(red: 0.98, green: 0.96, blue: 0.92))
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            // MARK: - Dynamic Island
            DynamicIsland {
                // Expanded Leading
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: context.attributes.categoryIcon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(context.attributes.taskName)
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(context.state.isBreak ? "Istirahat" : "Fokus")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(context.state.isBreak ? .green : .orange)
                        }
                    }
                    .padding(.leading, 4)
                }

                // Expanded Trailing
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 1) {
                        if context.state.isPaused {
                            let mins = Int(context.state.remainingSecondsWhenPaused) / 60
                            let secs = Int(context.state.remainingSecondsWhenPaused) % 60
                            Text(String(format: "%02d:%02d", mins, secs))
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundColor(.yellow)
                        } else {
                            Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.trailing)
                        }
                        Text(context.state.isPaused ? "Dijeda" : "Berjalan")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 4)
                }

                // Expanded Bottom
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Label(
                            context.state.isBreak ? "Nikmati jeda sejenak" : "Mode pengunci aplikasi aktif",
                            systemImage: context.state.isBreak ? "cup.and.saucer.fill" : "shield.fill"
                        )
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))

                        Spacer()

                        Text(context.state.sessionTitle)
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow)
                            .cornerRadius(4)
                    }
                    .padding(.horizontal, 6)
                    .padding(.top, 4)
                }
            } compactLeading: {
                HStack(spacing: 3) {
                    Image(systemName: context.attributes.categoryIcon)
                        .font(.system(size: 12, weight: .bold))
                }
            } compactTrailing: {
                if context.state.isPaused {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 11, weight: .bold))
                } else {
                    Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(context.state.isBreak ? .green : .orange)
                        .frame(width: 44)
                }
            } minimal: {
                Image(systemName: context.attributes.categoryIcon)
                    .font(.system(size: 12, weight: .bold))
            }
            .keylineTint(context.state.isBreak ? Color.green : Color.orange)
        }
    }
}

// MARK: - Preview Helper
#if DEBUG
extension PomodoroAttributes {
    fileprivate static var preview: PomodoroAttributes {
        PomodoroAttributes(taskName: "Belajar SwiftUI & Dynamic Island", categoryIcon: "timer")
    }
}

extension PomodoroAttributes.ContentState {
    fileprivate static var running: PomodoroAttributes.ContentState {
        PomodoroAttributes.ContentState(
            endTime: Date().addingTimeInterval(25 * 60),
            isPaused: false,
            isBreak: false,
            sessionTitle: "25 Min (Klasik)"
        )
    }
}

#Preview("Live Activity", as: .content, using: PomodoroAttributes.preview) {
    TaskWidgetLiveActivity()
} contentStates: {
    PomodoroAttributes.ContentState.running
}
#endif
