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
            // 1. 🔘 Tombol Checkbox Kartun Pop Neo-Brutalist
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) {
                    onToggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(item.isCompleted ? Color.cartoonMint : Color.white)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: 2.0)
                        )
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                    
                    if item.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.black)
                    }
                }
                .frame(width: HIGSpacing.touchTargetMin, height: HIGSpacing.touchTargetMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))

            // 2. 📝 Detail Konten Aktivitas (Teks Hitam Tajam & Tegas Bergaya Kartun)
            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.black)
                    .strikethrough(item.isCompleted, color: Color.black.opacity(0.8))
                    .multilineTextAlignment(.leading)

                HStack(spacing: HIGSpacing.xs) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.black.opacity(0.65))
                        Text(item.timestamp, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color.black.opacity(0.65))
                    }

                    // Badge Prioritas Kartun
                    priorityBadge(for: item.priority)

                    // Badge Jadwal Rutin (Scheduler)
                    if item.isRecurring {
                        recurrenceBadge(for: item.recurrence)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap?()
            }

            Spacer()

            // 3. 🗑️ Tombol Hapus Kartun Pop
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    onDelete()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.cartoonPink)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: 1.8)
                        )
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                    
                    Image(systemName: "trash.fill")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.black)
                }
                .frame(width: HIGSpacing.touchTargetMin, height: HIGSpacing.touchTargetMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
        }
        .padding(.horizontal, HIGSpacing.md)
        .padding(.vertical, HIGSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .fill(item.isCompleted ? Color(red: 0.94, green: 0.94, blue: 0.94) : cardBgColor(for: item.priority))
                .shadow(color: .black, radius: 0, x: item.isCompleted ? 1.5 : 2.5, y: item.isCompleted ? 1.5 : 2.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
    }

    // MARK: - Warna Background Kartu Terang Solid
    private func cardBgColor(for priority: String) -> Color {
        switch priority {
        case "Tinggi": return Color(red: 1.0, green: 0.88, blue: 0.88)
        case "Normal": return Color(red: 1.0, green: 0.95, blue: 0.82)
        case "Rendah": return Color(red: 0.88, green: 0.95, blue: 1.0)
        default: return .white
        }
    }

    // MARK: - Badge Prioritas Bergaya Kartun
    @ViewBuilder
    private func priorityBadge(for priority: String) -> some View {
        let (color, text) = badgeData(for: priority)
        Text(text)
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .foregroundColor(.black)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(color)
            )
            .overlay(
                Capsule().stroke(Color.black, lineWidth: 1.2)
            )
            .shadow(color: .black, radius: 0, x: 1, y: 1)
    }

    // MARK: - Badge Jadwal Rutin (Scheduler)
    @ViewBuilder
    private func recurrenceBadge(for rule: RecurrenceRule) -> some View {
        HStack(spacing: 3) {
            Image(systemName: rule.icon)
                .font(.system(size: 8, weight: .bold))
            Text(rule.shortTitle)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
        }
        .foregroundColor(.black)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule().fill(rule.badgeColor)
        )
        .overlay(
            Capsule().stroke(Color.black, lineWidth: 1.2)
        )
        .shadow(color: .black, radius: 0, x: 1, y: 1)
    }

    private func badgeData(for priority: String) -> (Color, String) {
        switch priority {
        case "Tinggi": return (Color.cartoonPink, "Tinggi")
        case "Normal": return (Color.cartoonYellow, "Normal")
        case "Rendah": return (Color.cartoonMint, "Rendah")
        default: return (Color.white, priority)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ActivityCardView(
            item: Item(title: "Mengerjakan Desain UI Baru", timestamp: Date(), isCompleted: false, priority: "Tinggi", isRecurring: true, recurrenceRule: "Setiap Hari"),
            onToggle: {},
            onDelete: {}
        )
        ActivityCardView(
            item: Item(title: "Meeting Evaluasi Mingguan", timestamp: Date(), isCompleted: true, priority: "Normal"),
            onToggle: {},
            onDelete: {}
        )
    }
    .padding()
    .background(Color.cartoonBg)
}
