import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [AppColors.gradientStart.opacity(0.05), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            TabView(selection: $currentPage) {
                welcomePage
                    .tag(0)
                featuresPage
                    .tag(1)
                setupPage
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut, value: currentPage)
        }
    }

    // MARK: - Welcome Page

    private var welcomePage: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 80))
                .foregroundStyle(AppColors.primaryGradient)

            Text("HolyFit")
                .font(AppFont.stat(48))
                .foregroundStyle(AppColors.primaryGradient)

            Text("운동과 식단을 한 곳에서")
                .font(AppFont.heading())
                .foregroundStyle(AppColors.textSecondary)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, AppSpacing.xl)
    }

    // MARK: - Features Page

    private var featuresPage: some View {
        VStack(spacing: AppSpacing.xxl) {
            Spacer()

            featureRow(
                icon: "dumbbell.fill",
                title: "운동 기록",
                subtitle: "세트, 무게, 횟수를 간편하게 기록하세요"
            )

            featureRow(
                icon: "fork.knife",
                title: "식단 관리",
                subtitle: "매일 먹은 음식과 영양소를 관리하세요"
            )

            featureRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "통계 분석",
                subtitle: "운동 성과를 한눈에 확인하세요"
            )

            Spacer()
            Spacer()
        }
        .padding(.horizontal, AppSpacing.xl)
    }

    // MARK: - Setup Page

    private var setupPage: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppColors.primaryGradient)

            Text("준비 완료!")
                .font(AppFont.title(32))
                .foregroundStyle(AppColors.textPrimary)

            Text("지금 바로 시작해보세요")
                .font(AppFont.body())
                .foregroundStyle(AppColors.textSecondary)

            Spacer()

            Button {
                hasCompletedOnboarding = true
            } label: {
                Text("시작하기")
                    .font(AppFont.heading())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColors.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            }
            .padding(.bottom, AppSpacing.xxl)
        }
        .padding(.horizontal, AppSpacing.xl)
    }

    // MARK: - Feature Row

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(AppColors.primaryGradient)
                .frame(width: 56, height: 56)
                .background(AppColors.gradientStart.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppFont.heading())
                    .foregroundStyle(AppColors.textPrimary)

                Text(subtitle)
                    .font(AppFont.body(14))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()
        }
    }
}
