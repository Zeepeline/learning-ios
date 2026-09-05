//
//  TotalActivityView.swift
//  DeviceActivityReportExtension
//
//  Created by macbook on 9/5/26.
//

import SwiftUI

struct TotalActivityView: View {
    let totalActivity: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.99, green: 0.88, blue: 0.55))
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                
                Image(systemName: "hourglass")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("DURASI PENGGUNAAN HARI INI")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(.secondary)
                
                Text(totalActivity)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(10)
    }
}

#Preview {
    TotalActivityView(totalActivity: "1 jam 23 menit")
}
