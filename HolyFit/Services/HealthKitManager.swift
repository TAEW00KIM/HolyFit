import Foundation
import HealthKit
import os.log

@Observable
final class HealthKitManager {

    // MARK: - State

    @MainActor var isAuthorized: Bool = false
    nonisolated let isAvailable: Bool = HKHealthStore.isHealthDataAvailable()

    // MARK: - Private

    private nonisolated let store: HKHealthStore? = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
    private nonisolated let logger = Logger(subsystem: "com.personal.HolyFit", category: "HealthKit")

    private nonisolated let readTypes: Set<HKObjectType> = {
        [HKObjectType.quantityType(forIdentifier: .bodyMass),
         HKObjectType.quantityType(forIdentifier: .stepCount)]
            .compactMap { $0 }
            .reduce(into: Set<HKObjectType>()) { $0.insert($1) }
    }()

    private nonisolated let writeTypes: Set<HKSampleType> = [
        HKObjectType.workoutType()
    ]

    // MARK: - Authorization

    @MainActor
    func requestAuthorization() async -> Bool {
        guard let store, isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
            // Check actual authorization status (requestAuthorization succeeds even if user denies)
            let workoutType = HKObjectType.workoutType()
            isAuthorized = store.authorizationStatus(for: workoutType) == .sharingAuthorized
        } catch {
            isAuthorized = false
        }
        return isAuthorized
    }

    @MainActor
    func checkAuthorizationStatus() -> Bool {
        guard let store, isAvailable else {
            isAuthorized = false
            return false
        }
        let workoutType = HKObjectType.workoutType()
        isAuthorized = store.authorizationStatus(for: workoutType) == .sharingAuthorized
        return isAuthorized
    }

    // MARK: - Save Workout

    func saveWorkout(
        type: HKWorkoutActivityType,
        start: Date,
        end: Date,
        totalEnergyBurned: Double?
    ) async {
        guard let store, isAvailable else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = type

        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())

        do {
            try await builder.beginCollection(at: start)

            if let kcal = totalEnergyBurned {
                let energyType = HKQuantityType(.activeEnergyBurned)
                let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: kcal)
                let sample = HKQuantitySample(type: energyType, quantity: quantity, start: start, end: end)
                try await builder.addSamples([sample])
            }

            try await builder.endCollection(at: end)
            try await builder.finishWorkout()
        } catch {
            logger.error("운동 저장 실패: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Read Body Mass

    func readBodyMass() async -> Double? {
        guard let store, isAvailable else { return nil }
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }

        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let predicate = HKQuery.predicateForSamples(withStart: nil, end: Date(), options: .strictEndDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: kg)
            }
            store.execute(query)
        }
    }

    // MARK: - Read Step Count

    func readStepCount(for date: Date) async -> Int {
        guard let store, isAvailable else { return 0 }
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return 0 }

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                guard let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                let steps = Int(sum.doubleValue(for: .count()))
                continuation.resume(returning: steps)
            }
            store.execute(query)
        }
    }
}
