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
struct HealthWorkoutItem: Identifiable, Sendable {
    let id: UUID
    let activityType: HKWorkoutActivityType
    let title: String
    let icon: String
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let distanceKm: Double
    let calories: Double
    let sourceName: String
    
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
struct TodayHealthSummary: Sendable {
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
    
    @ObservationIgnored private let healthStore: HKHealthStore? = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
    @ObservationIgnored private var inFlightFetchTask: Task<Void, Never>? = nil
    
    var isAuthorized: Bool = false
    var isLoading: Bool = false
    var todaySummary: TodayHealthSummary = TodayHealthSummary()
    var authorizationError: String? = nil
    
    private init() {
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
        guard let healthStore = healthStore,
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let status = healthStore.authorizationStatus(for: stepType)
        self.isAuthorized = (status == .sharingAuthorized)
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
            
            self.todaySummary = TodayHealthSummary(
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
        }
        
        self.inFlightFetchTask = fetchTask
        await fetchTask.value
    }
    
    // MARK: - 3. Query Spesifik: Langkah Kaki Hari Ini (Steps)
    func fetchTodaySteps() async -> Int {
        guard let healthStore = healthStore,
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return 0
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                let totalSteps = Int(sum.doubleValue(for: HKUnit.count()))
                continuation.resume(returning: totalSteps)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - 4. Query Kalori Terbakar Hari Ini (Active Calories)
    func fetchTodayActiveCalories() async -> Double {
        guard let healthStore = healthStore,
              let calType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return 0.0
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: calType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0.0)
                    return
                }
                let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                continuation.resume(returning: calories)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - 5. Query Menit Olahraga Hari Ini (Exercise Time)
    func fetchTodayExerciseMinutes() async -> Double {
        guard let healthStore = healthStore,
              let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else {
            return 0.0
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: exerciseType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0.0)
                    return
                }
                let minutes = sum.doubleValue(for: HKUnit.minute())
                continuation.resume(returning: minutes)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - 6. Query Jarak Jalan/Lari Hari Ini (Distance Km)
    func fetchTodayDistance() async -> Double {
        guard let healthStore = healthStore,
              let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            return 0.0
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0.0)
                    return
                }
                let distanceKm = sum.doubleValue(for: HKUnit.meter()) / 1000.0
                continuation.resume(returning: distanceKm)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - 7. Query Durasi Tidur Semalam (Sleep Analysis)
    func fetchLastNightSleep() async -> (hours: Double, formattedText: String) {
        guard let healthStore = healthStore,
              let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return (0.0, "0 jam")
        }
        
        let calendar = Calendar.current
        let now = Date()
        guard let yesterdayEvening = calendar.date(byAdding: .hour, value: -18, to: now) else {
            return (0.0, "0 jam")
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: yesterdayEvening, end: now, options: [])
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: 30,
                sortDescriptors: [NSSortDescriptor(key: "startDate", ascending: false)]
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: (0.0, "0 jam"))
                    return
                }
                
                var totalSleepSeconds: TimeInterval = 0
                for sample in samples {
                    // Nilai value: asleepUnspecified / asleepCore / asleepDeep / asleepREM
                    if sample.value != HKCategoryValueSleepAnalysis.awake.rawValue {
                        totalSleepSeconds += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                }
                
                let totalHours = totalSleepSeconds / 3600.0
                let hours = Int(totalHours)
                let minutes = Int((totalSleepSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
                
                let text = "\(hours) jam \(minutes) mnt"
                continuation.resume(returning: (totalHours, text))
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - 8. Query Riwayat Sesi Workout Hari Ini (Zepp / Smartwatch Sync)
    func fetchTodayWorkouts() async -> [HealthWorkoutItem] {
        guard let healthStore = healthStore else { return [] }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: 10,
                sortDescriptors: [NSSortDescriptor(key: "startDate", ascending: false)]
            ) { _, samples, _ in
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let items: [HealthWorkoutItem] = workouts.map { workout in
                    let title = Self.workoutName(for: workout.workoutActivityType)
                    let icon = Self.workoutIcon(for: workout.workoutActivityType)
                    let distanceKm = (workout.totalDistance?.doubleValue(for: HKUnit.meter()) ?? 0.0) / 1000.0
                    let calories = workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? 0.0
                    let source = workout.sourceRevision.source.name
                    
                    return HealthWorkoutItem(
                        id: workout.uuid,
                        activityType: workout.workoutActivityType,
                        title: title,
                        icon: icon,
                        startDate: workout.startDate,
                        endDate: workout.endDate,
                        duration: workout.duration,
                        distanceKm: distanceKm,
                        calories: calories,
                        sourceName: source
                    )
                }
                continuation.resume(returning: items)
            }
            healthStore.execute(query)
        }
    }
    
    // Helper Nama Workout
    nonisolated static func workoutName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "Lari Luar Ruang"
        case .walking: return "Jalan Santai"
        case .cycling: return "Bersepeda"
        case .swimming: return "Berenang"
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "Latihan Beban"
        case .yoga: return "Yoga"
        case .highIntensityIntervalTraining: return "HIIT Workout"
        default: return "Aktivitas Olahraga"
        }
    }
    
    // Helper Icon Workout
    nonisolated static func workoutIcon(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "dumbbell.fill"
        case .yoga: return "figure.mind.and.body"
        case .highIntensityIntervalTraining: return "flame.fill"
        default: return "sportscourt.fill"
        }
    }
}
