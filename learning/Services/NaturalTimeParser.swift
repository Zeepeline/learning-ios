//
//  NaturalTimeParser.swift
//  learning
//
//  Created by macbook on 9/20/26.
//

import Foundation

// MARK: - Natural Indonesian Date & Time Parser
struct ParsedNaturalSchedule: Sendable {
    let targetDate: Date
    let cleanText: String
    let hasExplicitTime: Bool
    let formattedScheduleDescription: String
    let explicitCategory: TaskCategory?
    let explicitPriority: TaskPriority?
    let explicitRecurrence: RecurrenceRule?
    let notes: String?
}

enum NaturalTimeParser {
    /// Menganalisis kalimat bahasa Indonesia untuk mendeteksi tanggal, hari, jam, kategori, prioritas, dan perulangan
    static func parse(from text: String, baseDate: Date = Date()) -> ParsedNaturalSchedule {
        var clean = text
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "id_ID")
        let now = baseDate

        var targetComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        var hasExplicitDate = false
        var hasExplicitHour = false
        var explicitCategory: TaskCategory? = nil
        var explicitPriority: TaskPriority? = nil
        var explicitRecurrence: RecurrenceRule? = nil
        var explicitNotes: String? = nil

        let lower = text.lowercased()

        // 1. Deteksi Catatan / Notes (e.g., "catatan: bawa laptop", "notes: siapkan slide")
        if let notesRange = clean.range(of: "(?i)(catatan|notes|note|keterangan):\\s*(.+)$", options: .regularExpression) {
            let matchedStr = String(clean[notesRange])
            if let colonIdx = matchedStr.firstIndex(of: ":") {
                let noteVal = String(matchedStr[matchedStr.index(after: colonIdx)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !noteVal.isEmpty {
                    explicitNotes = noteVal
                }
            }
            clean.removeSubrange(notesRange)
        }

        // 2. Deteksi Prioritas Eksplisit
        if let prioRange = clean.range(of: "(?i)\\b(prioritas\\s+tinggi|prioritas\\s+urgent|prioritas\\s+penting|urgent|penting\\s+banget)\\b", options: .regularExpression) {
            explicitPriority = .high
            clean.removeSubrange(prioRange)
        } else if let prioRange = clean.range(of: "(?i)\\b(prioritas\\s+rendah|prioritas\\s+santai|prioritas\\s+low)\\b", options: .regularExpression) {
            explicitPriority = .low
            clean.removeSubrange(prioRange)
        } else if let prioRange = clean.range(of: "(?i)\\b(prioritas\\s+normal|prioritas\\s+sedang|prioritas\\s+biasa)\\b", options: .regularExpression) {
            explicitPriority = .normal
            clean.removeSubrange(prioRange)
        }

        // 3. Deteksi Kategori Eksplisit (e.g. "kategori Belajar", "kategori Coding", "kategori Kesehatan")
        for cat in TaskCategory.allCases {
            let catPattern = "(?i)\\b(kategori|category|tag)\\s+\(cat.rawValue.lowercased())\\b"
            if let catRange = clean.range(of: catPattern, options: .regularExpression) {
                explicitCategory = cat
                clean.removeSubrange(catRange)
                break
            }
        }

        // 4. Deteksi Perulangan / Recurrence Eksplisit
        if let recRange = clean.range(of: "(?i)\\b(setiap\\s+hari|tiap\\s+hari|harian|daily|setiap\\s+hari\\s+kerja|hari\\s+kerja|senin-jumat|akhir\\s+pekan|sabtu-minggu|setiap\\s+minggu|tiap\\s+minggu|mingguan)\\b", options: .regularExpression) {
            let recText = String(clean[recRange]).lowercased()
            if recText.contains("kerja") || recText.contains("senin-jumat") {
                explicitRecurrence = .weekdays
            } else if recText.contains("akhir pekan") || recText.contains("sabtu-minggu") {
                explicitRecurrence = .weekends
            } else if recText.contains("minggu") && !recText.contains("senin") {
                explicitRecurrence = .weekly
            } else {
                explicitRecurrence = .daily
            }
            clean.removeSubrange(recRange)
        }

        // 5. Deteksi Hari / Tanggal Relatif
        if lower.contains("lusa") {
            if let lusaDate = calendar.date(byAdding: .day, value: 2, to: now) {
                let comps = calendar.dateComponents([.year, .month, .day], from: lusaDate)
                targetComponents.year = comps.year
                targetComponents.month = comps.month
                targetComponents.day = comps.day
                hasExplicitDate = true
            }
            clean = removePattern(clean, pattern: "(?i)\\blusa\\b")
        } else if lower.contains("besok") {
            if let besokDate = calendar.date(byAdding: .day, value: 1, to: now) {
                let comps = calendar.dateComponents([.year, .month, .day], from: besokDate)
                targetComponents.year = comps.year
                targetComponents.month = comps.month
                targetComponents.day = comps.day
                hasExplicitDate = true
            }
            clean = removePattern(clean, pattern: "(?i)\\bbesok\\b")
        } else if lower.contains("hari ini") {
            hasExplicitDate = true
            clean = removePattern(clean, pattern: "(?i)\\bhari\\s+ini\\b")
        }

        // 6. Deteksi Hari Tertentu (Senin..Minggu)
        let dayNames: [String: Int] = [
            "minggu": 1, "senin": 2, "selasa": 3, "rabu": 4, "kamis": 5, "jumat": 6, "sabtu": 7
        ]
        for (dayName, weekdayNum) in dayNames {
            let regexStr = "(?i)\\bhari\\s+\(dayName)\\b|\\b\(dayName)\\b"
            if let matchRange = clean.range(of: regexStr, options: .regularExpression) {
                let currentWeekday = calendar.component(.weekday, from: now)
                var daysToAdd = weekdayNum - currentWeekday
                if daysToAdd <= 0 { daysToAdd += 7 } // Next occurrence

                if let nextTarget = calendar.date(byAdding: .day, value: daysToAdd, to: now) {
                    let comps = calendar.dateComponents([.year, .month, .day], from: nextTarget)
                    targetComponents.year = comps.year
                    targetComponents.month = comps.month
                    targetComponents.day = comps.day
                    hasExplicitDate = true
                }
                clean.removeSubrange(matchRange)
                break
            }
        }

        // 7. Deteksi Relatif Menit / Jam ke Depan ("30 menit lagi", "2 jam lagi")
        if let match = matchRegex(in: clean, pattern: "(?i)(\\d+)\\s*(menit|mnt)\\s*(lagi|ke\\s*depan)?") {
            if let minutesVal = Int(match.groups[0]), let future = calendar.date(byAdding: .minute, value: minutesVal, to: now) {
                let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: future)
                targetComponents = comps
                hasExplicitDate = true
                hasExplicitHour = true
                clean = removePattern(clean, pattern: "(?i)\\b\\d+\\s*(menit|mnt)(\\s*(lagi|ke\\s*depan))?\\b")
            }
        } else if let match = matchRegex(in: clean, pattern: "(?i)(\\d+)\\s*(jam)\\s*(lagi|ke\\s*depan)?") {
            if let hoursVal = Int(match.groups[0]), let future = calendar.date(byAdding: .hour, value: hoursVal, to: now) {
                let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: future)
                targetComponents = comps
                hasExplicitDate = true
                hasExplicitHour = true
                clean = removePattern(clean, pattern: "(?i)\\b\\d+\\s*(jam)(\\s*(lagi|ke\\s*depan))?\\b")
            }
        }

