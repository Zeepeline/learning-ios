//
//  SidebarView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI

struct SidebarView: View {
    @Binding var isOpen: Bool
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = true

    var body: some View {
        ZStack(alignment: .leading) {
            // Latar Belakang Gelap Transparan
            if isOpen {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isOpen = false
                        }
                    }
            }

            // Panel Drawer Kartun Kompak & Playful
            if isOpen {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 14) {
                        
                        // 1. Header Profil Kartun Stiker
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.cartoonYellow)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle().stroke(Color.cartoonBorder, lineWidth: 2)
                                    )
                                    .shadow(color: .cartoonBorder, radius: 0, x: 2, y: 2)
                                
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.cartoonTextPrimary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Herlambang")
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                    .foregroundColor(.cartoonTextPrimary)
                                
                                // Tag Level Kartun
                                HStack(spacing: 3) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.orange)
                                    
                                    Text("Level 5")
                                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                                        .foregroundColor(.cartoonTextPrimary)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.cartoonMint)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(Color.cartoonBorder, lineWidth: 1.5)
                                )
                            }

                            Spacer()

                            // Tombol Close Silang Kartun
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    isOpen = false
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.cartoonTextPrimary)
                                    .padding(6)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.cartoonBorder, lineWidth: 1.5))
                                    .shadow(color: .cartoonBorder, radius: 0, x: 1.5, y: 1.5)
                            }
                            .buttonStyle(CartoonPressButtonStyle())
                        }
                        .padding(.top, 50)

                        // Garis Pemisah Kartun
                        Rectangle()
                            .fill(Color.cartoonBorder)
                            .frame(height: 2)
                            .padding(.vertical, 2)

                        // 2. Daftar Menu Kartun Mini
                        VStack(spacing: 9) {
                            CartoonMenuPill(
                                icon: "list.clipboard.fill",
                                title: "Semua Tugas",
                                count: 8,
                                bgColor: .cartoonYellow,
                                iconColor: .black
                            )
                            
                            CartoonMenuPill(
                                icon: "sun.max.fill",
                                title: "Hari Ini",
                                count: 3,
                                bgColor: .cartoonPink,
                                iconColor: .red
                            )
                            
                            CartoonMenuPill(
                                icon: "bookmark.fill",
                                title: "Penting",
                                count: 2,
                                bgColor: .cartoonBlue,
                                iconColor: .blue
                            )
                            
                            CartoonMenuPill(
                                icon: "folder.badge.gearshape",
                                title: "Kategori",
                                bgColor: .cartoonMint,
                                iconColor: .green
                            )
                            
                            CartoonMenuPill(
                                icon: "slider.horizontal.3",
                                title: "Pengaturan",
                                bgColor: .cartoonLavender,
                                iconColor: .purple
                            )
                        }
                        .padding(.horizontal, 10)

                        Spacer()

                        // 3. Tombol Logout / Keluar Kartun di Bagian Bawah
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isOpen = false
                                isLoggedIn = false // Otomatis berpindah ke halaman Login/Register
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(.red)
                                
                                Text("Keluar Akun")
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .foregroundColor(.red)
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity)
                            .cartoonCard(bgColor: .white, cornerRadius: 10, borderWidth: 1.5, shadowOffset: 2.0)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
                        .padding(.horizontal, 10)
                        .padding(.bottom, 25)
                    }
                    .padding(.horizontal, 14)
                    .frame(width: 280, alignment: .leading)
                    .background(Color.cartoonBg)
                    .overlay(
                        Rectangle()
                            .fill(Color.cartoonBorder)
                            .frame(width: 2.5),
                        alignment: .trailing
                    )
                    .ignoresSafeArea(.all, edges: .vertical)
                    .shadow(color: .black.opacity(0.25), radius: 12, x: 6, y: 0)

                    Spacer()
                }
                .transition(.move(edge: .leading))
            }
        }
    }
}

// Komponen Tombol Menu Kartu Kartun Kompak
struct CartoonMenuPill: View {
    let icon: String
    let title: String
    var count: Int? = nil
    var bgColor: Color
    var iconColor: Color

    var body: some View {
        Button {
            // Aksi saat menu diklik
        } label: {
            HStack(spacing: 8) {
                // Wadah Ikon Bulat Putih dengan Border
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .overlay(Circle().stroke(Color.cartoonBorder, lineWidth: 1.5))
                    
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(iconColor)
                }

                // Judul Menu Tebal tapi Kompak
                Text(title)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.cartoonTextPrimary)

                Spacer()

                // Badge Counter Kartun
                if let count = count {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(.cartoonTextPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.cartoonBorder, lineWidth: 1.2)
                        )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .cartoonCard(bgColor: bgColor, cornerRadius: 10, borderWidth: 1.5, shadowOffset: 2.0)
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
    }
}

#Preview {
    SidebarView(isOpen: .constant(true))
}
