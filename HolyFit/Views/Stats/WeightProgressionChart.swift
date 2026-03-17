import SwiftUI
import SwiftData
import Charts

struct WeightProgressionChart: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.startDate) private var sessions: [WorkoutSession]
    @State private var viewModel = StatsViewModel()
    @State private var selectedPoint: StatsViewModel.WeightDataPoint?

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                // 운동 선택
                ExerciseSelector(exercises: exercises, selected: $viewModel.selectedExercise)
                    .padding(.horizontal, AppSpacing.md)

                // 날짜 범위
                DateRangeFilterView(selected: $viewModel.dateRange)

                if let exercise = viewModel.selectedExercise {
                    let data = viewModel.weightProgression(for: exercise, sessions: sessions)

                    if data.isEmpty {
                        emptyDataView
                    } else {
                        // Chart card
                        WeightChartCard(data: data, selectedPoint: $selectedPoint)
                            .padding(.horizontal, AppSpacing.md)

                        // Selected point detail
                        if let point = selectedPoint {
                            SelectedPointCard(
                                date: point.date,
                                value: String(format: "%.1f kg", point.maxWeight),
                                label: "최고 중량",
                                color: AppColors.gradientStart
                            )
                            .padding(.horizontal, AppSpacing.md)
                        }
                    }
                } else {
                    noExerciseView
                }

                Spacer(minLength: AppSpacing.xxl)
            }
            .padding(.top, AppSpacing.md)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("중량 추이")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyDataView: some View {
        ContentUnavailableView(
            "데이터가 없습니다",
            systemImage: "chart.line.uptrend.xyaxis",
            description: Text("이 운동의 기록이 없습니다")
        )
        .padding(.top, AppSpacing.xxl)
    }

    private var noExerciseView: some View {
        ContentUnavailableView(
            "운동을 선택하세요",
            systemImage: "figure.strengthtraining.traditional",
            description: Text("위에서 운동을 선택하면 중량 추이를 볼 수 있습니다")
        )
        .padding(.top, AppSpacing.xxl)
    }
}

// MARK: - Weight Chart Card

private struct WeightChartCard: View {
    let data: [StatsViewModel.WeightDataPoint]
    @Binding var selectedPoint: StatsViewModel.WeightDataPoint?

    private var minWeight: Double { (data.map(\.maxWeight).min() ?? 0) * 0.95 }
    private var maxWeight: Double {
        let raw = (data.map(\.maxWeight).max() ?? 100) * 1.05
        return raw > minWeight ? raw : minWeight + 10
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("중량 추이")
                        .font(AppFont.heading(16))
                        .foregroundStyle(.primary)
                    if let latest = data.last {
                        Text("최근: \(String(format: "%.1f", latest.maxWeight)) kg")
                            .font(AppFont.caption(13))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.gradientStart)
            }

            Chart(data) { point in
                // Gradient area fill
                AreaMark(
                    x: .value("날짜", point.date),
                    yStart: .value("min", minWeight),
                    yEnd: .value("중량", point.maxWeight)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            AppColors.gradientStart.opacity(0.35),
                            AppColors.gradientStart.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Line
                LineMark(
                    x: .value("날짜", point.date),
                    y: .value("중량", point.maxWeight)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(AppColors.primaryGradient)
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                // Points
                PointMark(
                    x: .value("날짜", point.date),
                    y: .value("중량", point.maxWeight)
                )
                .foregroundStyle(AppColors.gradientStart)
                .symbolSize(selectedPoint?.id == point.id ? 120 : 60)
            }
            .chartYScale(domain: minWeight...maxWeight)
            .chartYAxisLabel("kg")
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.secondary.opacity(0.2))
                    AxisValueLabel(format: .dateTime.month().day())
                        .font(AppFont.caption(10))
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.secondary.opacity(0.2))
                    AxisValueLabel()
                        .font(AppFont.caption(10))
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            guard let date: Date = proxy.value(atX: location.x) else { return }
                            selectedPoint = data.min(by: {
                                abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                            })
                        }
                }
            }
            .frame(height: 240)
        }
        .padding(AppSpacing.md)
        .glassCard(cornerRadius: AppRadius.xl)
    }
}

// MARK: - Selected Point Card

struct SelectedPointCard: View {
    let date: Date
    let value: String
    let label: String
    let color: Color

    private var formattedDate: String {
        AppDateFormatter.shortDate.string(from: date)
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color)
                .frame(width: 4, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(AppFont.caption(12))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(AppFont.heading(18))
                    .foregroundStyle(.primary)
            }

            Spacer()

            Text(formattedDate)
                .font(AppFont.caption(13))
                .foregroundStyle(.secondary)
        }
        .padding(AppSpacing.md)
        .glassCard(cornerRadius: AppRadius.lg)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Exercise Selector

struct ExerciseSelector: View {
    let exercises: [Exercise]
    @Binding var selected: Exercise?
    @State private var searchText = ""

    private var usedExercises: [Exercise] {
        exercises.filter { !$0.entries.isEmpty }
    }

    private var filtered: [Exercise] {
        if searchText.isEmpty { return usedExercises }
        return usedExercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            if let exercise = selected {
                // Selected state
                HStack(spacing: AppSpacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                            .fill(AppColors.muscleGroupColor(exercise.muscleGroup).opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: exercise.muscleGroup.icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppColors.muscleGroupColor(exercise.muscleGroup))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(AppFont.heading(16))
                            .foregroundStyle(.primary)
                        Text(exercise.muscleGroup.rawValue)
                            .font(AppFont.caption(12))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selected = nil
                        }
                    } label: {
                        Text("변경")
                            .font(AppFont.caption(13))
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.accent)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, 5)
                            .background(AppColors.accent.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding(AppSpacing.md)
                .glassCard(cornerRadius: AppRadius.lg)

            } else {
                // Search + chips
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    TextField("운동 검색", text: $searchText)
                        .font(AppFont.body(15))
                }
                .padding(AppSpacing.sm + 4)
                .glassCard(cornerRadius: AppRadius.lg)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(filtered.prefix(20)) { exercise in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selected = exercise
                                    searchText = ""
                                }
                            } label: {
                                HStack(spacing: AppSpacing.xs) {
                                    Circle()
                                        .fill(AppColors.muscleGroupColor(exercise.muscleGroup))
                                        .frame(width: 7, height: 7)
                                    Text(exercise.name)
                                        .font(AppFont.caption(13))
                                        .fontWeight(.medium)
                                }
                                .foregroundStyle(.primary)
                                .padding(.horizontal, AppSpacing.sm + 2)
                                .padding(.vertical, AppSpacing.xs + 4)
                                .background(AppColors.surfaceElevated)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }
}
