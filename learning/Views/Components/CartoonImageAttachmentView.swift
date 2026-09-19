//
//  CartoonImageAttachmentView.swift
//  learning
//
//  Created by macbook on 9/18/26.
//

import SwiftUI
import PhotosUI

// MARK: - 📸 Reusable Cartoon Image Attachment Component
struct CartoonImageAttachmentView: View {
    @Binding var imageData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isShowingFullPreview: Bool = false

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            // Header
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 11, weight: .black))
                    Text("LAMPIRAN FOTO / REFERENSI")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.secondary)

                Spacer()
            }

            if let data = imageData,
               let uiImage = ImageCacheManager.shared.thumbnail(for: data, key: "attachment_\(data.count)", targetSize: CGSize(width: 400, height: 320)) {
                // Tampilan Foto Terlampir
                VStack(spacing: 6) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .clipped()
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.5))
                            .shadow(color: .black.opacity(0.15), radius: 0, x: 2, y: 2)
                            .onTapGesture {
                                isShowingFullPreview = true
                            }

                        // Tombol Hapus Foto
                        Button {
                            HapticManager.shared.warning()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                imageData = nil
                                selectedPhotoItem = nil
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.cartoonPink)
                                    .frame(width: 28, height: 28)
                                    .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                                    .shadow(color: .black.opacity(0.2), radius: 0, x: 1, y: 1)

                                Image(systemName: "trash.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                        .padding(8)
                    }

                    // Teks Keterangan
                    HStack {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.cartoonBlue)
                        Text("Ketuk foto untuk memperbesar")
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }
                .sheet(isPresented: $isShowingFullPreview) {
                    NavigationStack {
                        ZStack {
                            Color.black.ignoresSafeArea()
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .padding()
                        }
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Tutup") {
                                    isShowingFullPreview = false
                                }
                                .font(.system(.body, design: .rounded).weight(.bold))
                                .foregroundColor(.white)
                            }
                        }
                    }
                }
            } else {
                // Tombol Pemilih Foto
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.cartoonPink.opacity(0.8))
                                .frame(width: 32, height: 32)
                                .overlay(Circle().stroke(Color.black, lineWidth: 1.4))

                            Image(systemName: "camera.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.black)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Lampirkan Foto / Referensi")
                                .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                            Text("Pilih sketsa, screenshot atau dokumen foto")
                                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1.2)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 0, x: 1.5, y: 1.5)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                .onChange(of: selectedPhotoItem) { _, newItem in
                    guard let newItem = newItem else { return }
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            await MainActor.run {
                                HapticManager.shared.success()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    self.imageData = data
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
