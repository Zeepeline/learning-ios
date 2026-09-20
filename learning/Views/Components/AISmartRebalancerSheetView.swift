//
//  AISmartRebalancerSheetView.swift
//  learning
//
//  Created by macbook on 9/20/26.
//

import SwiftUI
import SwiftData

struct AISmartRebalancerSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let items: [Item]

    @State private var proposals: [RebalanceProposalItem] = []
    @State private var isApplying: Bool = false
    @State private var showSuccessCelebration: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cartoonBg
                    .ignoresSafeArea()

                if showSuccessCelebration {
                    successView
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                } else if proposals.isEmpty {
                    emptyStateView
                } else {
                    mainContentView
                }
            }
            .navigationTitle("AI Smart Rebalancer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CartoonIconButton(icon: "xmark") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadProposals()
            }
        }
    }

    // MARK: - Main Content View
    private var mainContentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: HIGSpacing.md) {
                // 1. Header Banner
                headerBanner

                // 2. Section Title
                HStack {
                    Text("PROPOSAL JADWAL BARU")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.secondary)

                    Spacer()

                    let selectedCount = proposals.filter { $0.isIncluded }.count
                    Text("\(selectedCount)/\(proposals.count) Dipilih")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.cartoonYellow)
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1))
                }
                .padding(.horizontal, HIGSpacing.md)

                // 3. Proposal Items List
                VStack(spacing: HIGSpacing.sm) {
                    ForEach($proposals) { $proposal in
                        rebalanceProposalCard(proposal: $proposal)
                    }
                }
                .padding(.horizontal, HIGSpacing.md)

                // 4. Action Buttons
                VStack(spacing: HIGSpacing.xs) {
                    let hasSelection = proposals.contains { $0.isIncluded }

                    Button {
                        applyScheduleChanges()
                    } label: {
                        HStack(spacing: 8) {
                            if isApplying {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .black))
                                Text("Terapkan Jadwal Cerdas")
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                            }
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(hasSelection ? Color.cartoonMint : Color.gray.opacity(0.3))
                        .cornerRadius(CartoonMetrics.cardCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                        )
                        .shadow(color: .black, radius: 0, x: hasSelection ? 2.5 : 1.0, y: hasSelection ? 2.5 : 1.0)
                    }
                    .buttonStyle(CartoonPressButtonStyle(pressOffset: hasSelection ? 1.5 : 0))
                    .disabled(!hasSelection || isApplying)

                    Button {
                        dismiss()
                    } label: {
                        Text("Batal & Biarkan Jadwal Asli")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, HIGSpacing.md)
                .padding(.top, HIGSpacing.sm)
                .padding(.bottom, 40)
            }
            .padding(.top, HIGSpacing.xs)
        }
    }

    // MARK: - Header Banner
    private var headerBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.cartoonYellow)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1.8))
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("AI Smart Rebalancing")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Text("AI menganalisis tugas terlewat & bentrok, lalu merancang ulang jam pengerjaan yang realistis dan bebas bentrok.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2, y: 2)
        .padding(.horizontal, HIGSpacing.md)
    }

    // MARK: - Rebalance Proposal Card
    private func rebalanceProposalCard(proposal: Binding<RebalanceProposalItem>) -> some View {
        let prop = proposal.wrappedValue
        return HStack(alignment: .top, spacing: 12) {
            // Checkbox
            Button {
                HapticManager.shared.selection()
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    proposal.wrappedValue.isIncluded.toggle()
                }
            } label: {
                Image(systemName: prop.isIncluded ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(prop.isIncluded ? .black : .secondary.opacity(0.6))
                    .padding(.top, 2)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                // Title & Category
                HStack {
                    Text(prop.item.title)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .lineLimit(1)

                    Spacer()

                    Text(prop.item.category)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cartoonLavender.opacity(0.5))
                        .cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.black, lineWidth: 0.8))
                }

                // Time comparison: Old -> New
                HStack(spacing: 6) {
                    Text(prop.originalDate.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .strikethrough(true, color: .secondary)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Color.cartoonCoral)

                    Text(prop.proposedDate.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cartoonMint)
                        .cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.black, lineWidth: 0.8))
                }

                // Reason Badge
                HStack(spacing: 4) {
                    Image(systemName: prop.reasonType.icon)
                        .font(.system(size: 10, weight: .bold))
                    Text(prop.reason)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundColor(prop.reasonType == .overdue ? Color(red: 0.8, green: 0.2, blue: 0.2) : .secondary)
            }
        }
        .padding(12)
        .background(prop.isIncluded ? Color.white : Color(red: 0.95, green: 0.95, blue: 0.95))
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: prop.isIncluded ? CartoonMetrics.borderWidth : 1.0)
        )
        .shadow(color: .black, radius: 0, x: prop.isIncluded ? 2 : 1, y: prop.isIncluded ? 2 : 1)
        .opacity(prop.isIncluded ? 1.0 : 0.65)
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.cartoonMint)
                    .frame(width: 80, height: 80)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    .shadow(color: .black, radius: 0, x: 2, y: 2)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.black)
            }

            VStack(spacing: 6) {
                Text("Jadwalmu Sudah Sempurna! 🎉")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Text("Tidak ditemukan tugas terlewat ataupun tabrakan waktu. Seluruh jadwalmu hari ini berjalan rapi.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                dismiss()
            } label: {
                Text("Tutup")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.cartoonYellow)
                    .cornerRadius(CartoonMetrics.cardCornerRadius)
                    .overlay(RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius).stroke(Color.black, lineWidth: 1.8))
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
            .padding(.top, 8)
        }
        .padding(24)
    }

    // MARK: - Success View
    private var successView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.cartoonYellow)
                    .frame(width: 80, height: 80)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    .shadow(color: .black, radius: 0, x: 2, y: 2)

                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .black))
                    .foregroundColor(.black)
            }

            VStack(spacing: 6) {
                Text("Jadwal Berhasil Ditata Ulang! 🚀")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Text("Waktu tugas dan pengingat notifikasi telah diperbarui secara otomatis. Selamat melanjutkan fokus!")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button {
                dismiss()
            } label: {
                Text("Kembali ke Beranda")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.cartoonMint)
                    .cornerRadius(CartoonMetrics.cardCornerRadius)
                    .overlay(RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius).stroke(Color.black, lineWidth: 1.8))
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
            .padding(.top, 8)
        }
        .padding(24)
    }

    // MARK: - Logic
    private func loadProposals() {
        proposals = AIScheduleRebalancerService.shared.analyzeAndGenerateProposals(for: items)
    }

    private func applyScheduleChanges() {
        isApplying = true
        Task {
            await AIScheduleRebalancerService.shared.applyRebalance(proposals: proposals, in: modelContext)
            await MainActor.run {
                isApplying = false
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showSuccessCelebration = true
                }
            }
        }
    }
}
