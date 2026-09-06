//
//  ProfileHeaderView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI

struct ProfileHeaderView: View {
    let userName: String
    let userEmail: String
    let userBio: String
    let avatarIcon: String
    let avatarColorHex: String
    let totalXP: Int
    let userLevel: Int
    let xpProgressInCurrentLevel: Double
    let onEditTap: () -> Void

    var body: some View {
        VStack(spacing: HIGSpacing.sm) {
            ZStack(alignment: .bottomTrailing) {
                // Avatar Bulat Kartun
                ZStack {
                    Circle()
                        .fill(Color(hex: avatarColorHex))
                        .frame(width: 88, height: 88)
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: CartoonMetrics.thickBorderWidth)
                        )
                        .shadow(color: .black, radius: 0, x: 3, y: 3)
                    
                    Image(systemName: avatarIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .foregroundColor(.black)
                }

                // Badge Edit Pensil Mini
                Button {
                    HapticManager.shared.impact(style: .light)
                    onEditTap()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Color.cartoonMint)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.6))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
            }
            .padding(.top, HIGSpacing.xs)

            // Nama & Email
            VStack(spacing: HIGSpacing.xxs) {
                Text(userName)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Text(userBio)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)

                Text(userEmail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.8))
            }

            // Badge XP & Level Gamifikasi Real-Time
            VStack(spacing: 6) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.cartoonOrange)
                        Text("Level \(userLevel) Explorer")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                    }

                    Spacer()

                    Text("\(totalXP) XP Total")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }

                // Progress Bar Kartun
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.93, green: 0.93, blue: 0.95))
                            .frame(height: 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: 1.5)
                            )

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.cartoonMint)
                            .frame(width: max(geometry.size.width * CGFloat(xpProgressInCurrentLevel), (totalXP > 0 ? 12 : 0)), height: 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: 1.5)
                            )
                            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: xpProgressInCurrentLevel)
                    }
                }
                .frame(height: 12)
            }
            .padding(HIGSpacing.md)
            .background(Color.white)
            .cornerRadius(CartoonMetrics.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
            )
            .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
            .padding(.horizontal, HIGSpacing.md)
        }
    }
}
