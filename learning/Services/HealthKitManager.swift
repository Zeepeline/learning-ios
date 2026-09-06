//
//  HealthKitManager.swift
//  learning
//
//  Created by macbook on 9/6/26.
//

import Foundation
import HealthKit
import SwiftUI
import Combine

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
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: startDate)
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
    var lastUpdated: Date = Date()
    
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

// MARK: - 🩺 HealthKit Service Layer Manager
@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore: HKHealthStore? = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
    
    @Published var isAuthorized: Bool = false
    @Published var isLoading: Bool = false
    @Published var todaySummary: TodayHealthSummary = TodayHealthSummary()
    @Published var authorizationError: String? = nil
    
    private init() {
        checkAuthorizationStatus()
    }
    
    /// Memeriksa ketersediaan sensor & status HealthKit di perangkat
    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    // MARK: - 1. Request Izin Akses HealthKit
    func requestAuthorization(completion: (@Sendable (Bool) -> Void)? = nil) {
        guard let healthStore = healthStore else {
            completion?(false)
            return
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
        
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] success, error in
            Task { @MainActor in
                guard let self = self else { return }
                if success {
                    self.isAuthorized = true
                    self.authorizationError = nil
                    await self.fetchAllTodayHealthData()
                    completion?(true)
                } else {
                    self.authorizationError = error?.localizedDescription ?? "Izin HealthKit ditolak."
                    completion?(false)
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        guard let healthStore = healthStore,
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let status = healthStore.authorizationStatus(for: stepType)
        self.isAuthorized = (status == .sharingAuthorized)
    }
    
    // MARK: - 2. Mengambil Seluruh Data Kesehatan Hari Ini
    func fetchAllTodayHealthData() async {
        guard let _ = healthStore else { return }
        isLoading = true
        defer { isLoading = false }
        
        async let steps = fetchTodaySteps()
        async let calories = fetchTodayActiveCalories()
        async let exercise = fetchTodayExerciseMinutes()
        async let distance = fetchTodayDistance()
        async let sleep = fetchLastNightSleep()
        async let workouts = fetchTodayWorkouts()
        
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
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - 4. Query Spesifik: Kalori Aktif Hari Ini (kCal)
    func fetchTodayActiveCalories() async -> Double {
        guard let healthStore = healthStore,
              let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return 0
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: calorieType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let calories = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                continuation.resume(returning: calories)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - 5. Query Spesifik: Menit Olahraga (Exercise Minutes)
    func fetchTodayExerciseMinutes() async -> Double {
        guard let healthStore = healthStore,
              let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else {
            return 0
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
                let minutes = result?.sumQuantity()?.doubleValue(for: HKUnit.minute()) ?? 0
                continuation.resume(returning: minutes)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - 6. Query Spesifik: Jarak Jalan & Lari (km)
    func fetchTodayDistance() async -> Double {
        guard let healthStore = healthStore,
              let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            return 0
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
                let distanceMeter = result?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
                let distanceKm = distanceMeter / 1000.0
                continuation.resume(returning: distanceKm)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - 7. Query Spesifik: Sesi Olahraga / Lari Hari Ini (Workouts dari Zepp, Apple Watch, dll.)
    func fetchTodayWorkouts() async -> [HealthWorkoutItem] {
        guard let healthStore = healthStore else { return [] }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: 10,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let workoutItems = workouts.map { workout -> HealthWorkoutItem in
                    let distanceKm = (workout.totalDistance?.doubleValue(for: .meter()) ?? 0) / 1000.0
                    let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                    let source = workout.sourceRevision.source.name
                    
                    return HealthWorkoutItem(
                        id: workout.uuid,
                        activityType: workout.workoutActivityType,
                        title: Self.title(for: workout.workoutActivityType),
                        icon: Self.icon(for: workout.workoutActivityType),
                        startDate: workout.startDate,
                        endDate: workout.endDate,
                        duration: workout.duration,
                        distanceKm: distanceKm,
                        calories: calories,
                        sourceName: source.isEmpty ? "Apple Health" : source
                    )
                }
                
                continuation.resume(returning: workoutItems)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - 8. Query Spesifik: Durasi Tidur Semalam (Sleep Analysis)
    func fetchLastNightSleep() async -> (durationHours: Double, formatted: String) {
        guard let healthStore = healthStore,
              let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return (0, "0 jam")
        }
        
        let calendar = Calendar.current
        // Ambil rentang waktu 24 jam terakhir (dari kemarin sore sampai pagi ini)
        let now = Date()
        guard let yesterdayNoon = calendar.date(byAdding: .hour, value: -24, to: now) else {
            return (0, "0 jam")
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: yesterdayNoon, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: (0, "0 jam"))
                    return
                }
                
                var totalSleepSeconds: TimeInterval = 0
                for sample in sleepSamples {
                    // Cek status tidur (Asleep, Core, Deep, REM)
                    if sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                        totalSleepSeconds += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                }
                
                let hours = totalSleepSeconds / 3600.0
                let totalMinutes = Int(totalSleepSeconds) / 60
                let h = totalMinutes / 60
                let m = totalMinutes % 60
                
                let formatted = h > 0 ? "\(h)j \(m)m" : "\(m) mnt"
                continuation.resume(returning: (hours, formatted))
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Helper Pemetaan Icon & Nama Aktivitas Kartun
    private static func title(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "Lari"
        case .walking: return "Jalan Santai"
        case .cycling: return "Bersepeda"
        case .swimming: return "Berenang"
        case .traditionalStrengthTraining, .functionalStrengthTraining: return "Latihan Beban"
        case .yoga: return "Yoga & Relaksasi"
        case .highIntensityIntervalTraining: return "HIIT Workout"
        case .badminton: return "Badminton"
        case .soccer: return "Sepak Bola"
        case .basketball: return "Bola Basket"
        default: return "Sesi Olahraga"
        }
    }
    
    private static func icon(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .traditionalStrengthTraining, .functionalStrengthTraining: return "dumbbell.fill"
        case .yoga: return "figure.mind.and.body"
        case .highIntensityIntervalTraining: return "flame.fill"
        case .badminton: return "figure.badminton"
        case .soccer: return "soccerball"
        case .basketball: return "basketball.fill"
        default: return "figure.mixed.cardio"
        }
    }
}
