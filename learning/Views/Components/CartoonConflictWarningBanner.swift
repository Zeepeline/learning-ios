//
//  CartoonConflictWarningBanner.swift
//  learning
//
//  Created by macbook on 9/20/26.
//

import SwiftUI

// MARK: - ⚠️ Cartoon Conflict Warning Banner
struct CartoonConflictWarningBanner: View {
    let conflict: ScheduleConflict
    var onShiftTime: (Date) -> Void

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.cartoonCoral)
                        .frame(width: 24, height: 24)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.4))

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.black)
                }

                Text("Potensi Tabrakan Jadwal")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Spacer()
            }

            Text(conflict.localizedWarningMessage)
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundColor(Color.black.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            // Quick Resolution Action Chips
            HStack(spacing: 6) {
                Text("Solusi Cepat:")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(.black.opacity(0.6))

                // +30 Menit
                Button {
                    HapticManager.shared.impact(style: .light)
                    let newDate = conflict.existingTaskTime.addingTimeInterval(30 * 60)
                    onShiftTime(newDate)
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text("+30m")
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cartoonYellow)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.2))
                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))

                // +1 Jam
                Button {
                    HapticManager.shared.impact(style: .light)
                    let newDate = conflict.existingTaskTime.addingTimeInterval(60 * 60)
                    onShiftTime(newDate)
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.system(size: 9, weight: .bold))
                        Text("+1 Jam")
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cartoonMint)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.2))
                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))
            }
            .padding(.top, 2)
        }
        .padding(10)
        .background(Color.cartoonCoral.opacity(0.2))
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: 1.5)
        )
        .shadow(color: .black, radius: 0, x: 2, y: 2)
    }
}
