import SwiftUI
import SwiftData

// MARK: - WeeklySummaryView

struct WeeklySummaryView: View {
    @Environment(\.modelContext) private var modelContext

    private static let koreanDayLabels = ["월", "화", "수", "목", "금", "토", "일"]

    // MARK: Week range (Monday–Sunday)

    private var weekInterval: DateInterval {
        let cal = Calendar.current
        let now = Date()
        // weekOfYear interval starts on Sunday in Gregorian; shift to Monday
        let weekdayComponent = cal.component(.weekday, from: now)
        // weekday: 1=Sun, 2=Mon, ..., 7=Sat
        let daysFromMonday = (weekdayComponent + 5) % 7  // 0=Mon … 6=Sun
        let startOfDay = cal.startOfDay(for: now)
        let monday = cal.date(byAdding: .day, value: -daysFromMonday, to: startOfDay) ?? startOfDay
        let sunday = cal.date(byAdding: .day, value: 6, to: monday) ?? startOfDay
        let endOfSunday = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: sunday)) ?? sunday
        return DateInterval(start: monday, end: endOfSunday)
    }

    private var weekDates: [Date] {
        let cal = Calendar.current
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: weekInterval.start) }
    }

    // MARK: Filtered data

    private var weeklySessions: [WorkoutSession] {
        let interval = weekInterval
        let start = interval.start
        let end = interval.end
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { $0.startDate >= start && $0.startDate < end && $0.endDate != nil },
            sortBy: [SortDescriptor(\.startDate)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private var weeklyMeals: [MealEntry] {
        let interval = weekInterval
        let start = interval.start
        let end = interval.end
        let descriptor = FetchDescriptor<MealEntry>(
            predicate: #Predicate<MealEntry> { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.date)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: Computed stats

    private var sessionCount: Int { weeklySessions.count }

    private var totalVolume: Double {
        weeklySessions.reduce(0) { $0 + $1.totalVolume }
    }

    private var totalVolumeDisplay: (value: String, unit: String) {
        if totalVolume >= 1000 {
            return (String(format: "%.1f", totalVolume / 1000), "t")
        }
        return (String(format: "%.0f", totalVolume), "kg")
    }

    private var averageCalories: Int {
        let daysWithData = Set(weeklyMeals.map { Calendar.current.startOfDay(for: $0.date) })
        guard !daysWithData.isEmpty else { return 0 }
        let total = weeklyMeals.reduce(0) { $0 + ($1.calories ?? 0) }
        return total / daysWithData.count
    }

    private var workedOutDays: Int {
        Set(weeklySessions.map { Calendar.current.startOfDay(for: $0.startDate) }).count
    }

    private var workedOutDaySet: Set<Date> {
        Set(weeklySessions.map { Calendar.current.startOfDay(for: $0.startDate) })
    }

    private var hasAnyData: Bool {
        !weeklySessions.isEmpty || !weeklyMeals.isEmpty
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            headerRow
            if hasAnyData {
                statsGrid
                dayIndicator
            } else {
                emptyState
            }
        }
        .padding(AppSpacing.md)
        .glassCard(cornerRadius: AppRadius.xl)
    }

    // MARK: Header

    private var headerRow: some View {
        HStack {
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.gradientStart, AppColors.gradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text("이번 주 요약")
                    .font(AppFont.heading(17))
                    .foregroundStyle(.primary)
            }
            Spacer()
            Text(weekRangeLabel)
                .font(AppFont.caption(12))
                .foregroundStyle(.secondary)
        }
    }

    private var weekRangeLabel: String {
        let start = AppDateFormatter.chartDate.string(from: weekInterval.start)
        let end: String = {
            // end is exclusive (start of next day after Sunday), show Sunday
            let cal = Calendar.current
            let sundayEnd = weekInterval.end
            let sunday = cal.date(byAdding: .second, value: -1, to: sundayEnd) ?? sundayEnd
            return AppDateFormatter.chartDate.string(from: sunday)
        }()
        return "\(start) – \(end)"
    }

    // MARK: Stats Grid

    private var statsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: AppSpacing.sm),
                GridItem(.flexible(), spacing: AppSpacing.sm)
            ],
            spacing: AppSpacing.sm
        ) {
            WeeklyStatCell(
                icon: "figure.strengthtraining.traditional",
                label: "운동 횟수",
                value: "\(sessionCount)",
                unit: "회",
                colors: [AppColors.gradientStart, AppColors.gradientEnd]
            )
            WeeklyStatCell(
                icon: "scalemass.fill",
                label: "총 볼륨",
                value: totalVolumeDisplay.value,
                unit: totalVolumeDisplay.unit,
                colors: [Color(hex: "F39C12"), Color(hex: "FDCB6E")]
            )
            WeeklyStatCell(
                icon: "fork.knife",
                label: "평균 칼로리",
                value: averageCalories > 0 ? "\(averageCalories)" : "-",
                unit: averageCalories > 0 ? "kcal" : "",
                colors: [AppColors.danger, Color(hex: "FF9FF3")]
            )
            WeeklyStatCell(
                icon: "checkmark.seal.fill",
                label: "운동 일수",
                value: "\(workedOutDays)/7",
                unit: "일",
                colors: [AppColors.success, Color(hex: "55E6C1")]
            )
        }
    }

    // MARK: Day Indicator

    private var dayIndicator: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekDates.enumerated()), id: \.offset) { index, date in
                VStack(spacing: AppSpacing.xs) {
                    Text(Self.koreanDayLabels[index])
                        .font(AppFont.caption(11))
                        .foregroundStyle(.secondary)

                    let isWorkedOut = workedOutDaySet.contains(Calendar.current.startOfDay(for: date))
                    let isToday = Calendar.current.isDateInToday(date)

                    ZStack {
                        Circle()
                            .fill(
                                isWorkedOut
                                    ? LinearGradient(
                                        colors: [AppColors.gradientStart, AppColors.gradientEnd],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                      )
                                    : LinearGradient(
                                        colors: [Color(.systemFill), Color(.systemFill)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                      )
                            )
                            .frame(width: 28, height: 28)

                        if isToday && !isWorkedOut {
                            Circle()
                                .strokeBorder(AppColors.gradientStart.opacity(0.6), lineWidth: 1.5)
                                .frame(width: 28, height: 28)
                        }

                        if isWorkedOut {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        } else {
                            Text(dayNumber(for: date))
                                .font(.system(size: 11, weight: isToday ? .bold : .regular, design: .rounded))
                                .foregroundStyle(isToday ? AppColors.gradientStart : Color(.tertiaryLabel))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, AppSpacing.xs)
    }

    private func dayNumber(for date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        return "\(day)"
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            dayIndicator

            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(AppColors.warning)
                Text("이번 주 첫 운동을 시작해보세요!")
                    .font(AppFont.body(14))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, AppSpacing.xs)
        }
    }
}

// MARK: - WeeklyStatCell

private struct WeeklyStatCell: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let colors: [Color]

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .fill(
                        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 36, height: 36)
                    .shadow(color: colors.first?.opacity(0.3) ?? .clear, radius: 4, x: 0, y: 2)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(AppFont.stat(18))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(AppFont.caption(11))
                            .foregroundStyle(.secondary)
                    }
                }
                Text(label)
                    .font(AppFont.caption(11))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.sm)
        .glassEffect(.regular, in: .rect(cornerRadius: AppRadius.md))
    }
}
