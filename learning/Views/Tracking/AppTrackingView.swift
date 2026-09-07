//
//  AppTrackingView.swift
//  learning
//
//  Created by macbook on 9/5/26.
//

import SwiftUI
import AppTrackingTransparency
import AdSupport

struct AppTrackingView: View {
    var trackingManager = AppTrackingManager.shared
    @State private var copiedToast: Bool = false
    @State private var isAnimatingRadar: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: HIGSpacing.md) {
                // 1. 🎯 Sticker Badge & Hero Card
                heroHeaderCard

                // 2. 🛡️ Status Otorisasi Live Card
                statusOverviewCard

                // 3. 🆔 IDFA (Identifier for Advertisers) Card
                idfaDetailCard

                // 4. ⚡ Tombol Aksi Kontrol (Action Buttons)
                actionButtonsCard

                // 5. 💡 Info & Edukasi Privasi Apple (ATT Guide)
                privacyEducationalCard
            }
            .padding(.horizontal, HIGSpacing.md)
            .padding(.top, HIGSpacing.sm)
            .padding(.bottom, 100) // Ruang ekstra untuk floating bottom navbar
        }
        .background(Color.cartoonBg)
        .overlay(alignment: .top) {
            if copiedToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.black)
                    Text("IDFA berhasil disalin ke Clipboard!")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.cartoonMint)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 2))
                .shadow(color: .black, radius: 0, x: 2, y: 2)
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 12)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: copiedToast)
        .onAppear {
            trackingManager.checkTrackingStatus()
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimatingRadar = true
            }
        }
    }

    // MARK: - 🎯 1. Hero Header Sticker Card
    private var heroHeaderCard: some View {
        HStack(spacing: HIGSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.cartoonBlue)
                    .frame(width: 60, height: 60)
                    .scaleEffect(isAnimatingRadar ? 1.08 : 0.96)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    .shadow(color: .black, radius: 0, x: 2, y: 2)

                Image(systemName: "hand.raised.app.fill")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.black)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("App Tracking")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)

                    Text("ATT")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cartoonYellow)
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.2))
                }

                Text("Transparansi & Otorisasi Pelacakan Privasi Apple iOS")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(HIGSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .fill(Color.white)
                .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
    }

    // MARK: - 🛡️ 2. Status Otorisasi Live Card
    private var statusOverviewCard: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.sm) {
            HStack {
                Text("STATUS OTORISASI LIVE")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(trackingManager.statusColor)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1))

                    Text(trackingManager.statusTitle)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(trackingManager.statusColor.opacity(0.4))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.2))
            }

            HStack(spacing: HIGSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(trackingManager.statusColor)
                        .frame(width: 44, height: 44)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.6))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)

                    Image(systemName: trackingManager.statusIcon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(trackingManager.statusDescription)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.black.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(HIGSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .fill(Color.white)
                .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
    }

    // MARK: - 🆔 3. IDFA Card
    private var idfaDetailCard: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.xs) {
            HStack {
                Label("IDFA (ADVERTISING IDENTIFIER)", systemImage: "qrcode")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.secondary)

                Spacer()

                if trackingManager.isAuthorized {
                    Button {
                        HapticManager.shared.success()
                        UIPasteboard.general.string = trackingManager.idfaString
                        copiedToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            copiedToast = false
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("Salin")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.cartoonMint)
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.2))
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(trackingManager.idfaString)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.cartoonBg)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.3), lineWidth: 1.2))
            }
        }
        .padding(HIGSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .fill(Color.white)
                .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
    }

    // MARK: - ⚡ 4. Action Buttons Card
    private var actionButtonsCard: some View {
        VStack(spacing: HIGSpacing.sm) {
            // Tombol Minta Izin
            Button {
                HapticManager.shared.impact(style: .medium)
                Task {
                    await trackingManager.requestTrackingAuthorization()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 14, weight: .black))
                    Text(trackingManager.isRequesting ? "Menampilkan Pop-up..." : "Minta Izin ATT (Pop-up Sistem)")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.cartoonYellow)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                )
                .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.5))
            .disabled(trackingManager.isRequesting)

            HStack(spacing: HIGSpacing.sm) {
                // Tombol Refresh Status
                Button {
                    HapticManager.shared.selection()
                    trackingManager.checkTrackingStatus()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12, weight: .bold))
                        Text("Refresh Status")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1.6)
                    )
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))

                // Tombol Buka Pengaturan iOS
                Button {
                    HapticManager.shared.impact(style: .light)
                    trackingManager.openSettings()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("Pengaturan iOS")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.cartoonLavender)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1.6)
                    )
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
            }
        }
        .padding(HIGSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .fill(Color(red: 0.96, green: 0.94, blue: 0.90))
                .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
    }

    // MARK: - 💡 5. Privacy Guide Card
    private var privacyEducationalCard: some View {
        VStack(alignment: .leading, spacing: HIGSpacing.xs) {
            Label("TENTANG APP TRACKING TRANSPARENCY", systemImage: "info.circle.fill")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                guideRow(number: "1", title: "Kebijakan Apple iOS 14.5+", text: "Pengembang wajib meminta izin eksplisit sebelum dapat mengakses IDFA perangkat.")
                guideRow(number: "2", title: "Nilai IDFA Nol", text: "Jika pengguna menolak (Denied), sistem otomatis mengembalikan string berupa kumpulan angka 00000000-0000-0000-0000-000000000000.")
                guideRow(number: "3", title: "Hak Pengguna", text: "Pengguna dapat mengubah izin kapan saja melalui menu Settings > Privacy & Security > Tracking.")
            }
            .padding(.top, 4)
        }
        .padding(HIGSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .fill(Color.white)
                .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
    }

    private func guideRow(number: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(.black)
                .frame(width: 18, height: 18)
                .background(Color.cartoonPink)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.black, lineWidth: 1.2))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                Text(text)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    AppTrackingView()
}
