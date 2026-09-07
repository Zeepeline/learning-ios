//
//  PomodoroFocusView.swift
//  learning
//
//  Created by macbook on 9/5/26.
//

import SwiftUI
import FamilyControls

struct PomodoroFocusView: View {
    var pomodoro = PomodoroManager.shared
    @Bindable private var screenTime = ScreenTimeManager.shared
    @State private var isPickerPresented: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: HIGSpacing.md) {
                // 1. Kartu Timer Utama dengan Progress Ring & Pulse
                PomodoroMainTimerCard(pomodoro: pomodoro)

                // 2. Preset Durasi Fokus / Istirahat
                PomodoroPresetSelector(pomodoro: pomodoro)

                // 3. Pengaturan Sesi & Integrasi Kunci Aplikasi
                FocusSessionSettingsCard(pomodoro: pomodoro, screenTime: screenTime)

                // 4. Suara Ambient Latar & White Noise
                AmbientSoundControlCard()

                // 5. Tombol Kontrol Aksi Fokus
                FocusActionControls(pomodoro: pomodoro)

                // 6. Kartu Statistik Sesi Hari Ini
                FocusSessionStatsCard(pomodoro: pomodoro)
            }
            .padding(.horizontal, HIGSpacing.md)
            .padding(.top, HIGSpacing.xxs)
            .padding(.bottom, 110)
        }
        .background(Color.cartoonBg)
        .familyActivityPicker(
            isPresented: $isPickerPresented,
            selection: $screenTime.activitySelection
        )
    }
}

// MARK: - 1. Main Timer Card
struct PomodoroMainTimerCard: View {
    var pomodoro: PomodoroManager

    var body: some View {
        VStack(spacing: HIGSpacing.md) {
            // Header Status Sesi
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(pomodoro.selectedPreset.themeColor)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1))

                    Text(pomodoro.selectedPreset.rawValue.uppercased())
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                )
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))

                Spacer()

                // Badge Mode Sesi
                Text(sessionModeText)
                    .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(pomodoro.selectedPreset.themeColor)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
            }

            // Circular Timer Display
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.black, lineWidth: 12)
                    .frame(width: 200, height: 200)

                Circle()
                    .stroke(Color(red: 0.90, green: 0.90, blue: 0.92), lineWidth: 8)
                    .frame(width: 200, height: 200)

                // Progress Bar
                Circle()
                    .trim(from: 0, to: pomodoro.progress)
                    .stroke(
                        pomodoro.selectedPreset.themeColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 200, height: 200)
                    .animation(.linear(duration: 1.0), value: pomodoro.progress)

                // Timer & Subtitle Text
                VStack(spacing: 2) {
                    Text(pomodoro.formattedTime)
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                        .monospacedDigit()

                    if !pomodoro.taskTitle.isEmpty {
                        Text(pomodoro.taskTitle)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .padding(.horizontal, 20)
                    } else {
                        Text(pomodoro.selectedPreset.isBreak ? "Waktu Istirahat" : "Waktu Fokus")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 6)

            // Status Shield Info
            if ScreenTimeManager.shared.isShieldActive {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)

                    Text("Aplikasi terganggu sedang dikunci demi fokus Anda")
                        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.cartoonCoral.opacity(0.35))
                )
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.1))
            }
        }
        .padding(HIGSpacing.md)
        .cartoonCard()
    }

    private var sessionModeText: String {
        switch pomodoro.state {
        case .idle: return "Siap Mulai"
        case .running: return pomodoro.selectedPreset.isBreak ? "Istirahat" : "Sedang Fokus"
        case .paused: return "Dijeda"
        }
    }
}

// MARK: - 2. Pomodoro Preset Selector
struct PomodoroPresetSelector: View {
    var pomodoro: PomodoroManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PILIH PRESET WAKTU")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundColor(.secondary)

            HStack(spacing: 6) {
                ForEach(PomodoroPreset.allCases, id: \.self) { preset in
                    let isSelected = pomodoro.selectedPreset == preset
                    Button {
                        HapticManager.shared.selection()
                        pomodoro.selectPreset(preset)
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: preset.iconName)
                                .font(.system(size: 13, weight: .bold))

                            Text(preset.rawValue)
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .lineLimit(1)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? preset.themeColor : Color.white)
                                .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: isSelected ? 1.8 : 1.1)
                        )
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    .disabled(pomodoro.state != .idle)
                }
            }
        }
        .padding(HIGSpacing.md)
        .cartoonCard()
    }
}

// MARK: - 3. Focus Session Settings Card (Task + Shield Toggle)
struct FocusSessionSettingsCard: View {
    @Bindable var pomodoro: PomodoroManager
    var screenTime: ScreenTimeManager

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
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
            )
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))

            // Auto Shield Toggle Row (Menggunakan CartoonToggleSwitch)
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

                CartoonToggleSwitch(
                    isOn: $pomodoro.isAutoShieldEnabled,
                    activeColor: Color.cartoonCoral
                )
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
    var pomodoro: PomodoroManager

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
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.cartoonYellow)
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: CartoonMetrics.borderWidth))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

            case .running:
                Button {
                    pomodoro.pauseTimer()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 14, weight: .black))
                        Text("Jeda")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.cartoonLavender)
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.8))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                Button {
                    pomodoro.resetTimer()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 14, weight: .black))
                        Text("Batal")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.cartoonCoral)
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.8))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

            case .paused:
                Button {
                    pomodoro.resumeTimer()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .black))
                        Text("Lanjutkan")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.cartoonMint)
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.8))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

                Button {
                    pomodoro.resetTimer()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 14, weight: .black))
                        Text("Reset")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.8))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
        }
    }
}

// MARK: - 5. Focus Session Stats Card
struct FocusSessionStatsCard: View {
    var pomodoro: PomodoroManager

    var body: some View {
        HStack(spacing: HIGSpacing.sm) {
            // Sesi Selesai Hari Ini
            VStack(spacing: 3) {
                Text("\(pomodoro.completedSessionsCount)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.black)

                Text("Sesi Selesai")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
            )
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.2))

            // Preset Aktif Info
            VStack(spacing: 3) {
                Text("\(Int(pomodoro.selectedPreset.duration / 60)) Menit")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.black)

                Text("Target Sesi")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
            )
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.2))
        }
    }
}

#Preview {
    PomodoroFocusView()
}
