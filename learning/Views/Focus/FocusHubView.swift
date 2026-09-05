//
//  FocusHubView.swift
//  learning
//
//  Created by macbook on 9/5/26.
//

import SwiftUI

struct FocusHubView: View {
    @State private var selectedSegment: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Segmented Switcher Ringkas & Bersih
            HStack(spacing: 8) {
                FocusSegmentTab(
                    title: "Timer",
                    icon: "timer",
                    isSelected: selectedSegment == 0,
                    activeColor: Color.cartoonCoral.opacity(0.85)
                ) {
                    HapticManager.shared.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedSegment = 0
                    }
                }

                FocusSegmentTab(
                    title: "Screen Time",
                    icon: "hourglass",
                    isSelected: selectedSegment == 1,
                    activeColor: Color.cartoonLavender
                ) {
                    HapticManager.shared.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedSegment = 1
                    }
                }
            }
            .padding(4)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: 1.8)
            )
            .shadow(color: .black, radius: 0, x: 2, y: 2)
            .padding(.horizontal, HIGSpacing.md)
            .padding(.top, HIGSpacing.xs)
            .padding(.bottom, HIGSpacing.sm)

            // Content Switcher
            Group {
                if selectedSegment == 0 {
                    PomodoroFocusView()
                } else {
                    ScreenTimeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.cartoonBg)
    }
}

struct FocusSegmentTab: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let activeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .black))

                Text(title)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? activeColor : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.black : Color.clear, lineWidth: 1.4)
            )
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
    }
}

#Preview {
    FocusHubView()
}
