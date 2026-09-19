//
//  MotivationalQuoteService.swift
//  learning
//
//  Created by macbook on 9/19/26.
//

import Foundation
import SwiftUI
import Combine

struct DailyQuote: Codable, Equatable {
    let quote: String
    let author: String
    let category: String
}

@MainActor
final class MotivationalQuoteService: ObservableObject {
    static let shared = MotivationalQuoteService()

    @Published var currentQuote: DailyQuote = DailyQuote(
        quote: "The future belongs to those who believe in the beauty of their dreams.",
        author: "Eleanor Roosevelt",
        category: "Motivation"
    )
    @Published var isLoading: Bool = false

    private let cacheKeyQuote = "cached_daily_quote_text"
    private let cacheKeyAuthor = "cached_daily_quote_author"
    private let cacheKeyCategory = "cached_daily_quote_category"
    private let cacheKeyDate = "cached_daily_quote_date"

    // 📚 Curated Offline Backup Quotes (English & Indonesian)
    private let curatedQuotes: [DailyQuote] = [
        DailyQuote(quote: "The only way to do great work is to love what you do.", author: "Steve Jobs", category: "Inspiration"),
        DailyQuote(quote: "Focus on progress, not perfection. Consistency beats talent.", author: "James Clear", category: "Habits"),
        DailyQuote(quote: "It always seems impossible until it is done.", author: "Nelson Mandela", category: "Perseverance"),
        DailyQuote(quote: "Start where you are. Use what you have. Do what you can.", author: "Arthur Ashe", category: "Motivation"),
        DailyQuote(quote: "Discipline is the bridge between goals and accomplishment.", author: "Jim Rohn", category: "Discipline"),
        DailyQuote(quote: "You don't have to be great to start, but you have to start to be great.", author: "Zig Ziglar", category: "Action"),
        DailyQuote(quote: "The secret of getting ahead is getting started.", author: "Mark Twain", category: "Productivity"),
        DailyQuote(quote: "Small daily improvements over time lead to stunning results.", author: "Robin Sharma", category: "Growth"),
        DailyQuote(quote: "Do what you can, with what you have, where you are.", author: "Theodore Roosevelt", category: "Action"),
        DailyQuote(quote: "Believe you can and you're halfway there.", author: "Theodore Roosevelt", category: "Mindset"),
        DailyQuote(quote: "Action is the foundational key to all success.", author: "Pablo Picasso", category: "Action"),
        DailyQuote(quote: "Don't watch the clock; do what it does. Keep going.", author: "Sam Levenson", category: "Focus"),
        DailyQuote(quote: "Your time is limited, so don't waste it living someone else's life.", author: "Steve Jobs", category: "Wisdom"),
        DailyQuote(quote: "Success is the sum of small efforts, repeated day in and day out.", author: "Robert Collier", category: "Consistency"),
        DailyQuote(quote: "Langkah kecil setiap hari akan menghasilkan perubahan besar di masa depan.", author: "Kaizen", category: "Produktivitas")
    ]

    private init() {
        loadCachedQuote()
    }

    /// Load quote harian: cek apakah tanggal hari ini sudah punya quote di cache, jika belum fetch online/curated
    func loadDailyQuoteIfNeeded() {
        let todayStr = todayDateKey()
        let cachedDate = UserDefaults.standard.string(forKey: cacheKeyDate)

        if cachedDate == todayStr,
           let cachedQuote = UserDefaults.standard.string(forKey: cacheKeyQuote),
           let cachedAuthor = UserDefaults.standard.string(forKey: cacheKeyAuthor) {
            let cat = UserDefaults.standard.string(forKey: cacheKeyCategory) ?? "Today"
            self.currentQuote = DailyQuote(quote: cachedQuote, author: cachedAuthor, category: cat)
            return
        }

        // Ambil quote baru untuk hari ini
        Task {
            await fetchFreshQuote()
        }
    }

    /// Fetch quote baru secara online dari API publik (ZenQuotes / Quotable / DummyJSON) dengan fallback
    func fetchFreshQuote() async {
        isLoading = true
        defer { isLoading = false }

        // 1. Coba ZenQuotes API
        if let quote = await fetchFromZenQuotes() {
            self.currentQuote = quote
            saveToCache(quote)
            return
        }

        // 2. Coba Quotable API
        if let quote = await fetchFromQuotable() {
            self.currentQuote = quote
            saveToCache(quote)
            return
        }

        // 3. Coba DummyJSON Quotes API
        if let quote = await fetchFromDummyJSON() {
            self.currentQuote = quote
            saveToCache(quote)
            return
        }

        // 4. Fallback offline: Gunakan kurasi berdasarkan nomor hari dalam tahun (Rotasi otomatis 365 hari)
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = dayOfYear % curatedQuotes.count
        let chosen = curatedQuotes[index]
        self.currentQuote = chosen
        saveToCache(chosen)
    }

