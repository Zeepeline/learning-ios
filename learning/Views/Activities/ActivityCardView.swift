//
//  ActivityCardView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI

struct ActivityCardView: View {
    let item: Item
    var onToggle: () -> Void
    var onDelete: () -> Void
    var onTap: (() -> Void)?

    var body: some View {
        HStack(spacing: HIGSpacing.sm) {
            // 1. Tombol Checkbox Kartun (Touch target minimal 44pt via contentShape/frame)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    onToggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(item.isCompleted ? Color.cartoonMint : Color.white)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle().stroke(Color.cartoonBorder, lineWidth: CartoonMetrics.borderWidth)
                        )
                    
                    if item.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.cartoonTextPrimary)
                    }
                }
                .frame(width: HIGSpacing.touchTargetMin, height: HIGSpacing.touchTargetMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))

            // 2. Detail Konten Aktivitas (Dapat diketuk untuk membuka modal Edit)
            Button {
                onTap?()
            } label: {
                VStack(alignment: .leading, spacing: HIGSpacing.xxs) {
                    // Judul Aktivitas
                    Text(item.title)
                        .font(.cartoonHeadline)
                        .foregroundColor(.cartoonTextPrimary)
                        .strikethrough(item.isCompleted, color: .cartoonBorder)
                        .opacity(item.isCompleted ? 0.55 : 1.0)
                        .multilineTextAlignment(.leading)

                    // Info Waktu & Catatan
                    HStack(spacing: HIGSpacing.xs) {
                        HStack(spacing: HIGSpacing.xxs) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text(item.timestamp, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                                .font(.cartoonBadge)
                                .foregroundColor(.secondary)
                        }

                        // Badge Prioritas
                        priorityBadge(for: item.priority)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            // 3. Tombol Hapus Mini (Touch target 44x44)
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    onDelete()
                }
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.red.opacity(0.8))
                    .padding(HIGSpacing.xs)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.cartoonBorder, lineWidth: 1.2))
                    .frame(width: HIGSpacing.touchTargetMin, height: HIGSpacing.touchTargetMin)
                    .contentShape(Rectangle())
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
        }
        .padding(.horizontal, HIGSpacing.md)
        .padding(.vertical, HIGSpacing.sm)
        .cartoonCard(
            bgColor: item.isCompleted ? Color.gray.opacity(0.12) : cardBgColor(for: item.priority),
            cornerRadius: CartoonMetrics.cardCornerRadius,
            borderWidth: CartoonMetrics.borderWidth,
            shadowOffset: item.isCompleted ? 1.0 : 2.5
        )
    }

    // Warna Background Kartu berdasarkan Prioritas
    private func cardBgColor(for priority: String) -> Color {
        switch priority {
        case "Tinggi": return Color.cartoonPink.opacity(0.6)
        case "Normal": return Color.cartoonYellow.opacity(0.6)
        case "Rendah": return Color.cartoonBlue.opacity(0.6)
        default: return .white
        }
    }

    // Badge Prioritas
    @ViewBuilder
    private func priorityBadge(for priority: String) -> some View {
        let (color, text) = badgeData(for: priority)
        Text(text)
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .foregroundColor(.cartoonTextPrimary)
            .padding(.horizontal, HIGSpacing.xs)
            .padding(.vertical, HIGSpacing.xxs)
            .background(color)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.cartoonBorder, lineWidth: 1.2)
            )
    }

    private func badgeData(for priority: String) -> (Color, String) {
        switch priority {
        case "Tinggi": return (Color.cartoonPink, "Tinggi ⚡️")
        case "Normal": return (Color.cartoonYellow, "Normal")
        case "Rendah": return (Color.cartoonMint, "Rendah")
        default: return (Color.white, priority)
        }
    }
}
