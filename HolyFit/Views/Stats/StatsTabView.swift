import SwiftUI
import SwiftData

struct StatsTabView: View {
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \MealEntry.date, order: .reverse) private var meals: [MealEntry]
    @State private var selectedRange: StatsRange = .week
    @AppStorage("selectedTab") private var selectedTab = 0

    var body: some View {
        NavigationStack {
            if sessions.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: AppSpacing.md) {
                        rangePicker
                            .padding(.horizontal, AppSpacing.md)

                        summaryHeroCard
                            .padding(.horizontal, AppSpacing.md)

                        statsRow
                            .padding(.horizontal, AppSpacing.md)

                        weeklyActivitySection
                            .padding(.horizontal, AppSpacing.md)

                        insightCards
                            .padding(.horizontal, AppSpacing.md)

                        Spacer(minLength: AppSpacing.xxl)
                    }
                    .padding(.top, AppSpacing.sm)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("통계")
                .navigationBarTitleDisplayMode(.large)
            }
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            VStack(spacing: AppSpacing.lg) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 48))
                    .foregroundStyle(AppColors.accent.opacity(0.6))

                VStack(spacing: AppSpacing.xs) {
                    Text("아직 통계가 없어요")
                        .font(AppFont.heading(18))
                    Text("운동을 기록하면\n통계를 확인할 수 있어요")
                        .font(AppFont.body(14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    selectedTab = 0
                } label: {
                    Text("운동 기록하러 가기")
                        .font(AppFont.heading(15))
                        .foregroundStyle(.white)
                        .frame(maxWidth: 200)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                }
            }
            .padding(AppSpacing.xxl)
            .glassCard()
            .padding(.horizontal, AppSpacing.md)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("통계")
        .navigationBarTitleDisplayMode(.large)
    }

    private var filteredSessions: [WorkoutSession] {
        sessions.filter { session in
            session.endDate != nil && session.startDate >= selectedRange.startDate
        }
    }

    private var filteredMeals: [MealEntry] {
        meals.filter { $0.date >= selectedRange.startDate }
    }

    private var totalWorkouts: Int { filteredSessions.count }

    private var totalVolume: Double {
        filteredSessions.reduce(0) { $0 + $1.totalVolume }
    }

    private var totalCalories: Int {
        filteredMeals.compactMap(\.calories).reduce(0, +)
    }

    private var totalDuration: TimeInterval {
        filteredSessions.compactMap(\.duration).reduce(0, +)
    }

    private var completionProgress: Double {
        min(Double(totalWorkouts) / Double(selectedRange.targetWorkoutCount), 1)
    }

    private var bestOneRepMax: Double {
        filteredSessions
            .flatMap(\.entries)
            .flatMap(\.sets)
            .map(\.estimatedOneRepMax)
            .max() ?? 0
    }

    private var weightDelta: Double {
        let validSessions = filteredSessions
            .filter { $0.totalVolume > 0 }
            .sorted { $0.startDate < $1.startDate }

        guard validSessions.count >= 2 else { return 0 }

        let last = validSessions[validSessions.count - 1]
        let previous = validSessions[validSessions.count - 2]

        let lastMax = last.entries.flatMap(\.sets).map(\.weight).max() ?? 0
        let previousMax = previous.entries.flatMap(\.sets).map(\.weight).max() ?? 0

        return lastMax - previousMax
    }

    private var rangePicker: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(StatsRange.allCases) { range in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedRange = range
                    }
                } label: {
                    Text(range.title)
                        .font(AppFont.caption(13))
                        .fontWeight(.semibold)
                        .foregroundStyle(selectedRange == range ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .fill(selectedRange == range ? Color(.systemBackground) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.secondarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
    }

    private var summaryHeroCard: some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(selectedRange.subtitle)
                    .font(AppFont.caption(12))
                    .foregroundStyle(.secondary)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(totalWorkouts)")
                        .font(AppFont.stat(36))
                        .foregroundStyle(AppColors.gradientStart)
                    Text("회")
                        .font(AppFont.heading(18))
                        .foregroundStyle(AppColors.gradientStart)
                }
                Text(progressLabel)
                    .font(AppFont.caption(12))
                    .foregroundStyle(AppColors.success)
            }

            Spacer()

            ProgressRing(progress: completionProgress, label: "\(totalWorkouts)/\(selectedRange.targetWorkoutCount)")
                .frame(width: 80, height: 80)
        }
        .padding(AppSpacing.md + AppSpacing.xs)
        .glassCard(cornerRadius: AppRadius.xl)
    }

    private var statsRow: some View {
        HStack(spacing: AppSpacing.sm) {
            statCard(icon: "scalemass.fill", value: volumeLabel, label: "총 볼륨", color: AppColors.gradientStart)
            statCard(icon: "flame.fill", value: "\(totalCalories)", label: "kcal", color: AppColors.warning)
            statCard(icon: "clock.fill", value: durationLabel, label: "운동 시간", color: AppColors.info)
        }
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(AppFont.heading(18))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(AppFont.caption(11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .glassCard(cornerRadius: AppRadius.lg)
    }

    private var weeklyActivitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("주간 활동")
                .font(AppFont.heading(16))
                .foregroundStyle(.primary)

            HStack(alignment: .bottom, spacing: AppSpacing.sm) {
                ForEach(weekBars) { item in
                    VStack(spacing: AppSpacing.xs) {
                        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                            .fill(item.isActive ? AppColors.primaryGradient : LinearGradient(colors: [Color(.systemFill), Color(.systemFill)], startPoint: .top, endPoint: .bottom))
                            .frame(height: max(18, 20 + item.height * 92))
                        Text(item.label)
                            .font(AppFont.caption(10))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120, alignment: .bottom)
            .padding(AppSpacing.md)
            .glassCard(cornerRadius: AppRadius.xl)
        }
    }

    private var insightCards: some View {
        HStack(spacing: AppSpacing.sm) {
            NavigationLink {
                WeightProgressionChart()
            } label: {
                insightCard(
                    title: "중량 변화",
                    value: formattedDelta(weightDelta),
                    caption: "최근 세션 대비",
                    color: AppColors.success,
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                OneRepMaxChart()
            } label: {
                insightCard(
                    title: "1RM 추정",
                    value: bestOneRepMax > 0 ? "\(Int(bestOneRepMax.rounded()))kg" : "--",
                    caption: "현재 최고치",
                    color: AppColors.gradientStart,
                    icon: "trophy.fill"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func insightCard(title: String, value: String, caption: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                Spacer()
            }

            Text(title)
                .font(AppFont.caption(12))
                .foregroundStyle(.secondary)
            Text(value)
                .font(AppFont.heading(22))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(caption)
                .font(AppFont.caption(11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .glassCard(cornerRadius: AppRadius.xl)
    }

    private var progressLabel: String {
        if totalWorkouts == 0 { return "이번 \(selectedRange.title) 목표를 시작해보세요" }
        return "+ \(Int(completionProgress * 100))% 목표 달성"
    }

    private var volumeLabel: String {
        if totalVolume >= 1000 {
            return NumberFormatter.localizedString(from: NSNumber(value: totalVolume), number: .decimal)
        }
        return String(format: "%.0f", totalVolume)
    }

    private var durationLabel: String {
        totalDuration > 0 ? AppDateFormatter.durationString(from: totalDuration) : "--"
    }

    private func formattedDelta(_ value: Double) -> String {
        guard value != 0 else { return "±0kg" }
        return String(format: "%@%.1fkg", value > 0 ? "+" : "", value)
    }

    private var weekBars: [WeekBar] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let mondayOffset = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: today) ?? today

        let workoutDays = Set(
            filteredSessions.map { calendar.startOfDay(for: $0.startDate) }
        )

        let labels = ["월", "화", "수", "목", "금", "토", "일"]
        return (0..<7).map { index in
            let date = calendar.date(byAdding: .day, value: index, to: monday) ?? monday
            let isActive = workoutDays.contains(date)
            return WeekBar(id: index, label: labels[index], height: isActive ? 1 : 0.1, isActive: isActive)
        }
    }
}

private enum StatsRange: String, CaseIterable, Identifiable {
    case week = "주간"
    case month = "월간"
    case all = "전체"

    var id: String { rawValue }
    var title: String { rawValue }

    var subtitle: String {
        switch self {
        case .week: return "이번 주 운동"
        case .month: return "이번 달 운동"
        case .all: return "전체 운동"
        }
    }

    var targetWorkoutCount: Int {
        switch self {
        case .week: return 5
        case .month: return 12
        case .all: return 30
        }
    }

    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .all:
            return .distantPast
        }
    }
}

private struct WeekBar: Identifiable {
    let id: Int
    let label: String
    let height: Double
    let isActive: Bool
}

private struct ProgressRing: View {
    let progress: Double
    let label: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.gradientStart.opacity(0.12), lineWidth: 6)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AppColors.primaryGradient,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text(label)
                    .font(AppFont.heading(18))
                    .foregroundStyle(.primary)
                Text("달성")
                    .font(AppFont.caption(10))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