    /// Shuffle / Ganti quote secara interaktif saat tombol ditekan
    func shuffleQuote() {
        HapticManager.shared.impact(style: .medium)
        Task {
            isLoading = true
            defer { isLoading = false }

            // 1. Coba ambil random quote dari ZenQuotes
            if let quote = await fetchFromZenQuotes(random: true) {
                self.currentQuote = quote
                saveToCache(quote)
                return
            }

            // 2. Coba Quotable API
            if let quote = await fetchFromQuotable() {
                self.currentQuote = quote
                saveToCache(quote)
                return
            }

            // 3. Coba DummyJSON
            if let quote = await fetchFromDummyJSON() {
                self.currentQuote = quote
                saveToCache(quote)
                return
            }

            // Fallback offline shuffle
            let remaining = curatedQuotes.filter { $0.quote != currentQuote.quote }
            if let randomQuote = remaining.randomElement() {
                self.currentQuote = randomQuote
                saveToCache(randomQuote)
            }
        }
    }

    // MARK: - 1. ZenQuotes API (https://zenquotes.io)
    private func fetchFromZenQuotes(random: Bool = false) async -> DailyQuote? {
        let endpoint = random ? "https://zenquotes.io/api/random" : "https://zenquotes.io/api/today"
        guard let url = URL(string: endpoint) else { return nil }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 4.0
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }

            struct ZenQuote: Codable {
                let q: String // Quote
                let a: String // Author
            }

            let decoded = try JSONDecoder().decode([ZenQuote].self, from: data)
            if let first = decoded.first, !first.q.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return DailyQuote(quote: first.q.trimmingCharacters(in: .whitespacesAndNewlines), author: first.a.isEmpty ? "Unknown" : first.a, category: "ZenQuotes")
            }
            return nil
        } catch {
            return nil
        }
    }

    // MARK: - 2. Quotable API (https://api.quotable.io)
    private func fetchFromQuotable() async -> DailyQuote? {
        guard let url = URL(string: "https://api.quotable.io/random?tags=motivational|inspirational") else { return nil }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 4.0
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }

            struct QuotableResponse: Codable {
                let content: String
                let author: String
            }

            let decoded = try JSONDecoder().decode(QuotableResponse.self, from: data)
            return DailyQuote(quote: decoded.content.trimmingCharacters(in: .whitespacesAndNewlines), author: decoded.author.isEmpty ? "Unknown" : decoded.author, category: "Quotable")
        } catch {
            return nil
        }
    }

    // MARK: - 3. DummyJSON Quotes API (https://dummyjson.com/quotes/random)
    private func fetchFromDummyJSON() async -> DailyQuote? {
        guard let url = URL(string: "https://dummyjson.com/quotes/random") else { return nil }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 4.0
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }

            struct DummyJSONQuote: Codable {
                let quote: String
                let author: String
            }

            let decoded = try JSONDecoder().decode(DummyJSONQuote.self, from: data)
            return DailyQuote(quote: decoded.quote.trimmingCharacters(in: .whitespacesAndNewlines), author: decoded.author.isEmpty ? "Unknown" : decoded.author, category: "Inspiration")
        } catch {
            return nil
        }
    }

    private func todayDateKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func saveToCache(_ quote: DailyQuote) {
        UserDefaults.standard.set(quote.quote, forKey: cacheKeyQuote)
        UserDefaults.standard.set(quote.author, forKey: cacheKeyAuthor)
        UserDefaults.standard.set(quote.category, forKey: cacheKeyCategory)
        UserDefaults.standard.set(todayDateKey(), forKey: cacheKeyDate)
    }

    private func loadCachedQuote() {
        if let cachedQuote = UserDefaults.standard.string(forKey: cacheKeyQuote),
           let cachedAuthor = UserDefaults.standard.string(forKey: cacheKeyAuthor) {
            let cat = UserDefaults.standard.string(forKey: cacheKeyCategory) ?? "Today"
            self.currentQuote = DailyQuote(quote: cachedQuote, author: cachedAuthor, category: cat)
        } else {
            let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
            let index = dayOfYear % curatedQuotes.count
            self.currentQuote = curatedQuotes[index]
        }
    }
}
