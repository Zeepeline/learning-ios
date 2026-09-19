//
//  CartoonAlarmSoundPicker.swift
//  learning
//
//  Created by macbook on 9/18/26.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - 🎵 Cartoon Alarm Sound Picker Component
struct CartoonAlarmSoundPicker: View {
    @Binding var selectedSoundName: String?
    
    @State private var availableSounds: [AlarmSoundItem] = []
    @State private var isShowingFileImporter: Bool = false
    @State private var isImporting: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isShowingErrorAlert: Bool = false
    @State private var currentlyPlayingId: String? = nil

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            // Header Section
            HStack {
                Text("NADA ALARM NOTIFIKASI")
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .foregroundColor(.secondary)

                Spacer()

                // Tombol Impor MP3 / Audio Baru
                Button {
                    HapticManager.shared.impact(style: .medium)
                    isShowingFileImporter = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("Impor MP3")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cartoonMint)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.black, lineWidth: 1.2)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 0, x: 1, y: 1)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }

            // Chips List Suara (Presets & Custom)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(availableSounds) { sound in
                        let isSelected = (selectedSoundName == sound.fileName) || (selectedSoundName == nil && sound.fileName == nil) || (selectedSoundName == sound.id)

                        Button {
                            HapticManager.shared.selection()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                selectedSoundName = sound.fileName
                            }
                            // Putar Preview Suara
                            currentlyPlayingId = sound.id
                            SoundManager.shared.previewSound(named: sound.fileName)
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: sound.iconName)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(isSelected ? .black : .secondary)

                                Text(sound.title)
                                    .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                                    .foregroundColor(.black)

                                if sound.isCustom {
                                    // Tag Custom
                                    Text("MP3")
                                        .font(.system(size: 8, weight: .black, design: .rounded))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.cartoonPink.opacity(0.3))
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelected ? Color.cartoonYellow : Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 0, x: 1, y: 1)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: isSelected ? 1.6 : 1.0)
                            )
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                        .contextMenu {
                            if sound.isCustom, let fileName = sound.fileName {
                                Button(role: .destructive) {
                                    deleteCustomSound(sound, fileName: fileName)
                                } label: {
                                    Label("Hapus Suara Ini", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            // Status Info & Tombol Preview Ulang
            HStack(spacing: 6) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cartoonMint)

                let currentTitle = availableSounds.first {
                    ($0.fileName == selectedSoundName) || (selectedSoundName == nil && $0.fileName == nil) || ($0.id == selectedSoundName)
                }?.title ?? "Default iOS"

                Text("Nada aktif: **\(currentTitle)**")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundColor(.black.opacity(0.8))

                Spacer()

                Button {
                    SoundManager.shared.previewSound(named: selectedSoundName)
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text("Tes Bunyi")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white)
                    .cornerRadius(5)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.black, lineWidth: 1.0))
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cartoonMint.opacity(0.15))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cartoonMint.opacity(0.4), lineWidth: 1.0))
        }
        .onAppear {
            refreshSounds()
        }
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.audio, .mp3, .wav, .aiff],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result: result)
        }
        .alert("Gagal Mengimpor Audio", isPresented: $isShowingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Terjadi kesalahan saat memproses file MP3.")
        }
    }

    private func refreshSounds() {
        availableSounds = SoundManager.shared.getAvailableAlarmSounds()
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selectedURL = urls.first else { return }
            isImporting = true
            Task {
                do {
                    let importedItem = try await SoundManager.shared.importAudioFile(from: selectedURL)
                    await MainActor.run {
                        refreshSounds()
                        selectedSoundName = importedItem.fileName
                        isImporting = false
                        HapticManager.shared.success()
                        SoundManager.shared.previewSound(named: importedItem.fileName)
                    }
                } catch {
                    await MainActor.run {
                        isImporting = false
                        errorMessage = error.localizedDescription
                        isShowingErrorAlert = true
                    }
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            isShowingErrorAlert = true
        }
    }

    private func deleteCustomSound(_ sound: AlarmSoundItem, fileName: String) {
        SoundManager.shared.deleteCustomSound(fileName: fileName)
        if selectedSoundName == fileName {
            selectedSoundName = nil
        }
        refreshSounds()
        HapticManager.shared.warning()
    }
}
