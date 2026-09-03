//
//  SidebarView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI
import SwiftData

struct SidebarView: View {
    @Binding var isOpen: Bool
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = true
    @AppStorage("userName") private var userName: String = "Bruce Wayne"
    
    @Query private var allItems: [Item]
    @State private var isShowingLogoutDialog: Bool = false

    private let calendar = Calendar.current

    // Live counts dari SwiftData
    private var todayCount: Int {
        allItems.filter { calendar.isDateInToday($0.timestamp) }.count
    }

    private var importantCount: Int {
        allItems.filter { $0.priority == "Tinggi" }.count
    }

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
                    VStack(alignment: .leading, spacing: HIGSpacing.md) {
                        
                        // 1. Header Profil Kartun Stiker
                        HStack(spacing: HIGSpacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(Color.cartoonYellow)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle().stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                                    )
                                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                                
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 28)
                                    .foregroundColor(.black)
                            }

                            VStack(alignment: .leading, spacing: HIGSpacing.xxs) {
                                Text(userName)
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                    .foregroundColor(.black)
                                
                                // Tag Level Kartun
                                HStack(spacing: 3) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.orange)
                                    
                                    Text("Level 1")
                                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                                        .foregroundColor(.black)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.cartoonMint)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(Color.black, lineWidth: 1.2)
                                )
                            }

                            Spacer()

                            // Tombol Close Silang Kartun (Touch Target 44pt)
                            Button {
                                HapticManager.shared.impact(style: .light)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    isOpen = false
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(.black)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                            }
                            .buttonStyle(CartoonPressButtonStyle())
                        }
                        .padding(.top, 50)

                        // Garis Pemisah Kartun
                        Rectangle()
                            .fill(Color.black)
                            .frame(height: 2)
                            .padding(.vertical, HIGSpacing.xxs)

                        // 2. Daftar Menu Kartun Mini dengan Live Counter
                        VStack(spacing: HIGSpacing.xs) {
                            CartoonMenuPill(
                                icon: "list.clipboard.fill",
                                title: "Semua Tugas",
                                count: allItems.count,
                                bgColor: .cartoonYellow,
                                iconColor: .black
                            )
                            
                            CartoonMenuPill(
                                icon: "sun.max.fill",
                                title: "Hari Ini",
                                count: todayCount,
                                bgColor: .cartoonPink,
                                iconColor: .red
                            )
                            
                            CartoonMenuPill(
                                icon: "bookmark.fill",
                                title: "Penting",
                                count: importantCount,
                                bgColor: .cartoonBlue,
                                iconColor: .blue
                            )
                            
                            CartoonMenuPill(
                                icon: "folder.badge.gearshape",
                                title: "Kategori",
                                bgColor: .cartoonMint,
                                iconColor: .green
                            )
                        }
                        .padding(.horizontal, HIGSpacing.xs)

                        Spacer()

                        // 3. Tombol Logout / Keluar Kartun di Bagian Bawah
                        Button {
                            HapticManager.shared.warning()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                isShowingLogoutDialog = true
                            }
                        } label: {
                            HStack(spacing: HIGSpacing.xs) {
                                Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundColor(.red)
                                
                                Text("Keluar Akun")
                                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                                    .foregroundColor(.red)
                                
                                Spacer()
                            }
                            .padding(.vertical, HIGSpacing.sm)
                            .padding(.horizontal, HIGSpacing.md)
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(CartoonMetrics.cardCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                            .shadow(color: .black, radius: 0, x: 2.0, y: 2.0)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
                        .padding(.horizontal, HIGSpacing.xs)
                        .padding(.bottom, HIGSpacing.xl)
                    }
                    .padding(.horizontal, HIGSpacing.md)
                    .frame(width: 280, alignment: .leading)
                    .background(Color.cartoonBg)
                    .overlay(
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: CartoonMetrics.thickBorderWidth),
                        alignment: .trailing
                    )
                    .ignoresSafeArea(.all, edges: .vertical)
                    .shadow(color: .black.opacity(0.25), radius: 12, x: 6, y: 0)

                    Spacer()
                }
                .transition(.move(edge: .leading))
            }

            // Dialog Konfirmasi Logout dari Sidebar
            if isShowingLogoutDialog {
                CartoonConfirmDialog(
                    title: "Keluar Akun?",
                    message: "Apakah kamu yakin ingin keluar?",
                    icon: "rectangle.portrait.and.arrow.right.fill",
                    iconBgColor: Color(red: 1.0, green: 0.92, blue: 0.92),
                    iconFgColor: Color.cartoonCoral,
                    cancelTitle: "Batal",
                    confirmTitle: "Ya, Keluar",
                    confirmColor: Color.cartoonCoral,
                    onCancel: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            isShowingLogoutDialog = false
                        }
                    },
                    onConfirm: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isShowingLogoutDialog = false
                            isOpen = false
                            isLoggedIn = false
                        }
                    }
                )
            }
        }
    }
}

// Komponen Tombol Menu Kartu Kartun Kompak
struct CartoonMenuPill: View {
    let icon: String
    let title: String
    var count: Int?
    var bgColor: Color
    var iconColor: Color

    var body: some View {
        Button {
            HapticManager.shared.impact(style: .light)
        } label: {
            HStack(spacing: HIGSpacing.xs) {
                // Wadah Ikon Bulat Putih dengan Border
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.4))
                    
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(iconColor)
                }

                // Judul Menu Tebal tapi Kompak
                Text(title)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)

                Spacer()

                // Badge Counter Kartun
                if let count = count {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.black, lineWidth: 1.2)
                        )
                }
            }
            .padding(.horizontal, HIGSpacing.sm)
            .padding(.vertical, 8)
            .background(bgColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: 1.6)
            )
            .shadow(color: .black, radius: 0, x: 2, y: 2)
        }
        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
    }
}

#Preview {
    SidebarView(isOpen: .constant(true))
        .modelContainer(for: Item.self, inMemory: true)
}
