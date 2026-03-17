import WidgetKit
import SwiftUI

// MARK: - Shared UserDefaults reader (widget-side, no SwiftData)

private enum WidgetSharedDefaults {
    static let suiteName        = "group.com.personal.HolyFit"
    static let keyWorkoutCount  = "widgetTodayWorkoutCount"
    static let keyCalories      = "widgetTodayCalories"
    static let keyProtein       = "widgetTodayProtein"
    static let keyLastUpdated   = "widgetLastUpdated"
    static let keyStreak        = "widgetCurrentStreak"
    static let keyTodayCalories = "widgetTodayMealCalories"
    static let keyDuration      = "widgetTodayDuration"
    static let keyVolume        = "widgetTodayVolume"

    static func workoutCount() -> Int {
        UserDefaults(suiteName: suiteName)?.integer(forKey: keyWorkoutCount) ?? 0
    }
    static func calories() -> Int {
        UserDefaults(suiteName: suiteName)?.integer(forKey: keyCalories) ?? 0
    }
    static func protein() -> Double {
        UserDefaults(suiteName: suiteName)?.double(forKey: keyProtein) ?? 0.0
    }
    static func lastUpdated() -> Date {
        UserDefaults(suiteName: suiteName)?.object(forKey: keyLastUpdated) as? Date ?? .distantPast
    }
    static func streak() -> Int {
        UserDefaults(suiteName: suiteName)?.integer(forKey: keyStreak) ?? 0
    }
    static func todayCalories() -> Int {
        UserDefaults(suiteName: suiteName)?.integer(forKey: keyTodayCalories) ?? 0
    }
    static func duration() -> Int {
        UserDefaults(suiteName: suiteName)?.integer(forKey: keyDuration) ?? 0
    }
    static func volume() -> Double {
        UserDefaults(suiteName: suiteName)?.double(forKey: keyVolume) ?? 0.0
    }
}

// MARK: - Timeline Entry

struct HolyFitWidgetEntry: TimelineEntry {
    let date: Date
    let workoutCount: Int
    let calories: Int
    let protein: Double
    let currentStreak: Int
    let todayCalories: Int
    let duration: Int       // minutes
    let volume: Double      // kg
}

// MARK: - Timeline Provider

struct HolyFitWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> HolyFitWidgetEntry {
        HolyFitWidgetEntry(date: .now, workoutCount: 1, calories: 520, protein: 142.0, currentStreak: 5, todayCalories: 1380, duration: 47, volume: 4280)
    }

    func getSnapshot(in context: Context, completion: @escaping (HolyFitWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HolyFitWidgetEntry>) -> Void) {
        let entry = currentEntry()
        // Refresh every 15 minutes; the app also reloads on data changes via WidgetCenter
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func currentEntry() -> HolyFitWidgetEntry {
        HolyFitWidgetEntry(
            date: .now,
            workoutCount: WidgetSharedDefaults.workoutCount(),
            calories: WidgetSharedDefaults.calories(),
            protein: WidgetSharedDefaults.protein(),
            currentStreak: WidgetSharedDefaults.streak(),
            todayCalories: WidgetSharedDefaults.todayCalories(),
            duration: WidgetSharedDefaults.duration(),
            volume: WidgetSharedDefaults.volume()
        )
    }
}

// MARK: - Widget Configuration

@main
struct HolyFitWidget: Widget {
    let kind = "HolyFitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HolyFitWidgetProvider()) { entry in
            HolyFitWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetBackgroundView()
                }
        }
        .configurationDisplayName("HolyFit")
        .description("오늘의 운동 현황과 칼로리를 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
