//
//  EditProfileView.swift
//  learning
//
//  Created by macbook on 9/6/26.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("userName") private var storedName: String = "Bruce Wayne"
    @AppStorage("userEmail") private var storedEmail: String = "brucewayne27@suarasa.com"
    @AppStorage("userBio") private var storedBio: String = "Productivity Master"
    @AppStorage("userAvatarIcon") private var storedAvatarIcon: String = "person.crop.circle.fill"
    @AppStorage("userAvatarColor") private var storedAvatarColor: String = "#FFD166"

    @State private var nameText: String = ""
    @State private var emailText: String = ""
    @State private var bioText: String = ""
    @State private var selectedAvatarIcon: String = "person.crop.circle.fill"
    @State private var selectedColorHex: String = "#FFD166"

    private let avatarIcons: [String] = [
        "person.crop.circle.fill",
        "star.circle.fill",
        "bolt.circle.fill",
        "heart.circle.fill",
        "sparkles",
        "crown.fill",
        "flame.fill",
        "brain.head.profile"
    ]

    private let avatarColors: [(name: String, hex: String, color: Color)] = [
        ("Kuning", "#FFD166", .cartoonYellow),
        ("Pink", "#FF99C8", .cartoonPink),
        ("Mint", "#6EE7B7", .cartoonMint),
        ("Biru", "#A0C4FF", .cartoonBlue),
        ("Lavender", "#DDA0DD", .cartoonLavender),
        ("Oranye", "#FFAA00", .cartoonOrange)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cartoonBg
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: HIGSpacing.lg) {
                        // MARK: - 🎨 Avatar Preview & Selector
                        avatarPreviewSection

                        // MARK: - 📝 Form Input Fields
                        VStack(spacing: HIGSpacing.md) {
                            // Field Nama Lengkap
                            cartoonInputField(
                                title: "NAMA LENGKAP",
                                icon: "person.fill",
                                placeholder: "Masukkan nama kamu",
                                text: $nameText
                            )

                            // Field Bio / Tagline
                            cartoonInputField(
                                title: "BIO / STATUS",
                                icon: "quote.bubble.fill",
                                placeholder: "Contoh: Productivity Master",
                                text: $bioText
                            )

                            // Field Email
                            cartoonInputField(
                                title: "EMAIL",
                                icon: "envelope.fill",
                                placeholder: "nama@domain.com",
                                text: $emailText,
                                keyboardType: .emailAddress
                            )
                        }
                        .padding(.horizontal, HIGSpacing.md)

                        // MARK: - 💾 Tombol Simpan
                        Button {
                            saveProfile()
                        } label: {
                            HStack(spacing: HIGSpacing.xs) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 15, weight: .black))
                                Text("Simpan Profil")
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.cartoonMint)
                            .cornerRadius(CartoonMetrics.cardCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
                            )
                            .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.2))
                        .padding(.horizontal, HIGSpacing.md)
                        .padding(.top, HIGSpacing.xs)
                        .padding(.bottom, HIGSpacing.xl)
                    }
                    .padding(.top, HIGSpacing.md)
                }
            }
            .navigationTitle("Edit Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticManager.shared.impact(style: .light)
                        dismiss()
                    } label: {
                        Text("Batal")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(.cartoonTextPrimary)
                    }
                }
            }
            .onAppear {
                nameText = storedName
                emailText = storedEmail
                bioText = storedBio
                selectedAvatarIcon = storedAvatarIcon
                selectedColorHex = storedAvatarColor
            }
        }
    }

    // MARK: - 🎨 Avatar Preview & Selector Section
    private var avatarPreviewSection: some View {
        VStack(spacing: HIGSpacing.md) {
            // Avatar Big Preview
            ZStack {
                Circle()
                    .fill(Color(hex: selectedColorHex))
                    .frame(width: 96, height: 96)
                    .overlay(
                        Circle().stroke(Color.black, lineWidth: CartoonMetrics.thickBorderWidth)
                    )
                    .shadow(color: .black, radius: 0, x: 3, y: 3)

                Image(systemName: selectedAvatarIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
                    .foregroundColor(.black)
            }

            // Pilihan Warna Avatar
            VStack(alignment: .leading, spacing: HIGSpacing.xs) {
                Text("WARNA BACKGROUND AVATAR")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)

                HStack(spacing: HIGSpacing.sm) {
                    ForEach(avatarColors, id: \.hex) { item in
                        Button {
                            HapticManager.shared.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedColorHex = item.hex
                            }
                        } label: {
                            Circle()
                                .fill(item.color)
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Circle().stroke(Color.black, lineWidth: selectedColorHex == item.hex ? 2.5 : 1.5)
                                )
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .black))
                                        .foregroundColor(.black)
                                        .opacity(selectedColorHex == item.hex ? 1 : 0)
                                )
                                .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                        }
                        .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                    }
                }
            }
            .padding(.horizontal, HIGSpacing.md)

            // Pilihan Ikon Avatar
            VStack(alignment: .leading, spacing: HIGSpacing.xs) {
                Text("IKON AVATAR")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: HIGSpacing.xs) {
                        ForEach(avatarIcons, id: \.self) { icon in
                            Button {
                                HapticManager.shared.selection()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedAvatarIcon = icon
                                }
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(width: 44, height: 44)
                                    .background(selectedAvatarIcon == icon ? Color.cartoonYellow : Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.black, lineWidth: selectedAvatarIcon == icon ? 2.2 : 1.5)
                                    )
                                    .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                            }
                            .buttonStyle(CartoonPressButtonStyle(pressOffset: 1.0))
                        }
                    }
                    .padding(.horizontal, HIGSpacing.md)
                }
            }
        }
    }

    // MARK: - 🛠️ Reusable Cartoon Input Field
    private func cartoonInputField(
        title: String,
        icon: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 24)

                TextField(placeholder, text: text)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Color.white)
            .cornerRadius(CartoonMetrics.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: CartoonMetrics.cardCornerRadius)
                    .stroke(Color.black, lineWidth: CartoonMetrics.borderWidth)
            )
            .shadow(color: .black, radius: 0, x: 2, y: 2)
        }
    }

    // MARK: - 💾 Save Action
    private func saveProfile() {
        let trimmedName = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = emailText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBio = bioText.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedName.isEmpty {
            storedName = trimmedName
        }
        if !trimmedEmail.isEmpty {
            storedEmail = trimmedEmail
        }
        storedBio = trimmedBio.isEmpty ? "Productivity Master" : trimmedBio
        storedAvatarIcon = selectedAvatarIcon
        storedAvatarColor = selectedColorHex

        HapticManager.shared.success()
        dismiss()
    }
}

#Preview {
    EditProfileView()
}
