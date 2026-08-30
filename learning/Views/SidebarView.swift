//
//  SidebarView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI

struct SidebarView: View {
    @Binding var isOpen: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            // Latar Belakang Gelap Semi-Transparan
            if isOpen {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isOpen = false
                        }
                    }
            }

            // Panel Drawer Kartun Modern
            if isOpen {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // 1. Header Profil Vector
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.yellow)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black, lineWidth: 2)
                                    )
                                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                                
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 26, height: 26)
                                    .foregroundColor(.black)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Herlambang")
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                
                                // Badge Vector (Menggantikan Emoji Api)
                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.orange)
                                    
                                    Text("Level 5")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(.black)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.mint.opacity(0.8))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(Color.black, lineWidth: 1.5)
                                )
                            }

                            Spacer()

                            // Tombol Close Vector Silang
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    isOpen = false
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(6)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                            }
                        }
                        .padding(.top, 50)

                        // Garis Pemisah Kartun
                        Rectangle()
                            .fill(Color.black)
                            .frame(height: 2)
                            .padding(.vertical, 2)

                        // 2. Daftar Menu dengan Ikon Vector Murni
                        VStack(spacing: 10) {
                            CartoonSidebarRow(
                                icon: "list.clipboard.fill",
                                title: "Semua Tugas",
                                count: 8,
                                bgColor: Color(red: 0.99, green: 0.88, blue: 0.55), // Pastel Kuning
                                iconColor: .black
                            )
                            
                            CartoonSidebarRow(
                                icon: "sun.max.fill",
                                title: "Hari Ini",
                                count: 3,
                                bgColor: Color(red: 1.0, green: 0.78, blue: 0.78), // Pastel Pink
                                iconColor: .red
                            )
                            
                            CartoonSidebarRow(
                                icon: "bookmark.fill",
                                title: "Penting",
                                count: 2,
                                bgColor: Color(red: 0.78, green: 0.92, blue: 1.0), // Sky Blue
                                iconColor: .blue
                            )
                            
                            CartoonSidebarRow(
                                icon: "folder.badge.gearshape",
                                title: "Kategori",
                                bgColor: Color(red: 0.84, green: 0.95, blue: 0.84), // Mint Green
                                iconColor: .green
                            )
                            
                            CartoonSidebarRow(
                                icon: "slider.horizontal.3",
                                title: "Pengaturan",
                                bgColor: Color(red: 0.93, green: 0.87, blue: 1.0), // Lavender
                                iconColor: .purple
                            )
                        }

                        Spacer()

                        // 3. Banner Bawah (Vector Icon)
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Text("Tetap Produktif")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.black)

                            Image(systemName: "arrow.up.right.circle.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 2)
                        )
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                        .padding(.bottom, 25)
                    }
                    .padding(.horizontal, 16)
                    .frame(width: 260, alignment: .leading)
                    .background(Color(red: 0.98, green: 0.96, blue: 0.92))
                    .overlay(
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 2.5),
                        alignment: .trailing
                    )
                    .ignoresSafeArea(.all, edges: .vertical)
                    .shadow(color: .black.opacity(0.3), radius: 12, x: 6, y: 0)

                    Spacer()
                }
                .transition(.move(edge: .leading))
            }
        }
    }
}

// Komponen Tombol Menu Kartun
struct CartoonSidebarRow: View {
    let icon: String
    let title: String
    var count: Int? = nil
    var bgColor: Color
    var iconColor: Color

    var body: some View {
        Button {
            // Aksi menu
        } label: {
            HStack(spacing: 10) {
                // Wadah Ikon Vector
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 30, height: 30)
                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(iconColor)
                }

                // Judul Menu
                Text(title)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                Spacer()

                // Badge Counter Vector
                if let count = count {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.black, lineWidth: 1.5)
                        )
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(bgColor)
            .cornerRadius(11)
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .stroke(Color.black, lineWidth: 2)
            )
            .shadow(color: .black, radius: 0, x: 2, y: 2)
        }
        .buttonStyle(CartoonPressButtonStyle())
    }
}

// Efek Tombol Membal (Bouncy Press)
struct CartoonPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(x: configuration.isPressed ? 1.5 : 0, y: configuration.isPressed ? 1.5 : 0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    SidebarView(isOpen: .constant(true))
}
