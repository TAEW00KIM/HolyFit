import WidgetKit
import SwiftUI

// MARK: - Widget colors

private enum WidgetColors {
    static let accent      = Color(red: 0.808, green: 0.353, blue: 0.333)  // #CE5A55
    static let success     = Color(red: 0.204, green: 0.780, blue: 0.349)  // #34C759
    static let darkBg      = Color(red: 0.071, green: 0.071, blue: 0.078)  // #121214
    static let lightBg     = Color(red: 0.965, green: 0.953, blue: 0.953)  // #F7F3F3
}

// MARK: - Container Background

struct WidgetBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        (colorScheme == .dark ? WidgetColors.darkBg : WidgetColors.lightBg)
            .ignoresSafeArea()
    }
}

// MARK: - Entry View

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
    private var primaryText: Color { isDark ? .white : Color(red: 0.1, green: 0.1, blue: 0.12) }
    private var secondaryText: Color { isDark ? .white.opacity(0.5) : Color(red: 0.55, green: 0.55, blue: 0.58) }

    var body: some View {
        VStack(spacing: 0) {
            if didWorkOut {
                completedView
            } else {
                notCompletedView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var completedView: some View {
        VStack(spacing: 8) {
            // Logo
            HStack(spacing: 4) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(WidgetColors.accent)
                Text("HolyFit")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(secondaryText)
            }

            Spacer()

            // Checkmark + 완료!
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(WidgetColors.success)

            Text("완료!")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(primaryText)

            Spacer()

            // Stats
            HStack(spacing: 4) {
                Text("\(entry.duration)분")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(secondaryText)
                Text("·")
                    .foregroundStyle(secondaryText.opacity(0.5))
                Text(volumeString)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(secondaryText)
            }
        }
        .padding(14)
    }

    private var notCompletedView: some View {
        VStack(spacing: 8) {
            // Logo
            HStack(spacing: 4) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(WidgetColors.accent)
                Text("HolyFit")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(secondaryText)
            }

            Spacer()

            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(WidgetColors.accent.opacity(0.6))

            Text("오늘도\n운동하세요")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(primaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Spacer()
        }
        .padding(14)
    }

    private var volumeString: String {
        if entry.volume >= 1000 {
            return String(format: "%.0fkg", entry.volume)
        }
        return String(format: "%.0fkg", entry.volume)
    }
}

// MARK: - Medium Widget

private struct MediumWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: HolyFitWidgetEntry

    private var didWorkOut: Bool { entry.workoutCount > 0 }
    private var isDark: Bool { colorScheme == .dark }
    private var primaryText: Color { isDark ? .white : Color(red: 0.1, green: 0.1, blue: 0.12) }
    private var secondaryText: Color { isDark ? .white.opacity(0.5) : Color(red: 0.55, green: 0.55, blue: 0.58) }

    var body: some View {
        if didWorkOut {
            completedView
        } else {
            notCompletedView
        }
    }

    private var completedView: some View {
        HStack(spacing: 0) {
            // Left content
            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack(spacing: 5) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(WidgetColors.accent)
                    Text("오늘 운동")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(secondaryText)
                }

                // 완료!
                Text("완료!")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(primaryText)

                Spacer()

                // Stats row
                HStack(spacing: 10) {
                    Label("\(entry.duration)분", systemImage: "clock")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(secondaryText)
                    Label(volumeString, systemImage: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(secondaryText)
                    Label("\(entry.calories)kcal", systemImage: "flame")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(secondaryText)
                }
                .labelStyle(WidgetLabelStyle())

                // HolyFit
                Text("HolyFit")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(secondaryText.opacity(0.6))
            }
            .padding(14)

            Spacer()

            // Right: checkmark circle
            ZStack {
                Circle()
                    .fill(WidgetColors.success.opacity(isDark ? 0.2 : 0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(WidgetColors.success)
            }
            .padding(.trailing, 20)
        }
    }

    private var notCompletedView: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(WidgetColors.accent)
                    Text("오늘 운동")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(secondaryText)
                }

                Text("오늘도\n운동하세요 💪")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(primaryText)
                    .lineSpacing(2)

                Spacer()

                Text("HolyFit")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(secondaryText.opacity(0.6))
            }
            .padding(14)

            Spacer()

            ZStack {
                Circle()
                    .strokeBorder(WidgetColors.accent.opacity(0.3), lineWidth: 2)
                    .frame(width: 56, height: 56)
                Image(systemName: "figure.run")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(WidgetColors.accent.opacity(0.5))
            }
            .padding(.trailing, 20)
        }
    }

    private var volumeString: String {
        if entry.volume >= 1000 {
            let formatted = String(format: "%.0f", entry.volume)
            // Add comma separator
            if let num = Int(formatted) {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                return (formatter.string(from: NSNumber(value: num)) ?? formatted) + "kg"
            }
            return formatted + "kg"
        }
        return String(format: "%.0fkg", entry.volume)
    }
}

// MARK: - Widget Label Style

private struct WidgetLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.icon
                .font(.system(size: 10))
            configuration.title
        }
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    HolyFitWidget()
} timeline: {
    HolyFitWidgetEntry(date: .now, workoutCount: 1, calories: 520, protein: 142.0, currentStreak: 5, todayCalories: 1380, duration: 47, volume: 4280)
    HolyFitWidgetEntry(date: .now, workoutCount: 0, calories: 0, protein: 0.0, currentStreak: 0, todayCalories: 0, duration: 0, volume: 0)
}

#Preview(as: .systemMedium) {
    HolyFitWidget()
} timeline: {
    HolyFitWidgetEntry(date: .now, workoutCount: 1, calories: 520, protein: 175.5, currentStreak: 5, todayCalories: 1380, duration: 47, volume: 4280)
    HolyFitWidgetEntry(date: .now, workoutCount: 0, calories: 0, protein: 0.0, currentStreak: 0, todayCalories: 0, duration: 0, volume: 0)
}
