import WidgetKit
import SwiftUI

// MARK: - Widget colors — adapts to light / dark

private enum WidgetColors {
    static let gradientStart = Color(red: 0.902, green: 0.224, blue: 0.275)  // #E63946
    static let gradientEnd   = Color(red: 1.0,   green: 0.176, blue: 0.333)  // #FF2D55
    static let calorieColor  = Color(red: 1.0,   green: 0.271, blue: 0.227)  // #FF453A
    static let proteinColor  = Color(red: 0.039, green: 0.518, blue: 1.0)    // #0A84FF
    static let successColor  = Color(red: 0.188, green: 0.820, blue: 0.345)  // #30D158

    // Dark surfaces
    static let darkBg        = Color(red: 0.071, green: 0.071, blue: 0.078)  // #121214
    static let darkSurface   = Color(red: 0.141, green: 0.141, blue: 0.157)  // #242428

    // Light surfaces (warm rose tint, NOT white)
    static let lightBg       = Color(red: 0.965, green: 0.945, blue: 0.945)  // #F7F1F1
    static let lightSurface  = Color(red: 0.945, green: 0.918, blue: 0.918)  // #F1EAEA

    static let primaryGradient = LinearGradient(
        colors: [gradientStart, gradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Widget Background (used by containerBackground)

struct WidgetBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        (colorScheme == .dark ? WidgetColors.darkBg : WidgetColors.lightBg)
            .ignoresSafeArea()
    }
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
    @Environment(\.colorScheme) private var colorScheme
    let entry: HolyFitWidgetEntry

    private var didWorkOut: Bool { entry.workoutCount > 0 }
    private var isDark: Bool { colorScheme == .dark }

    private var bgColor: Color { isDark ? WidgetColors.darkBg : WidgetColors.lightBg }
    private var primaryText: Color { isDark ? .white : Color(red: 0.1, green: 0.1, blue: 0.12) }
    private var secondaryText: Color { isDark ? .white.opacity(0.55) : Color(red: 0.4, green: 0.4, blue: 0.45) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Workout status badge
            HStack(spacing: 5) {
                Image(systemName: didWorkOut ? "checkmark.circle.fill" : "dumbbell.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(didWorkOut ? WidgetColors.successColor : WidgetColors.gradientStart)
                    Text(didWorkOut ? "운동 완료!" : "운동 전")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(primaryText.opacity(0.9))
                }

                if didWorkOut {
                    // Completed: streak + celebration
                    if entry.currentStreak > 0 {
                        HStack(spacing: 3) {
                            Text("🔥")
                                .font(.system(size: 11))
                            Text("\(entry.currentStreak)일 연속")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(primaryText.opacity(0.9))
                        }
                    }

                    Spacer()

                    // Calorie hero
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .lastTextBaseline, spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(WidgetColors.calorieColor)
                            Text("\(entry.calories)")
                                .font(.system(size: 30, weight: .heavy))
                                .foregroundStyle(primaryText)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }
                        Text("kcal")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(secondaryText)
                    }
                } else {
                    // Not completed: motivational
                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("오늘도")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(secondaryText)
                        Text("운동하세요 💪")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(primaryText)
                    }
                }

                // Accent bar
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(WidgetColors.primaryGradient)
                    .frame(height: 3)
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Medium Widget

private struct MediumWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: HolyFitWidgetEntry

    private var didWorkOut: Bool { entry.workoutCount > 0 }
    private var isDark: Bool { colorScheme == .dark }

    private var bgColor: Color { isDark ? WidgetColors.darkBg : WidgetColors.lightBg }
    private var surfaceColor: Color { isDark ? WidgetColors.darkSurface : WidgetColors.lightSurface }
    private var primaryText: Color { isDark ? .white : Color(red: 0.1, green: 0.1, blue: 0.12) }
    private var secondaryText: Color { isDark ? .gray : Color(red: 0.45, green: 0.45, blue: 0.5) }

    var body: some View {
        HStack(spacing: 0) {
            // Left panel – workout status
            VStack(alignment: .leading, spacing: 8) {
                Label("오늘 운동", systemImage: "dumbbell.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(WidgetColors.gradientStart)

                    Spacer()

                    if didWorkOut {
                        // Completed: gradient circle badge
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
                    } else {
                        // Not completed: outline circle
                        ZStack {
                            Circle()
                                .strokeBorder(WidgetColors.gradientStart.opacity(0.4), lineWidth: 2)
                                .frame(width: 52, height: 52)
                            Image(systemName: "figure.run")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(WidgetColors.gradientStart.opacity(0.6))
                        }
                    }

                    Spacer()

                    // Status label
                    HStack(spacing: 4) {
                        Image(systemName: didWorkOut ? "checkmark.seal.fill" : "xmark.seal")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(didWorkOut ? WidgetColors.successColor : secondaryText)
                        Text(didWorkOut ? "완료!" : "미완료")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(didWorkOut ? WidgetColors.successColor : secondaryText)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.leading, 14)
                .padding(.vertical, 14)

                // Divider
                Rectangle()
                    .fill(isDark ? WidgetColors.gradientStart.opacity(0.3) : WidgetColors.gradientStart.opacity(0.15))
                    .frame(width: 1)
                    .padding(.vertical, 14)

                // Right panel – nutrition summary + streak
                VStack(alignment: .leading, spacing: 6) {
                    Text("영양 요약")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(secondaryText)

                    Spacer()

                    NutritionRow(
                        icon: "flame.fill",
                        color: WidgetColors.calorieColor,
                        label: "칼로리",
                        value: "\(entry.calories)",
                        unit: "kcal",
                        primaryText: primaryText,
                        secondaryText: secondaryText
                    )

                    NutritionRow(
                        icon: "bolt.heart.fill",
                        color: WidgetColors.proteinColor,
                        label: "단백질",
                        value: String(format: "%.0f", entry.protein),
                        unit: "g",
                        primaryText: primaryText,
                        secondaryText: secondaryText
                    )

                    NutritionRow(
                        icon: "fork.knife",
                        color: WidgetColors.successColor,
                        label: "식사",
                        value: entry.todayCalories.formatted(),
                        unit: "kcal",
                        primaryText: primaryText,
                        secondaryText: secondaryText
                    )

                    Spacer()

                    // Streak badge
                    if entry.currentStreak > 0 {
                        HStack(spacing: 3) {
                            Text("🔥")
                                .font(.system(size: 10))
                            Text("\(entry.currentStreak)일 연속")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(primaryText.opacity(0.85))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
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
    let primaryText: Color
    let secondaryText: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 16)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(secondaryText)

            Spacer()

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(primaryText)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                Text(unit)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(secondaryText)
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
