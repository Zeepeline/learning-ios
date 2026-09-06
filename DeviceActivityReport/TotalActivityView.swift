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
        VStack(alignment: .leading, spacing: 10) {
            // 1. Ringkasan Durasi Pemakaian Target
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.99, green: 0.88, blue: 0.55))
                        .frame(width: 40, height: 40)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                        .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                    
                    Image(systemName: "hourglass.bottomhalf.filled")
                        .font(.system(size: 17, weight: .black))
                        .foregroundColor(.black)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("TOTAL DURASI APLIKASI DIBATASI")
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text(reportData.formattedTotal)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                }
                
                Spacer()
            }
            .padding(10)
            .background(Color.white)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1.2))
            
            // 2. Rincian Pemakaian per Aplikasi Target (Jika ada)
            if !reportData.appItems.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("RINCIAN PER APLIKASI")
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                    
                    VStack(spacing: 6) {
                        ForEach(reportData.appItems) { item in
                            HStack(spacing: 9) {
                                // 1. Kotak Icon Aplikasi
                                if let token = item.token {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 7)
                                            .fill(Color(red: 0.93, green: 0.90, blue: 0.98))
                                            .frame(width: 28, height: 28)
                                            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.black, lineWidth: 1.1))
                                        
                                        Label(token)
                                            .labelStyle(.iconOnly)
                                            .scaleEffect(0.8)
                                    }
                                } else {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 7)
                                            .fill(Color(red: 0.93, green: 0.90, blue: 0.98))
                                            .frame(width: 28, height: 28)
                                            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.black, lineWidth: 1.1))
                                        
                                        Image(systemName: "app.fill")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.black)
                                    }
                                }
                                
                                // 2. Tulisan Nama Aplikasi di Samping Icon
                                if !item.name.isEmpty {
                                    Text(item.name)
                                        .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else if let token = item.token {
                                    Label(token)
                                        .labelStyle(.titleOnly)
                                        .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    Text("Aplikasi")
                                        .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                Spacer()
                                
                                // 3. Badge Durasi Pemakaian Tiap App
                                Text(formatDuration(item.duration))
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3.5)
                                    .background(Color(red: 0.99, green: 0.88, blue: 0.55).opacity(0.6))
                                    .cornerRadius(6)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.0))
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1.0))
                        }
                    }
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.35, green: 0.80, blue: 0.65))
                    
                    Text("Aplikasi yang dibatasi belum digunakan hari ini. Tetap fokus!")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

#Preview {
    TotalActivityView(reportData: AppActivityReportData(
        totalTargetDuration: 1800,
        appItems: [
            AppUsageItem(token: nil, name: "Instagram", duration: 900),
            AppUsageItem(token: nil, name: "YouTube", duration: 900)
        ],
        formattedTotal: "30 Menit"
    ))
}