        // 8. Deteksi Waktu / Jam Eksplisit ("jam 8 malam", "pukul 14.30", "jam 07:00", "jam 2 siang")
        var hour: Int = 9
        var minute: Int = 0

        let timeRegex = "(?i)\\b(jam|pukul|pk)\\s*(\\d{1,2})([.:](\\d{2}))?\\s*(pagi|siang|sore|malam)?"
        if let match = matchRegex(in: clean, pattern: timeRegex) {
            let rawHourStr = match.groups[1]
            let rawMinStr = match.groups[3]
            let modifier = match.groups[4].lowercased()

            if var parsedHour = Int(rawHourStr) {
                let parsedMin = Int(rawMinStr) ?? 0

                if modifier == "malam" && parsedHour < 12 {
                    parsedHour += 12
                } else if modifier == "sore" && parsedHour < 12 {
                    parsedHour += 12
                } else if modifier == "siang" && parsedHour <= 5 {
                    parsedHour += 12
                }

                hour = min(max(parsedHour, 0), 23)
                minute = min(max(parsedMin, 0), 59)
                hasExplicitHour = true
            }

            clean = removePattern(clean, pattern: timeRegex)
        } else {
            // Cek kata waktu tanpa angka (misal: "besok malam", "nanti sore")
            if lower.contains("malam") {
                hour = 20
                minute = 0
                hasExplicitHour = true
                clean = removePattern(clean, pattern: "(?i)\\bmalam\\b")
            } else if lower.contains("sore") {
                hour = 16
                minute = 30
                hasExplicitHour = true
                clean = removePattern(clean, pattern: "(?i)\\bsore\\b")
            } else if lower.contains("siang") {
                hour = 13
                minute = 0
                hasExplicitHour = true
                clean = removePattern(clean, pattern: "(?i)\\bsiang\\b")
            } else if lower.contains("pagi") {
                hour = 8
                minute = 0
                hasExplicitHour = true
                clean = removePattern(clean, pattern: "(?i)\\bpagi\\b")
            }
        }

        if hasExplicitHour {
            targetComponents.hour = hour
            targetComponents.minute = minute
        }

