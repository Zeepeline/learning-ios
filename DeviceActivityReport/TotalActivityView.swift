//
//  TotalActivityView.swift
//  DeviceActivityReportExtension
//
//  Created by macbook on 9/5/26.
//

import SwiftUI
import FamilyControls

struct TotalActivityView: View {
    let reportData: AppActivityReportData
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours > 0 {
            return remainingMinutes > 0 ? "\(hours)j \(remainingMinutes)m" : "\(hours) Jam"
        } else {
            return "\(max(minutes, 1)) Menit"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 1. Ringkasan Durasi Pemakaian Target
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.99, green: 0.88, blue: 0.55))
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.3))
                        .shadow(color: .black, radius: 0, x: 1.2, y: 1.2)
                    
                    Image(systemName: "hourglass.bottomhalf.filled")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.black)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("TOTAL DURASI APLIKASI DIBATASI")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text(reportData.formattedTotal)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
                
                Spacer()
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Color.white)
            .cornerRadius(9)
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.black, lineWidth: 1.1))
            
            // 2. Rincian Pemakaian per Aplikasi Target (Jika ada)
            if !reportData.appItems.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("RINCIAN PER APLIKASI")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 4) {
                        ForEach(reportData.appItems) { item in
                            HStack(spacing: 8) {
                                // 1. Kotak Icon Aplikasi
                                if let token = item.token {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(red: 0.93, green: 0.90, blue: 0.98))
                                            .frame(width: 24, height: 24)
                                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
                                        
                                        Label(token)
                                            .labelStyle(.iconOnly)
                                            .scaleEffect(0.7)
                                    }
                                } else {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(red: 0.93, green: 0.90, blue: 0.98))
                                            .frame(width: 24, height: 24)
                                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
                                        
                                        Image(systemName: "app.fill")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.black)
                                    }
                                }
                                
                                // 2. Tulisan Nama Aplikasi di Samping Icon
                                if !item.name.isEmpty {
                                    Text(item.name)
                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else if let token = item.token {
                                    Label(token)
                                        .labelStyle(.titleOnly)
                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    Text("Aplikasi")
                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                Spacer()
                                
                                // 3. Badge Durasi Pemakaian Tiap App
                                Text(formatDuration(item.duration))
                                    .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2.5)
                                    .background(Color(red: 0.99, green: 0.88, blue: 0.55).opacity(0.6))
                                    .cornerRadius(5)
                                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.black, lineWidth: 0.9))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4.5)
                            .background(Color.white)
                            .cornerRadius(7)
                            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.black, lineWidth: 0.9))
                        }
                    }
                }
            } else {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.35, green: 0.80, blue: 0.65))
                    
                    Text("Aplikasi yang dibatasi belum digunakan hari ini. Tetap fokus!")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 2)
            }
        }
    }
}
