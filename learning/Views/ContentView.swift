//
//  ContentView.swift
//  learning
//
//  Created by macbook on 8/29/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State private var isShowingAddActivity = false
    @State private var isSidebarOpen = false

    var body: some View {
        ZStack {
            // 1. Konten Layar Utama
            NavigationStack {
                List {
                    ForEach(items) { item in
                        NavigationLink {
                            Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        } label: {
                            Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .navigationTitle("Aktivitas")
                .toolbar {
                    // Tombol Hamburger Menu di Kiri Atas
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isSidebarOpen.toggle()
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                        }
                    }

                    // Tombol Edit & Tambah di Kanan Atas
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button {
                            isShowingAddActivity = true
                        } label: {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
                .sheet(isPresented: $isShowingAddActivity) {
                    AddActivity()
                }
            }

            // 2. Custom Drawer Sidebar Menu di Atas Layar Utama
            SidebarView(isOpen: $isSidebarOpen)
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
