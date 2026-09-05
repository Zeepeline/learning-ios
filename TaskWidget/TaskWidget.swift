//
//  TaskWidget.swift
//  TaskWidget
//
//  Widget Bergaya Neo-Brutalism Kartun untuk Memantau Tugas Hari Ini
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - 1. Model Data Entri Widget
struct TaskWidgetEntry: TimelineEntry {
    let date: Date
    let todayTasks: [WidgetTaskItem]
    
    var pendingCount: Int {
        todayTasks.filter { !$0.isCompleted }.count
    }
    
    var completedCount: Int {
        todayTasks.filter { $0.isCompleted }.count
    }
}

struct WidgetTaskItem: Identifiable {
    let id: String
    let title: String
    let category: String
    let priority: String
    let timeFormatted: String
    let isCompleted: Bool
}

// MARK: - 2. Provider Pengambil Data SwiftData dari App Group
struct Provider: TimelineProvider {
    
    func placeholder(in context: Context) -> TaskWidgetEntry {
        TaskWidgetEntry(
            date: Date(),
            todayTasks: sampleTasks
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskWidgetEntry) -> Void) {
        let entry = TaskWidgetEntry(
            date: Date(),
            todayTasks: fetchTodayTasks()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskWidgetEntry>) -> Void) {
        let todayTasks = fetchTodayTasks()
        let entry = TaskWidgetEntry(date: Date(), todayTasks: todayTasks)
        
        // Refresh tiap 30 menit atau saat ada trigger reload dari App
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    // Helper Fetch SwiftData dari Shared Container
    private func fetchTodayTasks() -> [WidgetTaskItem] {
        let appGroupIdentifier = "group.com.gmedia.xlearning"
        let schema = Schema([Item.self])
        
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            return sampleTasks
        }
        
        let storeURL = containerURL.appendingPathComponent("learning.sqlite")
        let config = ModelConfiguration(schema: schema, url: storeURL)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
            
            let descriptor = FetchDescriptor<Item>(
                predicate: #Predicate { item in
                    item.timestamp >= startOfDay && item.timestamp < endOfDay
                },
                sortBy: [SortDescriptor(\.timestamp, order: .forward)]
            )
            
            let context = ModelContext(container)
            let items = try context.fetch(descriptor)
            
            if items.isEmpty {
                return []
            }
            
            return items.map { item in
                WidgetTaskItem(
                    id: item.title + item.timestamp.description,
                    title: item.title,
                    category: item.category.isEmpty ? "Tugas" : item.category,
                    priority: item.priority.isEmpty ? "Normal" : item.priority,
                    timeFormatted: item.timestamp.formatted(date: .omitted, time: .shortened),
                    isCompleted: item.isCompleted
                )
            }
        } catch {
            return sampleTasks
        }
    }
    
    private var sampleTasks: [WidgetTaskItem] {
        [
            WidgetTaskItem(id: "1", title: "Desain Wireframe App", category: "Design", priority: "Tinggi", timeFormatted: "09:00", isCompleted: false),
            WidgetTaskItem(id: "2", title: "Daily Standup Meeting", category: "Meeting", priority: "Normal", timeFormatted: "10:30", isCompleted: true),
            WidgetTaskItem(id: "3", title: "Bug Fixing Auth & UI", category: "Coding", priority: "Normal", timeFormatted: "14:00", isCompleted: false)
        ]
    }
}

// MARK: - 3. Tampilan Kartun Neo-Brutalism untuk Widget
struct TaskWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallWidgetView
            case .systemMedium:
                mediumWidgetView
            default:
                mediumWidgetView
            }
        }
        .environment(\.colorScheme, .light)
    }

    // MARK: - 🌟 Small Widget View
    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header Pill
            HStack {
                Text("HARI INI")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(red: 1.0, green: 0.90, blue: 0.40)) // cartoonYellow
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.2))

                Spacer()

                Image(systemName: "checklist")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
            }

            Spacer()

            if entry.todayTasks.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Santai!")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                    Text("Tidak ada tugas")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.black.opacity(0.6))
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.pendingCount)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.black)

                    Text(entry.pendingCount == 0 ? "Semua Beres!" : "Tugas Tersisa")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(entry.pendingCount == 0 ? Color(red: 0.15, green: 0.65, blue: 0.30) : Color.black.opacity(0.65))
                }

                if let nextTask = entry.todayTasks.first(where: { !$0.isCompleted }) {
                    Text(nextTask.title)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .padding(.top, 2)
                }
            }
        }
        .containerBackground(Color(red: 0.99, green: 0.98, blue: 0.94), for: .widget)
    }

    // MARK: - 🌟 Medium Widget View
    private var mediumWidgetView: some View {
        HStack(spacing: 12) {
            // Kolom Kiri: Ringkasan Status
            VStack(alignment: .leading, spacing: 6) {
                // Tanggal Hari Ini
                Text(entry.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color(red: 0.68, green: 0.85, blue: 0.90)) // cartoonSky
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.2))

                Spacer()

                Text("\(entry.pendingCount)")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.black)

                Text(entry.pendingCount == 0 ? "Semua Selesai" : "Tugas Pending")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color.black.opacity(0.7))
            }
            .frame(width: 105, alignment: .leading)

            // Garis Pembatas Vertikal Kartun
            Rectangle()
                .fill(Color.black)
                .frame(width: 1.5)
                .padding(.vertical, 2)

            // Kolom Kanan: Daftar 2-3 Tugas Terdekat
            VStack(alignment: .leading, spacing: 6) {
                if entry.todayTasks.isEmpty {
                    VStack(alignment: .center, spacing: 4) {
                        Spacer()
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.orange)
                        Text("Belum ada tugas hari ini!")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Color.black.opacity(0.6))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(entry.todayTasks.prefix(3)) { task in
                        HStack(spacing: 6) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(task.isCompleted ? Color(red: 0.15, green: 0.65, blue: 0.30) : Color.black)

                            Text(task.title)
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                                .strikethrough(task.isCompleted, color: .black)
                                .lineLimit(1)

                            Spacer()

                            Text(task.timeFormatted)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(Color.black.opacity(0.6))
                        }
                        .padding(.vertical, 2)
                    }
                    Spacer()
                }
            }
        }
        .containerBackground(Color(red: 0.99, green: 0.98, blue: 0.94), for: .widget)
    }
}

// MARK: - 4. Konfigurasi Target Widget
struct TaskWidget: Widget {
    let kind: String = "TaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TaskWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Jadwal Tugas Harian")
        .description("Pantau daftar dan status tugas hari ini dalam gaya kartun seru.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
