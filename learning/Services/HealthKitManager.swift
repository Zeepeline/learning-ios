//
//  HealthKitManager.swift
//  learning
//
//  Created by macbook on 9/6/26.
//

import Foundation
import HealthKit
import SwiftUI
import Observation

// MARK: - 🏃 Model Data Sesi Olahraga / Workout (Zepp, Apple Watch, dll.)
struct HealthWorkoutItem: Identifiable, Sendable, Codable {
    let id: UUID
    let activityTypeRaw: UInt
    let title: String
    let icon: String
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let distanceKm: Double
    let calories: Double
    let sourceName: String

    var activityType: HKWorkoutActivityType {
        HKWorkoutActivityType(rawValue: activityTypeRaw) ?? .other
    }

    init(
        id: UUID = UUID(),
        activityType: HKWorkoutActivityType,
        title: String,
        icon: String,
        startDate: Date,
        endDate: Date,
        duration: TimeInterval,
        distanceKm: Double,
        calories: Double,
        sourceName: String
    ) {
        self.id = id
        self.activityTypeRaw = activityType.rawValue
        self.title = title
        self.icon = icon
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.distanceKm = distanceKm
        self.calories = calories
        self.sourceName = sourceName
    }

    var durationFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remMinutes = minutes % 60
            return "\(hours) jam \(remMinutes) mnt"
        }
        return "\(minutes) mnt \(seconds) dtk"
    }

    var timeFormatted: String {
        startDate.formatted(date: .omitted, time: .shortened)
    }
}

// MARK: - 📊 Model Ringkasan Kebugaran & Kesehatan Hari Ini
struct TodayHealthSummary: Sendable, Codable {
    var steps: Int = 0
    var activeCalories: Double = 0
    var exerciseMinutes: Double = 0
    var distanceKm: Double = 0
    var sleepDurationHours: Double = 0
    var sleepFormatted: String = "0 jam"
    var recentWorkouts: [HealthWorkoutItem] = []
    var isAuthorized: Bool = false
    var lastUpdated: Date = Date.distantPast

    var stepsProgress: Double {
        min(1.0, Double(steps) / 6000.0) // Target default 6.000 langkah
    }

    var caloriesProgress: Double {
        min(1.0, activeCalories / 400.0) // Target default 400 kkal
    }

    var exerciseProgress: Double {
        min(1.0, exerciseMinutes / 30.0) // Target default 30 menit
    }
}

// MARK: - 🩺 HealthKit Service Layer Manager (High-Performance Query Cache & In-Flight Deduplication)
@Observable
@MainActor
final class HealthKitManager {
    static let shared = HealthKitManager()

    private static let authRequestedKey = "has_requested_healthkit_auth_v2"
    private static let cachedSummaryKey = "cached_today_health_summary_v2"

    @ObservationIgnored private let healthStore: HKHealthStore? = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
    @ObservationIgnored private var inFlightFetchTask: Task<Void, Never>? = nil

    var isAuthorized: Bool = false
    var isLoading: Bool = false
    var todaySummary: TodayHealthSummary = TodayHealthSummary()
    var authorizationError: String? = nil

    private init() {
        loadCachedSummary()
        checkAuthorizationStatus()
    }

