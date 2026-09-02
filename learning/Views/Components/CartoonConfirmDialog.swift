//
//  CartoonConfirmDialog.swift
//  learning
//
//  Created by macbook on 8/31/26.
//

import SwiftUI

// MARK: - 🎨 Reusable Cartoon Pop Confirmation Dialog
struct CartoonConfirmDialog: View {
    let title: String
    let message: String
    var icon: String = "trash.fill"
    var iconBgColor: Color = Color(red: 1.0, green: 0.92, blue: 0.92)
    var iconFgColor: Color = Color(red: 0.95, green: 0.32, blue: 0.32)
    var cancelTitle: String = "Batal"
    var confirmTitle: String = "Ya, Hapus"
    var confirmColor: Color = Color.cartoonCoral
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            // Backdrop Gelap Transparan
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    onCancel()
                }
                .zIndex(10)

            // Kartu Dialog Kartun Pop-up Membal
            VStack(spacing: HIGSpacing.md) {
                // Stiker Ikon Kartun Bulat
                ZStack {
                    Circle()
                        .fill(iconBgColor)
                        .frame(width: 68, height: 68)
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: 2.2)
                        )
                        .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)

                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .black))
                        .foregroundColor(iconFgColor)
                }
                .padding(.top, HIGSpacing.xxs)

                // Judul & Penjelasan
                VStack(spacing: HIGSpacing.xs) {
                    Text(title)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)

                    Text(message)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, HIGSpacing.xs)
                }

                // Tombol Aksi (Batal & Konfirmasi) - Min 44pt Touch Height
                HStack(spacing: HIGSpacing.sm) {
                    // Tombol Batal
                    Button {
                        onCancel()
                    } label: {
                        Text(cancelTitle)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: HIGSpacing.touchTargetMin)
                            .background(Color.white)
                            .cornerRadius(CartoonMetrics.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cornerRadius)
                                    .stroke(Color.black, lineWidth: 1.8)
                            )
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))

                    // Tombol Konfirmasi
                    Button {
                        onConfirm()
                    } label: {
                        Text(confirmTitle)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: HIGSpacing.touchTargetMin)
                            .background(confirmColor)
                            .cornerRadius(CartoonMetrics.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cornerRadius)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
                }
                .padding(.top, HIGSpacing.xs)
            }
            .padding(HIGSpacing.lg)
            .background(Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black, lineWidth: 2.5)
            )
            .shadow(color: .black, radius: 0, x: 4, y: 4)
            .frame(maxWidth: 310)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
            .zIndex(11)
        }
    }
}

#Preview {
    CartoonConfirmDialog(
        title: "Hapus Tugas?",
        message: "Apakah kamu yakin ingin menghapus tugas ini?",
        onCancel: {},
        onConfirm: {}
    )
}
