//
//  PomodoroFocusView.swift
//  learning
//
//  Created by macbook on 9/5/26.
//

import SwiftUI
import ActivityKit

struct PomodoroFocusView: View {
    @ObservedObject private var pomodoro = PomodoroManager.shared
    @ObservedObject private var screenTime = ScreenTimeManager.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: HIGSpacing.md) {
                // 1. Preset Selector Chips (Ringkas & Rapi)
                FocusPresetChips(pomodoro: pomodoro)

                // 2. Lingkaran Timer Kartun Interaktif
                FocusTimerRingCard(pomodoro: pomodoro)

                // 3. Pengaturan Sesi & Pelindung Fokus (Terpadu)
                FocusSessionSettingsCard(pomodoro: pomodoro, screenTime: screenTime)

                // 4. Tombol Kontrol Utama (Hero Action Button)
                FocusActionControls(pomodoro: pomodoro)
            }
            .padding(.horizontal, HIGSpacing.md)
            .padding(.top, HIGSpacing.xxs)
            .padding(.bottom, 110)
        }
        .background(Color.cartoonBg)
    }
}

// MARK: - 1. Preset Selector Chips (25m / 50m / 5m / 15m)
struct FocusPresetChips: View {
    @ObservedObject var pomodoro: PomodoroManager

    var body: some View {
        HStack(spacing: 8) {
            ForEach(PomodoroPreset.allCases) { preset in
                let isSelected = pomodoro.selectedPreset == preset
                Button {
                    pomodoro.selectPreset(preset)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: preset.iconName)
                            .font(.system(size: 11, weight: .black))

                        Text(presetShortLabel(preset))
                            .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isSelected ? preset.themeColor : Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: isSelected ? 1.8 : 1.2)
                    )
                    .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                .disabled(pomodoro.state != .idle)
            }
        }
    }

    private func presetShortLabel(_ preset: PomodoroPreset) -> String {
        switch preset {
        case .focus25: return "25m"
        case .deepWork50: return "50m"
        case .shortBreak5: return "5m"
        case .longBreak15: return "15m"
        }
    }
}

// MARK: - 2. Focus Timer Ring Card
struct FocusTimerRingCard: View {
    @ObservedObject var pomodoro: PomodoroManager

    var body: some View {
        VStack(spacing: HIGSpacing.sm) {
            // Header Status & Sesi Selesai
            HStack {
                HStack(spacing: 5) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1))

                    Text(statusText)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.3))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)

                    Text("\(pomodoro.completedSessionsCount) Sesi")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
            }

            // Ring Timer Animasi Kartun
            ZStack {
                // Outer Track
                Circle()
                    .stroke(Color.black.opacity(0.1), lineWidth: 14)
                    .frame(width: 200, height: 200)

                // Progress Stroke
                Circle()
                    .trim(from: 0.0, to: CGFloat(pomodoro.progress))
                    .stroke(
                        pomodoro.selectedPreset.themeColor,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: pomodoro.progress)
                    .frame(width: 200, height: 200)

                // Inner White Card
                Circle()
                    .fill(Color.white)
                    .frame(width: 165, height: 165)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    .shadow(color: .black, radius: 0, x: 2, y: 2)

                // Timer & Preset Content
                VStack(spacing: 3) {
                    Image(systemName: pomodoro.selectedPreset.iconName)
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.black)

                    Text(pomodoro.formattedTime)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                        .contentTransition(.numericText())

                    Text(pomodoro.taskTitle.isEmpty ? pomodoro.selectedPreset.rawValue : pomodoro.taskTitle)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .padding(.horizontal, 14)
                }
            }
            .padding(.vertical, 4)
        }
        .padding(HIGSpacing.md)
        .cartoonCard()
    }

    private var statusColor: Color {
        switch pomodoro.state {
        case .idle: return Color.cartoonYellow
        case .running: return Color.cartoonMint
        case .paused: return Color.cartoonOrange
        }
    }

    private var statusText: String {
        switch pomodoro.state {
        case .idle: return "Siap Dimulai"
        case .running: return pomodoro.selectedPreset.isBreak ? "Istirahat" : "Sedang Fokus"
        case .paused: return "Dijeda"
        }
    }
}

// MARK: - 3. Focus Session Settings Card (Task + Shield Toggle)
struct FocusSessionSettingsCard: View {
    @ObservedObject var pomodoro: PomodoroManager
    @ObservedObject var screenTime: ScreenTimeManager

    var body: some View {
        VStack(spacing: HIGSpacing.sm) {
            // Input Nama Tugas
            HStack(spacing: 8) {
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)

                TextField("Nama aktivitas fokus...", text: $pomodoro.taskTitle)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .disabled(pomodoro.state != .idle)

                if !pomodoro.taskTitle.isEmpty && pomodoro.state == .idle {
                    Button {
                        pomodoro.taskTitle = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))

            // Auto Shield Toggle Row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)

                    Text("Kunci Aplikasi Otomatis")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }

                Spacer()

                Toggle("", isOn: $pomodoro.isAutoShieldEnabled)
                    .labelsHidden()
                    .tint(Color.cartoonCoral)
                    .disabled(pomodoro.state != .idle)
            }
            .padding(.horizontal, 2)
        }
        .padding(HIGSpacing.md)
        .cartoonCard()
    }
}

// MARK: - 4. Focus Action Controls
struct FocusActionControls: View {
    @ObservedObject var pomodoro: PomodoroManager

    var body: some View {
        HStack(spacing: 10) {
            switch pomodoro.state {
            case .idle:
                Button {
                    pomodoro.startTimer()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 15, weight: .black))
                        Text(pomodoro.selectedPreset.isBreak ? "Mulai Istirahat" : "Mulai Fokus")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(pomodoro.selectedPreset.themeColor)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 2))
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.5))

            case .running:
                Button {
                    pomodoro.pauseTimer()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 14, weight: .black))
                        Text("Jeda")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.cartoonYellow)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 2))
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.5))

                Button {
                    pomodoro.resetTimer()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.black)
                        .padding(13)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 2))
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.5))

            case .paused:
                Button {
                    pomodoro.resumeTimer()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .black))
                        Text("Lanjutkan")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.cartoonMint)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 2))
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.5))

                Button {
                    pomodoro.resetTimer()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.black)
                        .padding(13)
                        .background(Color.cartoonCoral)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 2))
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.5))
            }
        }
    }
}

#Preview {
    PomodoroFocusView()
}
