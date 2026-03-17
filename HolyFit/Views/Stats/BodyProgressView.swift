import SwiftUI
import SwiftData
import Charts

struct BodyProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]

    @AppStorage("profileWeight") private var profileWeight: Double = 0
    @AppStorage("profileMuscleMass") private var profileMuscleMass: Double = 0
    @AppStorage("profileBodyFatPercent") private var profileBodyFatPercent: Double = 0
    @AppStorage("profileBMI") private var profileBMI: Double = 0

    @State private var showAddSheet = false
    @State private var selectedPoint: BodyMeasurement?

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                if measurements.isEmpty {
                    emptyState
                } else {
                    // Chart
                    weightChartSection

                    // Change summary cards
                    if measurements.count >= 2 {
                        changeSummarySection
                    }
                }

                // Add button
                addMeasurementButton

                // History list
                if !measurements.isEmpty {
                    historySection
                }

                Spacer(minLength: AppSpacing.xxl)
            }
            .padding(.top, AppSpacing.md)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("체성분 추이")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                AddBodyMeasurementSheet()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "figure.arms.open")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.accent.opacity(0.6))

            VStack(spacing: AppSpacing.xs) {
                Text("아직 기록이 없습니다")
                    .font(AppFont.heading(18))
                Text("체성분을 기록해보세요")
                    .font(AppFont.body(14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showAddSheet = true
            } label: {
                Text("기록 추가")
                    .font(AppFont.heading(15))
                    .foregroundStyle(.white)
                    .frame(maxWidth: 200)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColors.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            }
        }
        .padding(AppSpacing.xxl)
        .frame(maxWidth: .infinity)
        .glassCard()
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Weight Chart

    private var chartData: [BodyMeasurement] {
        measurements.sorted { $0.date < $1.date }
    }

    private var weightChartSection: some View {
        let data = chartData
        let weights = data.map(\.weight)
        let minW = (weights.min() ?? 50) * 0.97
        let maxW: Double = {
            let raw = (weights.max() ?? 80) * 1.03
            return raw > minW ? raw : minW + 10
        }()

        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("체중 추이")
                        .font(AppFont.heading(16))
                        .foregroundStyle(.primary)
                    if let latest = data.last {
                        Text("최근: \(String(format: "%.1f", latest.weight)) kg")
                            .font(AppFont.caption(13))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.protein)
            }

            Chart(data, id: \.id) { point in
                AreaMark(
                    x: .value("날짜", point.date),
                    yStart: .value("min", minW),
                    yEnd: .value("체중", point.weight)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            AppColors.protein.opacity(0.35),
                            AppColors.protein.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("날짜", point.date),
                    y: .value("체중", point.weight)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.protein, AppColors.info],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                PointMark(
                    x: .value("날짜", point.date),
                    y: .value("체중", point.weight)
                )
                .foregroundStyle(AppColors.protein)
                .symbolSize(selectedPoint?.id == point.id ? 120 : 60)
            }
            .chartYScale(domain: minW...maxW)
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

            // Selected point detail
            if let point = selectedPoint {
                SelectedPointCard(
                    date: point.date,
                    value: String(format: "%.1f kg", point.weight),
                    label: "체중",
                    color: AppColors.protein
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(AppSpacing.md)
        .glassCard(cornerRadius: AppRadius.xl)
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Change Summary

    private var changeSummarySection: some View {
        let latest = measurements[0]
        let previous = measurements[1]

        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "arrow.triangle.swap")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.gradientStart)
                Text("최근 변화")
                    .font(AppFont.caption(12))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.secondaryLabel))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .padding(.horizontal, AppSpacing.xs)

            HStack(spacing: AppSpacing.sm) {
                ChangeCard(
                    label: "체중",
                    value: String(format: "%.1f", latest.weight),
                    unit: "kg",
                    delta: latest.weight - previous.weight,
                    invertColor: true
                )

                if let latestMuscle = latest.muscleMass, let prevMuscle = previous.muscleMass {
                    ChangeCard(
                        label: "골격근량",
                        value: String(format: "%.1f", latestMuscle),
                        unit: "kg",
                        delta: latestMuscle - prevMuscle,
                        invertColor: false
                    )
                }

                if let latestFat = latest.bodyFatPercentage, let prevFat = previous.bodyFatPercentage {
                    ChangeCard(
                        label: "체지방률",
                        value: String(format: "%.1f", latestFat),
                        unit: "%",
                        delta: latestFat - prevFat,
                        invertColor: true
                    )
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Add Button

    private var addMeasurementButton: some View {
        Button {
            showAddSheet = true
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("새 기록 추가")
                    .font(AppFont.heading(16))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .gradientCard(cornerRadius: AppRadius.md)
        }
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.gradientStart)
                Text("기록 목록")
                    .font(AppFont.caption(12))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.secondaryLabel))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .padding(.horizontal, AppSpacing.xs)

            VStack(spacing: 0) {
                ForEach(Array(measurements.enumerated()), id: \.element.id) { index, measurement in
                    MeasurementRow(measurement: measurement)

                    if index < measurements.count - 1 {
                        Divider().padding(.leading, 52).opacity(0.4)
                    }
                }
            }
            .glassCard(cornerRadius: AppRadius.xl)
        }
        .padding(.horizontal, AppSpacing.md)
    }
}

