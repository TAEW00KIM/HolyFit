import SwiftUI

struct MyProfileView: View {
    @AppStorage("profileWeight") private var weight: Double = 0
    @AppStorage("profileHeight") private var height: Double = 0
    @AppStorage("profileAge") private var age: Int = 0
    @AppStorage("profileGender") private var gender: String = "남성"

    @AppStorage("profileMuscleMass") private var muscleMass: Double = 0
    @AppStorage("profileBodyFatPercent") private var bodyFatPercent: Double = 0
    @AppStorage("profileBMI") private var bmi: Double = 0
    @AppStorage("profileBodyFatMass") private var bodyFatMass: Double = 0

    @AppStorage("profileBMR") private var bmr: Double = 0
    @AppStorage("profileTDEE") private var tdee: Double = 0
    @AppStorage("profileMeasureDate") private var measureDateInterval: Double = 0

    @State private var showInBodyInput = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // 기본 정보
                basicInfoSection

                // 인바디 불러오기 버튼
                Button {
                    showInBodyInput = true
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("인바디에서 불러오기")
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

                // 체성분 변화 보기
                NavigationLink(destination: BodyProgressView()) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 16, weight: .semibold))
                        Text("체성분 변화 보기")
                            .font(AppFont.heading(15))
                    }
                    .foregroundStyle(AppColors.protein)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(AppColors.protein.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .strokeBorder(AppColors.protein, lineWidth: 1)
                    )
                }
                .padding(.horizontal, AppSpacing.md)

                // 체성분 정보
                if hasBodyComposition {
                    bodyCompositionSection

                    if measureDateInterval > 0 {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Text("측정일: \(Date(timeIntervalSince1970: measureDateInterval), style: .date)")
                                .font(AppFont.caption(12))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, AppSpacing.md + AppSpacing.xs)
                    }
                }

                // 대사 정보
                if bmr > 0 || tdee > 0 {
                    metabolismSection
                }

                Spacer(minLength: AppSpacing.xxl)
            }
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.xxl + AppSpacing.xl)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("내 정보")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showInBodyInput) {
            NavigationStack {
                InBodyResultView()
            }
        }
    }

    private var hasBodyComposition: Bool {
        muscleMass > 0 || bodyFatPercent > 0 || bmi > 0 || bodyFatMass > 0
    }

    // MARK: - 기본 정보

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionLabel(title: "기본 정보", icon: "person.fill")

            VStack(spacing: 0) {
                ProfileRow(
                    icon: "scalemass.fill",
                    iconColor: AppColors.protein,
                    label: "체중",
                    value: weight > 0 ? String(format: "%.1f kg", weight) : "-"
                )
                Divider().padding(.leading, 52).opacity(0.4)
                ProfileRow(
                    icon: "ruler.fill",
                    iconColor: AppColors.success,
                    label: "키",
                    value: height > 0 ? String(format: "%.0f cm", height) : "-"
                )
                Divider().padding(.leading, 52).opacity(0.4)
                ProfileRow(
                    icon: "calendar",
                    iconColor: AppColors.warning,
                    label: "나이",
                    value: age > 0 ? "\(age)세" : "-"
                )
                Divider().padding(.leading, 52).opacity(0.4)
                ProfileRow(
                    icon: "person.2.fill",
                    iconColor: AppColors.info,
                    label: "성별",
                    value: gender
                )
            }
            .glassCard(cornerRadius: AppRadius.xl)
        }
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - 체성분 정보

    private var bodyCompositionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionLabel(title: "체성분 정보", icon: "figure.stand")

            VStack(spacing: 0) {
                if muscleMass > 0 {
                    ProfileRow(
                        icon: "figure.strengthtraining.traditional",
                        iconColor: AppColors.protein,
                        label: "골격근량",
                        value: String(format: "%.1f kg", muscleMass)
                    )
                    Divider().padding(.leading, 52).opacity(0.4)
                }
                if bodyFatPercent > 0 {
                    ProfileRow(
                        icon: "percent",
                        iconColor: AppColors.warning,
                        label: "체지방률",
                        value: String(format: "%.1f %%", bodyFatPercent)
                    )
                    Divider().padding(.leading, 52).opacity(0.4)
                }
                if bmi > 0 {
                    ProfileRow(
                        icon: "chart.bar.fill",
                        iconColor: AppColors.chartPurple,
                        label: "BMI",
                        value: String(format: "%.1f", bmi)
                    )
                    Divider().padding(.leading, 52).opacity(0.4)
                }
                if bodyFatMass > 0 {
                    ProfileRow(
                        icon: "drop.fill",
                        iconColor: AppColors.carbs,
                        label: "체지방량",
                        value: String(format: "%.1f kg", bodyFatMass)
                    )
                }
            }
            .glassCard(cornerRadius: AppRadius.xl)
        }
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - 대사 정보

    private var metabolismSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionLabel(title: "대사 정보", icon: "flame.fill")

            VStack(spacing: 0) {
                if bmr > 0 {
                    ProfileRow(
                        icon: "bolt.heart.fill",
                        iconColor: AppColors.danger,
                        label: "기초대사량",
                        value: String(format: "%.0f kcal", bmr)
                    )
                }
                if bmr > 0 && tdee > 0 {
                    Divider().padding(.leading, 52).opacity(0.4)
                }
                if tdee > 0 {
                    ProfileRow(
                        icon: "flame.fill",
                        iconColor: AppColors.calories,
                        label: "활동대사량",
                        value: String(format: "%.0f kcal", tdee)
                    )
                }
            }
            .glassCard(cornerRadius: AppRadius.xl)
        }
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Section label

    private func sectionLabel(title: String, icon: String) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppColors.gradientStart)
            Text(title)
                .font(AppFont.caption(12))
                .fontWeight(.semibold)
                .foregroundStyle(Color(.secondaryLabel))
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(.horizontal, AppSpacing.xs)
    }
}

// MARK: - Profile Row

private struct ProfileRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

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

            Text(value)
                .font(AppFont.body(15))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 4)
    }
}
