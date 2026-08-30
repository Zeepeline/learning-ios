//
//  AddActivity.swift
//  learning
//
//  Created by macbook on 8/30/26.
//

import SwiftUI
import SwiftData

struct AddActivity: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // State untuk form input
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var dueDate: Date = Date()
    @State private var priority: String = "Normal"

    let priorityOptions = ["Rendah", "Normal", "Tinggi"]

    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Informasi Aktivitas
                Section("Aktivitas") {
                    TextField("Nama Kegiatan / Judul Tugas", text: $title)
                    TextField("Catatan Tambahan (opsional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Section 2: Jadwal & Prioritas
                Section("Detail Jadwal") {
                    DatePicker("Waktu Pengingat", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Prioritas", selection: $priority) {
                        ForEach(priorityOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                }
            }
            .navigationTitle("Aktivitas Baru")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Tombol Batal
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") {
                        dismiss()
                    }
                }
                
                // Tombol Simpan
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        saveActivity()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveActivity() {
        withAnimation {
            let newItem = Item(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes,
                timestamp: dueDate,
                isCompleted: false,
                priority: priority
            )
            modelContext.insert(newItem)
            dismiss()
        }
    }
}

#Preview {
    AddActivity()
        .modelContainer(for: Item.self, inMemory: true)
}