// MARK: - Change Card

private struct ChangeCard: View {
    let label: String
    let value: String
    let unit: String
    let delta: Double
    let invertColor: Bool

    private var isPositiveChange: Bool {
        invertColor ? delta < 0 : delta > 0
    }

    private var changeColor: Color {
        if abs(delta) < 0.01 { return .secondary }
        return isPositiveChange ? AppColors.success : AppColors.danger
    }

    private var arrowIcon: String {
        if abs(delta) < 0.01 { return "" }
        return delta > 0 ? "arrow.up" : "arrow.down"
    }

    var body: some View {
        VStack(spacing: AppSpacing.xs + 2) {
            Text(label)
                .font(AppFont.caption(11))
                .foregroundStyle(.secondary)

            Text(value)
                .font(AppFont.stat(24))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(unit)
                .font(AppFont.caption(11))
                .foregroundStyle(.secondary)

            if abs(delta) >= 0.01 {
                HStack(spacing: 2) {
                    Image(systemName: arrowIcon)
                        .font(.system(size: 9, weight: .bold))
                    Text(String(format: "%.1f", abs(delta)))
                        .font(AppFont.caption(11))
                        .fontWeight(.semibold)
                }
                .foregroundStyle(changeColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .padding(.horizontal, AppSpacing.sm)
        .glassCard(cornerRadius: AppRadius.lg)
    }
}

// MARK: - Measurement Row

private struct MeasurementRow: View {
    let measurement: BodyMeasurement

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .fill(AppColors.protein)
                    .frame(width: 32, height: 32)
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(AppDateFormatter.shortDate.string(from: measurement.date))
                    .font(AppFont.body(15))
                    .foregroundStyle(.primary)

                HStack(spacing: AppSpacing.sm) {
                    Text(String(format: "%.1f kg", measurement.weight))
                        .font(AppFont.caption(13))
                        .foregroundStyle(.secondary)

                    if let muscle = measurement.muscleMass {
                        Text("근육 \(String(format: "%.1f", muscle))")
                            .font(AppFont.caption(12))
                            .foregroundStyle(AppColors.success)
                    }

                    if let fat = measurement.bodyFatPercentage {
                        Text("체지방 \(String(format: "%.1f%%", fat))")
                            .font(AppFont.caption(12))
                            .foregroundStyle(AppColors.warning)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 4)
    }
}

// MARK: - Add Body Measurement Sheet

private struct AddBodyMeasurementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @AppStorage("profileWeight") private var profileWeight: Double = 0
    @AppStorage("profileMuscleMass") private var profileMuscleMass: Double = 0
    @AppStorage("profileBodyFatPercent") private var profileBodyFatPercent: Double = 0
    @AppStorage("profileBMI") private var profileBMI: Double = 0

    @State private var measureDate = Date()
    @State private var weightText = ""
    @State private var muscleMassText = ""
    @State private var bodyFatPercentText = ""

    private var canSave: Bool {
        guard let w = Double(weightText), w.isFinite, (1.0...500.0).contains(w) else {
            return false
        }
        return true
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Date
                dateSection

                // Input fields
                inputSection

                // Import from InBody
                importButton

                // Save button
                Button {
                    saveMeasurement()
                } label: {
                    Text("저장")
                        .font(AppFont.heading(16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .gradientCard(cornerRadius: AppRadius.md)
                }
                .disabled(!canSave)
                .opacity(canSave ? 1.0 : 0.5)
                .padding(.horizontal, AppSpacing.md)

                Spacer(minLength: AppSpacing.xxl)
            }
            .padding(.top, AppSpacing.md)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("기록 추가")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") { dismiss() }
                    .foregroundStyle(AppColors.accent)
            }
        }
    }

    // MARK: - Date Section

    private var dateSection: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .fill(AppColors.protein)
                    .frame(width: 32, height: 32)
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text("측정일")
                .font(AppFont.body(15))
                .foregroundStyle(.primary)

            Spacer()

            DatePicker("", selection: $measureDate, displayedComponents: .date)
                .labelsHidden()
                .tint(AppColors.accent)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 4)
        .glassCard(cornerRadius: AppRadius.xl)
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("체성분 정보")
                .font(AppFont.caption(13))
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppSpacing.md)

            VStack(spacing: 0) {
                MeasurementInputRow(
                    icon: "scalemass.fill",
                    iconColor: AppColors.protein,
                    label: "체중 (kg)",
                    text: $weightText,
                    placeholder: "필수",
                    keyboardType: .decimalPad
                )
                Divider().padding(.leading, 52).opacity(0.4)
                MeasurementInputRow(
                    icon: "figure.strengthtraining.traditional",
                    iconColor: AppColors.success,
                    label: "골격근량 (kg)",
                    text: $muscleMassText,
                    placeholder: "선택",
                    keyboardType: .decimalPad
                )
                Divider().padding(.leading, 52).opacity(0.4)
                MeasurementInputRow(
                    icon: "percent",
                    iconColor: AppColors.warning,
                    label: "체지방률 (%)",
                    text: $bodyFatPercentText,
                    placeholder: "선택",
                    keyboardType: .decimalPad
                )
            }
            .glassCard(cornerRadius: AppRadius.xl)
            .padding(.horizontal, AppSpacing.md)
        }
    }

    // MARK: - Import Button

    private var importButton: some View {
        Button {
            loadFromProfile()
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("InBody 데이터 불러오기")
                    .font(AppFont.heading(15))
            }
            .foregroundStyle(AppColors.accent)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(AppColors.accent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(AppColors.accent, lineWidth: 1)
            )
        }
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Helpers

    private func loadFromProfile() {
        if profileWeight > 0 { weightText = String(format: "%g", profileWeight) }
        if profileMuscleMass > 0 { muscleMassText = String(format: "%g", profileMuscleMass) }
        if profileBodyFatPercent > 0 { bodyFatPercentText = String(format: "%g", profileBodyFatPercent) }
    }

    private func saveMeasurement() {
        guard let weight = Double(weightText), weight.isFinite, (1.0...500.0).contains(weight) else { return }

        let muscleMass: Double? = {
            guard let v = Double(muscleMassText), v.isFinite, (0.1...300.0).contains(v) else { return nil }
            return v
        }()

        let bodyFat: Double? = {
            guard let v = Double(bodyFatPercentText), v.isFinite, (0.1...70.0).contains(v) else { return nil }
            return v
        }()

        let bmi: Double? = {
            guard profileBMI > 0 else { return nil }
            return profileBMI
        }()

        let measurement = BodyMeasurement(
            date: measureDate,
            weight: weight,
            muscleMass: muscleMass,
            bodyFatPercentage: bodyFat,
            bmi: bmi
        )

        modelContext.insert(measurement)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Measurement Input Row

private struct MeasurementInputRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .fill(iconColor)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(label)
                .font(AppFont.body(15))
                .foregroundStyle(.primary)

            Spacer()

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .font(AppFont.body(15))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 4)
    }
}