        var finalDate = calendar.date(from: targetComponents) ?? now
        // Jika hanya memasukkan jam tanpa tanggal dan jam tersebut sudah lewat hari ini, arahkan ke besok
        if !hasExplicitDate && hasExplicitHour && finalDate < now {
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: finalDate) {
                finalDate = nextDay
            }
        }

        // Format deskripsi ramah untuk user
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "id_ID")
        if calendar.isDateInToday(finalDate) {
            dateFormatter.dateFormat = "'Hari ini, pukul' HH:mm"
        } else if calendar.isDateInTomorrow(finalDate) {
            dateFormatter.dateFormat = "'Besok, pukul' HH:mm"
        } else {
            dateFormatter.dateFormat = "EEEE, d MMM 'pukul' HH:mm"
        }

        let scheduleDesc = dateFormatter.string(from: finalDate)

        // Bersihkan prefix pembuatan tugas ("tambahkan tugas", "buat task", "ingatkan", dsb)
        clean = sanitizeTaskTitle(clean)

        return ParsedNaturalSchedule(
            targetDate: finalDate,
            cleanText: clean,
            hasExplicitTime: hasExplicitDate || hasExplicitHour,
            formattedScheduleDescription: scheduleDesc,
            explicitCategory: explicitCategory,
            explicitPriority: explicitPriority,
            explicitRecurrence: explicitRecurrence,
            notes: explicitNotes
        )
    }

    /// Membersihkan kata-kata perintah seperti "tolong tambahkan task", "buatkan jadwal", dsb.
    static func sanitizeTaskTitle(_ raw: String) -> String {
        var clean = raw
        let prefixes = [
            "(?i)^tolong\\s+(tambahkan|buatkan|bikinkan|catatkan)?\\s*(tugas|task|to-?do|agenda|jadwal)?\\s*(baru)?\\s*(:|yaitu|untuk)?\\s*",
            "(?i)^tambahkan\\s+(tugas|task|to-?do|agenda|jadwal)?\\s*(baru)?\\s*(:|yaitu|untuk)?\\s*",
            "(?i)^tambahin\\s+(tugas|task|to-?do|agenda|jadwal)?\\s*(baru)?\\s*(:|yaitu|untuk)?\\s*",
            "(?i)^tambah\\s+(tugas|task|to-?do|agenda|jadwal)?\\s*(baru)?\\s*(:|yaitu|untuk)?\\s*",
            "(?i)^buatkan\\s+(tugas|task|to-?do|agenda|jadwal)?\\s*(baru)?\\s*(:|yaitu|untuk)?\\s*",
            "(?i)^buat\\s+(tugas|task|to-?do|agenda|jadwal)?\\s*(baru)?\\s*(:|yaitu|untuk)?\\s*",
            "(?i)^bikin\\s+(tugas|task|to-?do|agenda|jadwal)?\\s*(baru)?\\s*(:|yaitu|untuk)?\\s*",
            "(?i)^add\\s+(task|todo|to-?do)?\\s*(:|to|for)?\\s*",
            "(?i)^create\\s+(task|todo|to-?do)?\\s*(:|to|for)?\\s*",
            "(?i)^jadwalkan\\s+(tugas|task|to-?do|agenda)?\\s*(:|yaitu|untuk)?\\s*",
            "(?i)^agendakan\\s+(tugas|task|to-?do|agenda)?\\s*(:|yaitu|untuk)?\\s*",
            "(?i)^ingatkan\\s+(saya\\s+)?(untuk\\s+)?",
            "(?i)^remind\\s+(me\\s+)?(to\\s+)?",
            "(?i)^catat\\s+(tugas|task|to-?do|agenda)?\\s*(:|yaitu|untuk)?\\s*",
            "(?i)^masukkan\\s+(tugas|task|to-?do|agenda)?\\s*(:|yaitu|untuk)?\\s*"
        ]
        for p in prefixes {
            clean = removePattern(clean, pattern: p)
        }

        clean = clean.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)

        guard let firstChar = clean.first else { return clean }
        return String(firstChar).uppercased() + String(clean.dropFirst())
    }

    private static func removePattern(_ input: String, pattern: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return input }
        let range = NSRange(location: 0, length: input.utf16.count)
        return regex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: " ")
    }

    private struct RegexMatchResult {
        let fullMatch: String
        let groups: [String]
    }

    private static func matchRegex(in text: String, pattern: String) -> RegexMatchResult? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let nsString = text as NSString
        let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        guard let first = results.first else { return nil }
        var groups: [String] = []

        for i in 1..<first.numberOfRanges {
            let groupRange = first.range(at: i)
            if groupRange.location != NSNotFound {
                groups.append(nsString.substring(with: groupRange))
            } else {
                groups.append("")
            }
        }

        return RegexMatchResult(fullMatch: nsString.substring(with: first.range), groups: groups)
    }
}
