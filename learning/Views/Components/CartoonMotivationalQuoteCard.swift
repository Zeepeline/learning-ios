//
//  CartoonMotivationalQuoteCard.swift
//  learning
//
//  Created by macbook on 9/19/26.
//

import SwiftUI

struct CartoonMotivationalQuoteCard: View {
    @ObservedObject var quoteService = MotivationalQuoteService.shared

    dynamic var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 1. Header: Tag Motivasi + Tombol Acak / Refresh Quote
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.black)

                    Text("MOTIVASI HARI INI")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(Color.cartoonYellow)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.2))

                Spacer()

                // Tombol Ganti / Acak Kata Motivasi
                Button {
                    SoundManager.shared.playPop()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        quoteService.shuffleQuote()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10, weight: .bold))
                            .rotationEffect(.degrees(quoteService.isLoading ? 360 : 0))
                            .animation(quoteService.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: quoteService.isLoading)

                        Text("Ganti")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Color.white)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.2))
                    .shadow(color: .black, radius: 0, x: 1.0, y: 1.0)
                }
                .buttonStyle(CartoonPressButtonStyle(pressOffset: 0.8))
            }

            // 2. Isi Kata Motivasi (Kutipan & Penulis - 100% Tajam & Solid)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 6) {
                    Text("“")
                        .font(.system(size: 24, weight: .heavy, design: .serif))
                        .foregroundColor(Color.black)
                        .offset(y: -2)

                    Text(quoteService.currentQuote.quote)
                        .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.black)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack {
                    Spacer()
                    HStack(spacing: 3) {
                        Text("—")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                        Text(quoteService.currentQuote.author)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(Color.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white)
                    .cornerRadius(5)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.black, lineWidth: 1.0))
                }
            }
        }
        .padding(HIGSpacing.md)
        .background(Color.white)
        .cornerRadius(CartoonMetrics.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
        .onAppear {
            quoteService.loadDailyQuoteIfNeeded()
        }
    }
}
