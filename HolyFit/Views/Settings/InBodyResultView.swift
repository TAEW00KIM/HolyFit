import SwiftUI
import SwiftData

struct InBodyResultView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("profileWeight") private var profileWeight: Double = 0
    @AppStorage("profileMuscleMass") private var profileMuscleMass: Double = 0
    @AppStorage("profileBodyFatPercent") private var profileBodyFatPercent: Double = 0
    @AppStorage("profileBMI") private var profileBMI: Double = 0
    @AppStorage("profileBodyFatMass") private var profileBodyFatMass: Double = 0
    @AppStorage("profileBMR") private var profileBMR: Double = 0
    @AppStorage("profileMeasureDate") private var profileMeasureDateInterval: Double = 0

    @State private var measureDate = Date()
    @State private var weightText = ""
    @State private var muscleMassText = ""
    @State private var bodyFatPercentText = ""
    @State private var bmiText = ""
    @State private var bodyFatMassText = ""
    @State private var bmrText = ""

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // 측정일
                dateSection

                // 체성분 2x3 그리드
                bodyStatsGrid

                // 저장 버튼
                Button {
                    saveResults()
                } label: {
                    Text("저장하기")
                        .font(AppFont.heading(16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .gradientCard(cornerRadius: AppRadius.md)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)

                Spacer(minLength: AppSpacing.xxl)
            }
            .padding(.top, AppSpacing.md)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("인바디 결과")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") { dismiss() }
                    .foregroundStyle(AppColors.accent)
            }
        }
        .onAppear {
            loadExistingValues()
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

    // MARK: - Body Stats Grid

    private var bodyStatsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: AppSpacing.sm),
                GridItem(.flexible(), spacing: AppSpacing.sm)
            ],
            spacing: AppSpacing.sm
        ) {
            InBodyStatCard(
                icon: "scalemass.fill",
                iconColor: AppColors.protein,
                label: "체중 (kg)",
                text: $weightText,
                keyboardType: .decimalPad
            )
            InBodyStatCard(
                icon: "figure.strengthtraining.traditional",
                iconColor: AppColors.success,
                label: "골격근량 (kg)",
                text: $muscleMassText,
                keyboardType: .decimalPad
            )
            InBodyStatCard(
                icon: "percent",
                iconColor: AppColors.warning,
                label: "체지방률 (%)",
                text: $bodyFatPercentText,
                keyboardType: .decimalPad
            )
            InBodyStatCard(
                icon: "chart.bar.fill",
                iconColor: AppColors.chartPurple,
                label: "BMI",
                text: $bmiText,
                keyboardType: .decimalPad
            )
            InBodyStatCard(
                icon: "drop.fill",
                iconColor: AppColors.carbs,
                label: "체지방량 (kg)",
                text: $bodyFatMassText,
                keyboardType: .decimalPad
            )
            InBodyStatCard(
                icon: "bolt.heart.fill",
                iconColor: AppColors.danger,
                label: "기초대사량 (kcal)",
                text: $bmrText,
                keyboardType: .numberPad
            )
        }
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Helpers

    private func loadExistingValues() {
        if profileWeight > 0 { weightText = String(format: "%g", profileWeight) }
        if profileMuscleMass > 0 { muscleMassText = String(format: "%g", profileMuscleMass) }
        if profileBodyFatPercent > 0 { bodyFatPercentText = String(format: "%g", profileBodyFatPercent) }
        if profileBMI > 0 { bmiText = String(format: "%g", profileBMI) }
        if profileBodyFatMass > 0 { bodyFatMassText = String(format: "%g", profileBodyFatMass) }
        if profileBMR > 0 { bmrText = String(format: "%g", profileBMR) }
        if profileMeasureDateInterval > 0 {
            measureDate = Date(timeIntervalSince1970: profileMeasureDateInterval)
        }
    }

    private func saveResults() {
        let weight = Double(weightText).flatMap { $0.isFinite && (1.0...500.0).contains($0) ? $0 : nil }
        let muscle = Double(muscleMassText).flatMap { $0.isFinite && (0.1...300.0).contains($0) ? $0 : nil }
        let fatPct = Double(bodyFatPercentText).flatMap { $0.isFinite && (0.1...70.0).contains($0) ? $0 : nil }
        let bmi = Double(bmiText).flatMap { $0.isFinite && (5.0...100.0).contains($0) ? $0 : nil }
        let fatMass = Double(bodyFatMassText).flatMap { $0.isFinite && (0.1...300.0).contains($0) ? $0 : nil }
        let bmr = Double(bmrText).flatMap { $0.isFinite && (100.0...10000.0).contains($0) ? $0 : nil }

        // AppStorage 업데이트 (프로필 화면용)
        if let weight { profileWeight = weight }
        if let muscle { profileMuscleMass = muscle }
        if let fatPct { profileBodyFatPercent = fatPct }
        if let bmi { profileBMI = bmi }
        if let fatMass { profileBodyFatMass = fatMass }
        if let bmr { profileBMR = bmr }
        profileMeasureDateInterval = measureDate.timeIntervalSince1970

        // BodyMeasurement 동기화 (체성분 추이 차트용)
        if let weight {
            let measurement = BodyMeasurement(
                date: measureDate,
                weight: weight,
                muscleMass: muscle,
                bodyFatPercentage: fatPct,
                bmi: bmi
            )
            modelContext.insert(measurement)
            try? modelContext.save()
            WidgetDataManager.updateWidgetData(context: modelContext)
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

// MARK: - InBody Stat Card

private struct InBodyStatCard: View {
    let icon: String
    let iconColor: Color
    let label: String
    @Binding var text: String
    let keyboardType: UIKeyboardType

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(iconColor)
                Text(label)
                    .font(AppFont.caption(11))
                    .foregroundStyle(.secondary)
            }

            TextField("0", text: $text)
                .keyboardType(keyboardType)
                .font(AppFont.stat(28))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .padding(AppSpacing.md)
        .glassCard(cornerRadius: AppRadius.lg)
    }
}
