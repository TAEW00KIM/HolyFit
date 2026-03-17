import WidgetKit
import SwiftUI

// MARK: - Widget colors — Black / Red theme

private enum WidgetColors {
    static let gradientStart = Color(red: 0.902, green: 0.224, blue: 0.275)  // #E63946
    static let gradientEnd   = Color(red: 1.0,   green: 0.176, blue: 0.333)  // #FF2D55
    static let calorieColor  = Color(red: 1.0,   green: 0.271, blue: 0.227)  // #FF453A
    static let proteinColor  = Color(red: 0.039, green: 0.518, blue: 1.0)    // #0A84FF
    static let successColor  = Color(red: 0.188, green: 0.820, blue: 0.345)  // #30D158
    static let surface       = Color(red: 0.110, green: 0.110, blue: 0.118)  // #1C1C1E
    static let surfaceLight  = Color(red: 0.173, green: 0.173, blue: 0.180)  // #2C2C2E

    static let primaryGradient = LinearGradient(
        colors: [gradientStart, gradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Entry View (routes to small / medium)

struct HolyFitWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HolyFitWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget

private struct SmallWidgetView: View {
    let entry: HolyFitWidgetEntry

    private var didWorkOut: Bool { entry.workoutCount > 0 }

    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 6) {
                // Workout status badge
                HStack(spacing: 5) {
                    Image(systemName: didWorkOut ? "checkmark.circle.fill" : "dumbbell.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(didWorkOut ? WidgetColors.successColor : WidgetColors.gradientStart)
                    Text(didWorkOut ? "운동 완료" : "운동 전")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }

                // Streak badge (only when streak > 0)
                if entry.currentStreak > 0 {
                    HStack(spacing: 3) {
                        Text("🔥")
                            .font(.system(size: 11))
                        Text("\(entry.currentStreak)일 연속")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }

                Spacer()

                // Calorie number (hero)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(WidgetColors.calorieColor)
                        Text("\(entry.calories)")
                            .font(.system(size: 30, weight: .heavy))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                    Text("kcal")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }

                // Red accent bar at bottom
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(WidgetColors.primaryGradient)
                    .frame(height: 3)
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Medium Widget

private struct MediumWidgetView: View {
    let entry: HolyFitWidgetEntry

    private var didWorkOut: Bool { entry.workoutCount > 0 }

    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()

            HStack(spacing: 0) {
                // Left panel – workout status
                VStack(alignment: .leading, spacing: 8) {
                    Label("오늘 운동", systemImage: "dumbbell.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(WidgetColors.gradientStart)

                    Spacer()

                    // Workout count badge
                    ZStack {
                        Circle()
                            .fill(WidgetColors.primaryGradient)
                            .frame(width: 52, height: 52)
                        VStack(spacing: 0) {
                            Text("\(entry.workoutCount)")
                                .font(.system(size: 22, weight: .heavy))
                                .foregroundStyle(.white)
                            Text("회")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }

                    Spacer()

                    // Done / not done label
                    HStack(spacing: 4) {
                        Image(systemName: didWorkOut ? "checkmark.seal.fill" : "xmark.seal")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(didWorkOut ? WidgetColors.successColor : .gray)
                        Text(didWorkOut ? "완료" : "미완료")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(didWorkOut ? WidgetColors.successColor : .gray)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.leading, 14)
                .padding(.vertical, 14)

                // Divider
                Rectangle()
                    .fill(WidgetColors.gradientStart.opacity(0.3))
                    .frame(width: 1)
                    .padding(.vertical, 14)

                // Right panel – nutrition summary + streak
                VStack(alignment: .leading, spacing: 6) {
                    Text("영양 요약")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.gray)

                    Spacer()

                    NutritionRow(
                        icon: "flame.fill",
                        color: WidgetColors.calorieColor,
                        label: "칼로리",
                        value: "\(entry.calories)",
                        unit: "kcal"
                    )

                    NutritionRow(
                        icon: "bolt.heart.fill",
                        color: WidgetColors.proteinColor,
                        label: "단백질",
                        value: String(format: "%.0f", entry.protein),
                        unit: "g"
                    )

                    // Today's meal calories
                    NutritionRow(
                        icon: "fork.knife",
                        color: WidgetColors.successColor,
                        label: "식사",
                        value: entry.todayCalories.formatted(),
                        unit: "kcal"
                    )

                    Spacer()

                    // Streak badge
                    if entry.currentStreak > 0 {
                        HStack(spacing: 3) {
                            Text("🔥")
                                .font(.system(size: 10))
                            Text("\(entry.currentStreak)일 연속")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
            }
        }
    }
}

// MARK: - Nutrition Row

private struct NutritionRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String
    let unit: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 16)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.gray)

            Spacer()

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                Text(unit)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.gray)
            }
        }
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    HolyFitWidget()
} timeline: {
    HolyFitWidgetEntry(date: .now, workoutCount: 1, calories: 1850, protein: 142.0, currentStreak: 5,  todayCalories: 1380)
    HolyFitWidgetEntry(date: .now, workoutCount: 0, calories: 0,    protein: 0.0,   currentStreak: 0,  todayCalories: 0)
}

#Preview(as: .systemMedium) {
    HolyFitWidget()
} timeline: {
    HolyFitWidgetEntry(date: .now, workoutCount: 2, calories: 2100, protein: 175.5, currentStreak: 5,  todayCalories: 1380)
    HolyFitWidgetEntry(date: .now, workoutCount: 0, calories: 650,  protein: 48.0,  currentStreak: 0,  todayCalories: 650)
}
