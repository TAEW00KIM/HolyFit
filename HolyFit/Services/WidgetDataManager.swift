import Foundation
import SwiftData
import WidgetKit

/// Writes today's workout and nutrition summary to the shared App Group UserDefaults
/// so the home screen widget can read it without requiring SwiftData access.
enum WidgetDataManager {

    private static let suiteName = "group.com.personal.HolyFit"

    // UserDefaults keys
    private static let keyWorkoutCount  = "widgetTodayWorkoutCount"
    private static let keyCalories      = "widgetTodayCalories"
    private static let keyProtein       = "widgetTodayProtein"
    private static let keyLastUpdated   = "widgetLastUpdated"
    private static let keyStreak        = "widgetCurrentStreak"
    private static let keyTodayCalories = "widgetTodayMealCalories"
    private static let keyDuration      = "widgetTodayDuration"
    private static let keyVolume        = "widgetTodayVolume"

    /// Queries today's totals from the given model context and writes them to the
    /// shared UserDefaults suite, then reloads all WidgetKit timelines.
    static func updateWidgetData(context: ModelContext) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay   = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        // --- Workout count: sessions that ended today ---
        // Note: SwiftData #Predicate does not support force-unwrap (!)
        let completedDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.endDate != nil }
        )
        let allCompleted = (try? context.fetch(completedDescriptor)) ?? []
        let todaySessions = allCompleted.filter {
            guard let end = $0.endDate else { return false }
            return end >= startOfDay && end < endOfDay
        }
        let workoutCount = todaySessions.count
        let totalDuration = todaySessions.compactMap(\.duration).reduce(0, +)
        let totalVolume = todaySessions.reduce(0.0) { $0 + $1.totalVolume }

        // --- Nutrition totals for today ---
        let mealDescriptor = FetchDescriptor<MealEntry>(
            predicate: #Predicate { entry in
                entry.date >= startOfDay && entry.date < endOfDay
            }
        )
        let meals = (try? context.fetch(mealDescriptor)) ?? []
        let totalCalories = meals.compactMap(\.calories).reduce(0, +)
        let totalProtein  = meals.compactMap(\.protein).reduce(0.0, +)

        // --- Streak: consecutive workout days (same logic as WorkoutCalendarView) ---
        var uniqueWorkoutDates = Set<Date>()
        for session in allCompleted {
            uniqueWorkoutDates.insert(calendar.startOfDay(for: session.startDate))
        }
        let sortedDates = uniqueWorkoutDates.sorted(by: >)
        var currentStreak = 0
        if !sortedDates.isEmpty {
            var checkDate = startOfDay
            if sortedDates.first != startOfDay {
                if let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfDay) {
                    checkDate = yesterday
                }
            }
            for date in sortedDates {
                if date == checkDate {
                    currentStreak += 1
                    guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    checkDate = prev
                } else if date < checkDate {
                    break
                }
            }
        }

        // --- Write to shared suite ---
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.set(workoutCount,   forKey: keyWorkoutCount)
        defaults.set(totalCalories,  forKey: keyCalories)
        defaults.set(totalProtein,   forKey: keyProtein)
        defaults.set(currentStreak,  forKey: keyStreak)
        defaults.set(totalCalories,  forKey: keyTodayCalories)
        defaults.set(Int(totalDuration / 60), forKey: keyDuration)
        defaults.set(totalVolume,    forKey: keyVolume)
        defaults.set(Date(),         forKey: keyLastUpdated)

        // --- Reload widget timelines ---
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Read helpers (used by the widget target via its own copy of these keys)

    static func readWorkoutCount() -> Int {
        UserDefaults(suiteName: suiteName)?.integer(forKey: keyWorkoutCount) ?? 0
    }

    static func readCalories() -> Int {
        UserDefaults(suiteName: suiteName)?.integer(forKey: keyCalories) ?? 0
    }

    static func readProtein() -> Double {
        UserDefaults(suiteName: suiteName)?.double(forKey: keyProtein) ?? 0.0
    }

    static func readLastUpdated() -> Date {
        UserDefaults(suiteName: suiteName)?.object(forKey: keyLastUpdated) as? Date ?? .distantPast
    }

    static func readStreak() -> Int {
        UserDefaults(suiteName: suiteName)?.integer(forKey: keyStreak) ?? 0
    }

    static func readTodayCalories() -> Int {
        UserDefaults(suiteName: suiteName)?.integer(forKey: keyTodayCalories) ?? 0
    }
}
