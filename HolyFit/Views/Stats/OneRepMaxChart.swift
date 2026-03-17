import SwiftUI
import SwiftData
import Charts

struct OneRepMaxChart: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.startDate) private var sessions: [WorkoutSession]
    @State private var viewModel = StatsViewModel()
    @State private var selectedPoint: StatsViewModel.OneRepMaxDataPoint?

    private let redGradient = [Color(hex: "FF6B6B"), Color(hex: "F39C12")]

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                ExerciseSelector(exercises: exercises, selected: $viewModel.selectedExercise)
                    .padding(.horizontal, AppSpacing.md)

                DateRangeFilterView(selected: $viewModel.dateRange)

                if let exercise = viewModel.selectedExercise {
                    let data = viewModel.oneRepMaxProgression(for: exercise, sessions: sessions)

                    if data.isEmpty {
                        ContentUnavailableView(
                            "데이터가 없습니다",
                            systemImage: "trophy.fill",
                            description: Text("이 운동의 기록이 없습니다")
                        )
                        .padding(.top, AppSpacing.xxl)
                    } else {
                        // Best 1RM trophy card
                        if let best = data.max(by: { $0.estimatedMax < $1.estimatedMax }) {
                            BestOneRMCard(value: best.estimatedMax, date: best.date, colors: redGradient)
                                .padding(.horizontal, AppSpacing.md)
                        }

                        // Chart
                        OneRMChartCard(data: data, selectedPoint: $selectedPoint, colors: redGradient)
                            .padding(.horizontal, AppSpacing.md)

                        // Tap detail
                        if let point = selectedPoint {
                            SelectedPointCard(
                                date: point.date,
                                value: String(format: "%.1f kg", point.estimatedMax),
                                label: "추정 1RM",
                                color: Color(hex: "FF6B6B")
                            )
                            .padding(.horizontal, AppSpacing.md)
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "운동을 선택하세요",
                        systemImage: "trophy",
                        description: Text("위에서 운동을 선택하면 1RM 추정 추이를 볼 수 있습니다")
                    )
                    .padding(.top, AppSpacing.xxl)
                }

                Spacer(minLength: AppSpacing.xxl)
            }
            .padding(.top, AppSpacing.md)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("1RM 추정")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Best 1RM Trophy Card

private struct BestOneRMCard: View {
    let value: Double
    let date: Date
    let colors: [Color]

    private var formattedDate: String {
        AppDateFormatter.dateOnly.string(from: date)
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 56, height: 56)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("최고 추정 1RM")
                    .font(AppFont.caption(12))
                    .foregroundStyle(.white.opacity(0.8))
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", value))
                        .font(AppFont.stat(32))
                        .foregroundStyle(.white)
                    Text("kg")
                        .font(AppFont.heading(16))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
                Text(formattedDate)
                    .font(AppFont.caption(12))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(AppSpacing.md)
        .gradientCard(colors: colors, cornerRadius: AppRadius.xl)
    }
}

// MARK: - 1RM Line Chart Card

private struct OneRMChartCard: View {
    let data: [StatsViewModel.OneRepMaxDataPoint]
    @Binding var selectedPoint: StatsViewModel.OneRepMaxDataPoint?
    let colors: [Color]

    private var minVal: Double { (data.map(\.estimatedMax).min() ?? 0) * 0.93 }
    private var maxVal: Double {
        let raw = (data.map(\.estimatedMax).max() ?? 100) * 1.07
        return raw > minVal ? raw : minVal + 10
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("1RM 추정 추이")
                        .font(AppFont.heading(16))
                        .foregroundStyle(.primary)
                    Text("Epley 공식 기반")
                        .font(AppFont.caption(12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: "FF6B6B"))
            }

            Chart(data) { point in
                // Gradient area
                AreaMark(
                    x: .value("날짜", point.date),
                    yStart: .value("min", minVal),
                    yEnd: .value("1RM", point.estimatedMax)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "FF6B6B").opacity(0.35),
                            Color(hex: "FF6B6B").opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Line
                LineMark(
                    x: .value("날짜", point.date),
                    y: .value("1RM", point.estimatedMax)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                )
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                // Points
                PointMark(
                    x: .value("날짜", point.date),
                    y: .value("1RM", point.estimatedMax)
                )
                .foregroundStyle(Color(hex: "FF6B6B"))
                .symbolSize(selectedPoint?.id == point.id ? 120 : 55)
            }
            .chartYScale(domain: minVal...maxVal)
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
                GeometryReader { _ in
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
