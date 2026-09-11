//
//  AmbientSoundControlCard.swift
//  learning
//
//  Created by macbook on 9/7/26.
//

import SwiftUI

struct AmbientSoundControlCard: View {
    var soundManager = SoundManager.shared

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            // Header Info & Master Play/Stop Button
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "headphones")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.black)

                    Text("SUARA AMBIENT & FOKUS")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Master Ambient Play/Pause Button
                Button {
                    HapticManager.shared.impact(style: .medium)
                    soundManager.toggleAmbient()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: soundManager.isPlayingAmbient ? "speaker.wave.3.fill" : "speaker.slash.fill")
                            .font(.system(size: 10, weight: .bold))

                        Text(soundManager.isPlayingAmbient ? "Sedang Putar" : "Mati")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(soundManager.isPlayingAmbient ? Color.cartoonMint : Color.white)
                            .shadow(color: .black, radius: 0, x: 1, y: 1)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.1))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }

            // Grid / Baris Pilihan Suara Ambient
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AmbientSound.allCases) { sound in
                        let isSelected = soundManager.selectedAmbient == sound
                        Button {
                            HapticManager.shared.selection()
                            soundManager.selectedAmbient = sound
                            if sound != .none && !soundManager.isPlayingAmbient {
                                soundManager.playAmbient(sound)
                            } else if sound == .none {
                                soundManager.stopAmbient()
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: sound.iconName)
                                    .font(.system(size: 11, weight: .bold))

                                Text(sound.title)
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelected ? sound.themeColor : Color.white)
                                    .shadow(color: .black, radius: 0, x: isSelected ? 2 : 1, y: isSelected ? 2 : 1)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: isSelected ? 1.6 : 1.0)
                            )
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    }
                }
                .padding(.vertical, 2)
            }

            // Slider Volume & Auto Play Toggle jika bukan mode 'none'
            if soundManager.selectedAmbient != .none {
                VStack(spacing: 8) {
                    // Volume Control
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)

                        Slider(
                            value: Binding(
                                get: { soundManager.ambientVolume },
                                set: { soundManager.ambientVolume = $0 }
                            ),
                            in: 0.0...1.0
                        )
                        .tint(Color.cartoonCoral)

                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                    }

                    // Auto-play Toggle with Pomodoro
                    HStack {
                        Text("Putar otomatis saat sesi timer dimulai")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(.black.opacity(0.8))

                        Spacer()

                        CartoonToggleSwitch(
                            isOn: Binding(
                                get: { soundManager.isAutoPlayAmbientWithPomodoro },
                                set: { soundManager.isAutoPlayAmbientWithPomodoro = $0 }
                            ),
                            activeColor: Color.cartoonYellow
                        )
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(HIGSpacing.md)
        .cartoonCard()
    }
}

#Preview {
    AmbientSoundControlCard()
        .padding()
        .background(Color.cartoonBg)
}
