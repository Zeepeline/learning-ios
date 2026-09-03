//
//  ImportantTasksView.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI
import SwiftData

struct ImportantTasksView: View {
    let items: [Item]
    let onEditItem: (Item) -> Void
    let onToggleItem: (Item) -> Void
    let onDeleteItem: (Item) -> Void

    private var importantItems: [Item] {
        items.filter { $0.priority == "Tinggi" }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            if importantItems.isEmpty {
                VStack(spacing: HIGSpacing.sm) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                        .padding(.top, HIGSpacing.xxl)
                    Text("Tidak Ada Tugas Prioritas Tinggi")
                        .font(.cartoonHeadline)
                    Text("Semua tugas penting Anda akan muncul di sini.")
                        .font(.cartoonSubheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                LazyVStack(spacing: HIGSpacing.sm) {
                    ForEach(importantItems) { item in
                        ActivityCardView(
                            item: item,
                            onToggle: { onToggleItem(item) },
                            onDelete: { onDeleteItem(item) },
                            onTap: {
                                HapticManager.shared.impact(style: .light)
                                onEditItem(item)
                            }
                        )
                    }
                }
                .padding(.horizontal, HIGSpacing.md)
                .padding(.top, HIGSpacing.sm)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 75)
        }
    }
}