    /// Memeriksa ketersediaan sensor & status HealthKit di perangkat
    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - 1. Request Izin Akses HealthKit (Async/Await)
    @discardableResult
    func requestAuthorization() async -> Bool {
        guard let healthStore = healthStore else {
            self.authorizationError = "HealthKit tidak tersedia di perangkat ini."
            return false
        }

        // Tipe data yang ingin dibaca dari Apple Health (termasuk sync dari Zepp/Amazfit)
        var readTypes: Set<HKObjectType> = [
            HKObjectType.workoutType()
        ]

        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            readTypes.insert(stepType)
        }
        if let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            readTypes.insert(calorieType)
        }
        if let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) {
            readTypes.insert(exerciseType)
        }
        if let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            readTypes.insert(distanceType)
        }
        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            readTypes.insert(sleepType)
        }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            UserDefaults.standard.set(true, forKey: Self.authRequestedKey)
            self.isAuthorized = true
            self.authorizationError = nil
            await self.fetchAllTodayHealthData(force: true)
            return true
        } catch {
            self.authorizationError = error.localizedDescription
            return false
        }
    }

    private func checkAuthorizationStatus() {
        let hasRequested = UserDefaults.standard.bool(forKey: Self.authRequestedKey)
        if hasRequested {
            self.isAuthorized = true
            Task {
                await self.fetchAllTodayHealthData(force: false)
            }
        }
    }

    private func loadCachedSummary() {
        if let data = UserDefaults.standard.data(forKey: Self.cachedSummaryKey),
           let cached = try? JSONDecoder().decode(TodayHealthSummary.self, from: data) {
            // Jika cache berasal dari hari yang sama, gunakan langsung agar UI instan
            if Calendar.current.isDateInToday(cached.lastUpdated) {
                self.todaySummary = cached
                self.isAuthorized = true
            }
        }
    }

    private func saveCachedSummary(_ summary: TodayHealthSummary) {
        if let data = try? JSONEncoder().encode(summary) {
            UserDefaults.standard.set(data, forKey: Self.cachedSummaryKey)
        }
    }

    // MARK: - 2. Mengambil Seluruh Data Kesehatan Hari Ini (Deduplicated & Cached)
    func fetchAllTodayHealthData(force: Bool = false) async {
        guard healthStore != nil else { return }

        // ⚡ Cache throttle: Jangan query ulang jika data baru saja diambil kurang dari 60 detik lalu
        if !force && Date().timeIntervalSince(todaySummary.lastUpdated) < 60 && (todaySummary.steps > 0 || todaySummary.activeCalories > 0) {
            return
        }

        // ⚡ In-Flight Task Deduplication: Jika ada fetch yang sedang berjalan, tunggu task tersebut
        if let existingTask = inFlightFetchTask {
            await existingTask.value
            return
        }

        let fetchTask = Task { @MainActor in
            self.isLoading = true
            defer {
                self.isLoading = false
                self.inFlightFetchTask = nil
            }

            async let steps = self.fetchTodaySteps()
            async let calories = self.fetchTodayActiveCalories()
            async let exercise = self.fetchTodayExerciseMinutes()
            async let distance = self.fetchTodayDistance()
            async let sleep = self.fetchLastNightSleep()
            async let workouts = self.fetchTodayWorkouts()

            let fetchedSteps = await steps
            let fetchedCalories = await calories
            let fetchedExercise = await exercise
            let fetchedDistance = await distance
            let (sleepHours, sleepText) = await sleep
            let fetchedWorkouts = await workouts

            let newSummary = TodayHealthSummary(
                steps: fetchedSteps,
                activeCalories: fetchedCalories,
                exerciseMinutes: fetchedExercise,
                distanceKm: fetchedDistance,
                sleepDurationHours: sleepHours,
                sleepFormatted: sleepText,
                recentWorkouts: fetchedWorkouts,
                isAuthorized: true,
                lastUpdated: Date()
            )

            self.todaySummary = newSummary
            self.isAuthorized = true
            self.saveCachedSummary(newSummary)
        }

        self.inFlightFetchTask = fetchTask
        await fetchTask.value
    }

    // MARK: - 3. Query Spesifik: Langkah Kaki Hari Ini (Steps)
    func fetchTodaySteps() async -> Int {
        guard let healthStore = healthStore,
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return todaySummary.steps
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, _ in
                let sum = statistics?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0.0
                continuation.resume(returning: Int(sum))
            }
            healthStore.execute(query)
        }
    }

    // MARK: - 4. Query Spesifik: Kalori Terbakar Aktif (kCal)
    func fetchTodayActiveCalories() async -> Double {
        guard let healthStore = healthStore,
              let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return todaySummary.activeCalories
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, _ in
                let calories = statistics?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0.0
                continuation.resume(returning: calories)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - 5. Query Spesifik: Menit Latihan / Olahraga
    func fetchTodayExerciseMinutes() async -> Double {
        guard let healthStore = healthStore,
              let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else {
            return todaySummary.exerciseMinutes
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: exerciseType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, _ in
                let minutes = statistics?.sumQuantity()?.doubleValue(for: HKUnit.minute()) ?? 0.0
                continuation.resume(returning: minutes)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - 6. Query Spesifik: Jarak Berjalan / Berlari (Km)
    func fetchTodayDistance() async -> Double {
        guard let healthStore = healthStore,
              let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            return todaySummary.distanceKm
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, _ in
                let distanceInMeters = statistics?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0.0
                continuation.resume(returning: distanceInMeters / 1000.0)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - 7. Query Spesifik: Analisis Durasi Tidur Semalam
    func fetchLastNightSleep() async -> (hours: Double, formattedText: String) {
        guard let healthStore = healthStore,
              let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return (todaySummary.sleepDurationHours, todaySummary.sleepFormatted)
        }

        let calendar = Calendar.current
        let now = Date()
        guard let yesterdayNoon = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now)) else {
            return (0, "0 jam")
        }

        let predicate = HKQuery.predicateForSamples(withStart: yesterdayNoon, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 100, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let categorySamples = samples as? [HKCategorySample], !categorySamples.isEmpty else {
                    continuation.resume(returning: (0, "0 jam"))
                    return
                }

                var totalSleepSeconds: TimeInterval = 0
                for sample in categorySamples {
                    if #available(iOS 16.0, *) {
                        let val = sample.value
                        if val == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                           val == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                           val == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                           val == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                            totalSleepSeconds += sample.endDate.timeIntervalSince(sample.startDate)
                        }
                    } else {
                        if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                            totalSleepSeconds += sample.endDate.timeIntervalSince(sample.startDate)
                        }
                    }
                }

                let totalHours = totalSleepSeconds / 3600.0
                let hoursInt = Int(totalSleepSeconds) / 3600
                let minutesInt = (Int(totalSleepSeconds) % 3600) / 60
                let text = "\(hoursInt)j \(minutesInt)m"
                continuation.resume(returning: (totalHours, text))
            }
            healthStore.execute(query)
        }
    }

    // MARK: - 8. Query Spesifik: Riwayat Olahraga Terkini (Zepp / Amazfit / Apple Watch Workout)
    func fetchTodayWorkouts() async -> [HealthWorkoutItem] {
        guard let healthStore = healthStore else {
            return todaySummary.recentWorkouts
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicate, limit: 5, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }

                let items: [HealthWorkoutItem] = workouts.map { workout in
                    let distanceKm = workout.totalDistance?.doubleValue(for: HKUnit.meter()) ?? 0.0
                    let calories = workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? 0.0
                    let (title, icon) = Self.parseWorkoutType(workout.workoutActivityType)

                    return HealthWorkoutItem(
                        activityType: workout.workoutActivityType,
                        title: title,
                        icon: icon,
                        startDate: workout.startDate,
                        endDate: workout.endDate,
                        duration: workout.duration,
                        distanceKm: distanceKm / 1000.0,
                        calories: calories,
                        sourceName: workout.sourceRevision.source.name
                    )
                }
                continuation.resume(returning: items)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - 🏷️ Helper Identifikasi Jenis Olahraga & Ikon Kartun
    private static func parseWorkoutType(_ type: HKWorkoutActivityType) -> (title: String, icon: String) {
        switch type {
        case .running:
            return ("Lari Luar Ruang", "figure.run")
        case .walking:
            return ("Jalan Santai", "figure.walk")
        case .cycling:
            return ("Bersepeda", "figure.outdoor.cycle")
        case .swimming:
            return ("Berenang", "figure.pool.swim")
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            return ("Latihan Beban / Gym", "dumbbell.fill")
        case .highIntensityIntervalTraining:
            return ("HIIT Workout", "flame.fill")
        case .badminton:
            return ("Bulu Tangkis", "figure.badminton")
        case .soccer:
            return ("Sepak Bola", "figure.soccer")
        case .basketball:
            return ("Bola Basket", "figure.basketball")
        case .yoga:
            return ("Yoga / Stretching", "figure.yoga")
        default:
            return ("Aktivitas Kebugaran", "figure.mixed.cardio")
        }
    }
}
