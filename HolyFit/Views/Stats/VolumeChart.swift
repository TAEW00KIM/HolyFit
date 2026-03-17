import SwiftUI
import SwiftData
import Charts

struct VolumeChart: View {
    @Query(sort: \WorkoutSession.startDate) private var sessions: [WorkoutSession]
    @State private var viewModel = StatsViewModel()
    @State private var selectedPoint: StatsViewModel.VolumeDataPoint?

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                DateRangeFilterView(selected: $viewModel.dateRange)

                let data = viewModel.volumeProgression(sessions: sessions)

                if data.isEmpty {
                    ContentUnavailableView(
                        "데이터가 없습니다",
                        systemImage: "chart.bar.fill",
                        description: Text("운동을 기록하면 볼륨 추이를 볼 수 있습니다")
                    )
                    .padding(.top, AppSpacing.xxl)
                } else {
                    VolumeBarChartCard(data: data, selectedPoint: $selectedPoint)
                        .padding(.horizontal, AppSpacing.md)

                    if let point = selectedPoint {
                        SelectedPointCard(
                            date: point.date,
                            value: String(format: "%.0f kg", point.totalVolume),
                            label: "총 볼륨",
                            color: Color(hex: "00B894")
                        )
                        .padding(.horizontal, AppSpacing.md)
                    }

                    // Volume summary stats
                    VolumeSummaryRow(data: data)
                        .padding(.horizontal, AppSpacing.md)
                }

                Spacer(minLength: AppSpacing.xxl)
            }
            .padding(.top, AppSpacing.md)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("볼륨 추이")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Volume Bar Chart Card

private struct VolumeBarChartCard: View {
    let data: [StatsViewModel.VolumeDataPoint]
    @Binding var selectedPoint: StatsViewModel.VolumeDataPoint?

    private let barColors = [Color(hex: "00B894"), Color(hex: "55E6C1")]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("볼륨 추이")
                        .font(AppFont.heading(16))
                        .foregroundStyle(.primary)
                    if let max = data.max(by: { $0.totalVolume < $1.totalVolume }) {
                        Text("최고: \(String(format: "%.0f", max.totalVolume)) kg")
                            .font(AppFont.caption(13))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: "00B894"))
            }

            Chart(data) { point in
                BarMark(
                    x: .value("날짜", point.date, unit: .day),
                    y: .value("볼륨", point.totalVolume),
                    width: .ratio(0.5)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: barColors,
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(5)

                if let sel = selectedPoint, sel.id == point.id {
                    RuleMark(x: .value("날짜", point.date))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        .foregroundStyle(Color(hex: "00B894").opacity(0.5))
                        .annotation(position: .top) {
                            Text("\(Int(point.totalVolume))kg")
                                .font(AppFont.caption(11))
                                .fontWeight(.bold)
                                .foregroundStyle(Color(hex: "00B894"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(AppColors.surfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.secondary.opacity(0.2))
                    AxisValueLabel(format: .dateTime.month().day())
                        .font(AppFont.caption(10))
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.secondary.opacity(0.2))
                    AxisValueLabel {
                        if let val = value.as(Double.self) {
                            Text("\(Int(val))kg")
                                .font(AppFont.caption(10))
                        }
                    }
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

// MARK: - Volume Summary Row

private struct VolumeSummaryRow: View {
    let data: [StatsViewModel.VolumeDataPoint]

    private var totalVolume: Double { data.reduce(0) { $0 + $1.totalVolume } }
    private var avgVolume: Double { data.isEmpty ? 0 : totalVolume / Double(data.count) }
    private var maxVolume: Double { data.map(\.totalVolume).max() ?? 0 }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            VolumeStat(label: "총 볼륨", value: formatKg(totalVolume), color: Color(hex: "00B894"))
            VolumeStat(label: "평균", value: formatKg(avgVolume), color: Color(hex: "55E6C1"))
            VolumeStat(label: "최고", value: formatKg(maxVolume), color: AppColors.gradientStart)
        }
    }

    private func formatKg(_ val: Double) -> String {
        val >= 1000 ? String(format: "%.1ft", val / 1000) : String(format: "%.0fkg", val)
    }
}

private struct VolumeStat: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(label)
                .font(AppFont.caption(11))
                .foregroundStyle(.secondary)
            Text(value)
                .font(AppFont.heading(16))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.sm)
        .glassCard(cornerRadius: AppRadius.lg)
    }
}
