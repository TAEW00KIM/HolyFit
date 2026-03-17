import SwiftUI
import SwiftData

// MARK: - WorkoutCalendarCard

struct WorkoutCalendarCard: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<WorkoutSession> { $0.endDate != nil },
        sort: \WorkoutSession.startDate,
        order: .reverse
    ) private var sessions: [WorkoutSession]

    @State private var displayedMonth: Date = Date()

    private let calendar = Calendar.current
    private let weekdaySymbols = ["월", "화", "수", "목", "금", "토", "일"]

    // MARK: - Computed Properties

    private var workoutDays: Set<DateComponents> {
        var days = Set<DateComponents>()
        for session in sessions {
            let comps = calendar.dateComponents([.year, .month, .day], from: session.startDate)
            days.insert(comps)
        }
        return days
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: displayedMonth)
    }

    private var daysInMonth: [DayItem] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        // Weekday of first day (convert Sunday=1 to Monday-based: Mon=0..Sun=6)
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let mondayOffset = (firstWeekday + 5) % 7

        var items: [DayItem] = []

        // Leading empty cells
        for _ in 0..<mondayOffset {
            items.append(DayItem(day: 0, date: nil, isCurrentMonth: false))
        }

        // Actual days
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                items.append(DayItem(day: day, date: date, isCurrentMonth: true))
            }
        }

        return items
    }

    private var monthlyWorkoutCount: Int {
        let comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let year = comps.year, let month = comps.month else { return 0 }
        return sessions.filter {
            let c = calendar.dateComponents([.year, .month], from: $0.startDate)
            return c.year == year && c.month == month
        }.count
    }

    private var currentStreak: Int {
        let today = calendar.startOfDay(for: Date())

        // Collect unique workout dates sorted descending
        var uniqueDates = Set<Date>()
        for session in sessions {
            uniqueDates.insert(calendar.startOfDay(for: session.startDate))
        }
        let sorted = uniqueDates.sorted(by: >)
        guard !sorted.isEmpty else { return 0 }

        var streak = 0
        // Start from today or yesterday
        var checkDate = today
        if sorted.first != today {
            // If no workout today, start checking from yesterday
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
            checkDate = yesterday
        }

        for date in sorted {
            if date == checkDate {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else if date < checkDate {
                break
            }
        }

        return streak
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Month navigation
            monthNavigationHeader

            // Weekday labels
            weekdayHeader

            // Day grid
            dayGrid

            // Divider
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, AppSpacing.xs)

            // Stats row
            statsRow
        }
        .padding(AppSpacing.md)
        .glassCard()
    }

    // MARK: - Subviews

    private var monthNavigationHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if let prev = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
                        displayedMonth = prev
                    }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }

            Spacer()

            Text(monthTitle)
                .font(AppFont.heading(17))
                .foregroundStyle(.primary)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
                        displayedMonth = next
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
        }
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(AppFont.caption(11))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var dayGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: AppSpacing.xs) {
            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, item in
                dayCell(item)
            }
        }
    }

    private func dayCell(_ item: DayItem) -> some View {
        Group {
            if item.day == 0 {
                Color.clear
                    .frame(height: 36)
            } else {
                let isToday = item.date.map { calendar.isDateInToday($0) } ?? false
                let hasWorkout = item.date.map { date in
                    let comps = calendar.dateComponents([.year, .month, .day], from: date)
                    return workoutDays.contains(comps)
                } ?? false

                ZStack {
                    if hasWorkout {
                        Circle()
                            .fill(AppColors.primaryGradient)
                            .frame(width: 30, height: 30)
                    } else if isToday {
                        Circle()
                            .strokeBorder(AppColors.accent, lineWidth: 1.5)
                            .frame(width: 30, height: 30)
                    }

                    Text("\(item.day)")
                        .font(AppFont.caption(13))
                        .foregroundStyle(hasWorkout ? .white : isToday ? AppColors.accent : .primary)
                }
                .frame(height: 36)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: AppSpacing.sm) {
            // Streak badge
            if currentStreak > 0 {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("연속 \(currentStreak)일 운동 중!")
                        .font(AppFont.caption(13))
                        .lineLimit(1)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs + 2)
                .background(AppColors.primaryGradient)
                .clipShape(Capsule())
            }

            Spacer()

            // Monthly count
            Text("이번 달 \(monthlyWorkoutCount)회 운동")
                .font(AppFont.caption(13))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - DayItem

private struct DayItem {
    let day: Int
    let date: Date?
    let isCurrentMonth: Bool
}
