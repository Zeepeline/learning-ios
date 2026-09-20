//
//  CartoonAIWeeklyReviewSheetView.swift
//  learning
//
//  Created by macbook on 9/20/26.
//

import SwiftUI
import SwiftData

struct CartoonAIWeeklyReviewSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let report: WeeklyReport

    @State private var isScoreAnimated: Bool = false
    @State private var isShowingShareSheet: Bool = false
    @State private var isCopiedNotification: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cartoonBg
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: HIGSpacing.md) {
                        // 1. Hero Infographic Score & Grade Card
                        scoreHeroCard

                        // 2. Persona Badge Card
                        personaBadgeCard

                        // 3. 4-Grid Metric Performance
                        metricsGrid

                        // 4. AI Highlights Section
                        highlightsSection

                        // 5. Actionable Growth Tips
                        growthTipsSection

                        // 6. Share & Copy Action Buttons
                        actionButtons
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    .padding(.top, HIGSpacing.xs)
                    .padding(.bottom, 40)
                }

                // Toast Notifikasi Salin
                if isCopiedNotification {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.cartoonMint)
                            Text("Ringkasan berhasil disalin ke clipboard!")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.5))
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                        .padding(.bottom, 30)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Laporan Mingguan AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CartoonIconButton(icon: "xmark") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    isScoreAnimated = true
                }
                if report.score >= 85 {
                    SoundManager.shared.playSuccessChime()
                }
            }
            .sheet(isPresented: $isShowingShareSheet) {
                ShareSheet(activityItems: [report.shareableSummaryText])
            }
        }
    }

    // MARK: - 1. Score Hero Infographic Card
    private var scoreHeroCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PRODUKTIVITAS 7 HARI")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.secondary)

                    Text("Skor Performa AI")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                }

                Spacer()

                // Grade Pill
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.cartoonYellow)
                        .frame(width: 48, height: 48)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.8))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)

                    Text(report.scoreGrade)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                }
            }

            // Big Circular Meter
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.black.opacity(0.1), lineWidth: 12)
                        .frame(width: 96, height: 96)

                    Circle()
                        .trim(from: 0, to: isScoreAnimated ? CGFloat(report.score) / 100.0 : 0)
                        .stroke(
                            Color.cartoonMint,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 96, height: 96)

                    VStack(spacing: 0) {
                        Text("\(report.score)")
                            .font(.system(size: 26, weight: .black, design: .monospaced))
                            .foregroundColor(.black)
                        Text("/100")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(performanceDescription)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.black)

                    Text("Kategori paling aktif: **\(report.topCategory)**")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }

    private var performanceDescription: String {
        switch report.score {
        case 90...100: return "Luar Biasa! Performa produktivitasmu berada di level puncak. 🚀"
        case 75..<90: return "Sangat Bagus! Ritme fokus dan konsistensi tugasmu terjaga baik. 🌟"
        case 60..<75: return "Bagus! Kamu memiliki pondasi produktivitas yang stabil. ⚡"
        default: return "Tetap Semangat! Pekan depan adalah kesempatan baru untuk bersinar. 💪"
        }
    }

    // MARK: - 2. Persona Badge Card
    private var personaBadgeCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: report.persona.badgeColorHex))
                    .frame(width: 48, height: 48)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1.8))
                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)

                Image(systemName: report.persona.badgeIcon)
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.black)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("PERSONA MINGGU INI")
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                        .foregroundColor(.secondary)

                    Text("AI Archetype")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.cartoonYellow.opacity(0.4))
                        .cornerRadius(4)
                }

                Text(report.persona.rawValue)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Text(report.persona.tagline)
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }

    // MARK: - 3. 4-Grid Metric Performance
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            metricCard(
                icon: "checkmark.seal.fill",
                title: "Tugas Selesai",
                value: "\(report.completedTasksCount)",
                subvalue: "\(report.taskCompletionPercentage)% tuntas",
                color: .cartoonMint
            )

            metricCard(
                icon: "flame.fill",
                title: "Max Habit Streak",
                value: "\(report.maxHabitStreak) Hari",
                subvalue: "\(report.completedHabitsCheckins) check-in",
                color: .cartoonCoral
            )

            metricCard(
                icon: "timer",
                title: "Fokus Pomodoro",
                value: "\(report.totalFocusMinutes)m",
                subvalue: "\(report.pomodoroSessionsCount) sesi selesai",
                color: .cartoonLavender
            )

            metricCard(
                icon: "figure.walk",
                title: "Aktivitas Fisik",
                value: "\(report.averageSteps)",
                subvalue: "langkah / hari",
                color: .cartoonYellow
            )
        }
    }

    private func metricCard(icon: String, title: String, value: String, subvalue: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.2))

                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.black)
                }

                Spacer()
            }

            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(.black)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Text(subvalue)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }

    // MARK: - 4. Highlights Section
    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                Text("HIGHLIGHT PENCAPAIAN")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 6) {
                ForEach(report.highlights, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.cartoonMint)
                            .padding(.top, 1)

                        Text(item)
                            .font(.system(size: 12.5, weight: .medium, design: .rounded))
                            .foregroundColor(.black)

                        Spacer()
                    }
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.0))
                }
            }
        }
    }

    // MARK: - 5. Actionable Growth Tips
    private var growthTipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.cartoonYellow)
                Text("SARAN STRATEGIS PEKAN DEPAN")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 6) {
                ForEach(report.growthTips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.cartoonLavender)
                            .padding(.top, 1)

                        Text(tip)
                            .font(.system(size: 12.5, weight: .medium, design: .rounded))
                            .foregroundColor(.black)

                        Spacer()
                    }
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.0))
                }
            }
        }
    }

    // MARK: - 6. Share & Copy Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 10) {
            // Tombol Bagikan
            Button {
                HapticManager.shared.impact(style: .medium)
                isShowingShareSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("Bagikan Laporan")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.cartoonYellow)
                .cornerRadius(CartoonMetrics.cardCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                        .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                )
                .shadow(color: .black, radius: 0, x: 2, y: 2)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

            // Tombol Salin Ringkasan
            Button {
                HapticManager.shared.success()
                UIPasteboard.general.string = report.shareableSummaryText
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    isCopiedNotification = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        isCopiedNotification = false
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("Salin Teks")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.cartoonMint)
                .cornerRadius(CartoonMetrics.cardCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                        .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                )
                .shadow(color: .black, radius: 0, x: 2, y: 2)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
        }
        .padding(.top, 4)
    }
}

// MARK: - 📤 Native iOS ShareSheet Helper
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
