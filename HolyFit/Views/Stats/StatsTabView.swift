import SwiftUI
import SwiftData

struct StatsTabView: View {
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            if sessions.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: AppSpacing.md) {
                        // 이번 주 요약
                        WeeklySummaryView()
                            .padding(.horizontal, AppSpacing.md)

                        // 차트 네비게이션 카드
                        ChartNavigationSection()
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
        ContentUnavailableView(
            "통계 데이터가 없습니다",
            systemImage: "chart.line.uptrend.xyaxis",
            description: Text("운동을 기록하면 통계를 볼 수 있습니다")
        )
        .navigationTitle("통계")
    }
}

// MARK: - Chart Navigation Cards

private struct ChartNavigationSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("차트")
                .font(AppFont.heading(17))
                .foregroundStyle(.primary)
                .padding(.bottom, 2)

            VStack(spacing: AppSpacing.sm) {
                ChartNavCard(
                    destination: WeightProgressionChart(),
                    title: "중량 추이",
                    subtitle: "운동별 최대 중량 변화",
                    icon: "chart.line.uptrend.xyaxis",
                    colors: [AppColors.gradientStart, AppColors.gradientEnd]
                )
                ChartNavCard(
                    destination: VolumeChart(),
                    title: "볼륨 추이",
                    subtitle: "세션별 총 볼륨 변화",
                    icon: "chart.bar.fill",
                    colors: [Color(hex: "00B894"), Color(hex: "55E6C1")]
                )
                ChartNavCard(
                    destination: OneRepMaxChart(),
                    title: "1RM 추정",
                    subtitle: "최대 1회 반복 중량 추이",
                    icon: "trophy.fill",
                    colors: [AppColors.gradientStart, AppColors.gradientEnd]
                )
                ChartNavCard(
                    destination: BodyProgressView(),
                    title: "체성분 추이",
                    subtitle: "체중, 근육량, 체지방 변화",
                    icon: "figure.arms.open",
                    colors: [AppColors.protein, AppColors.info]
                )
            }
        }
    }
}

private struct ChartNavCard<Dest: View>: View {
    let destination: Dest
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(
                            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: colors.first?.opacity(0.35) ?? .clear, radius: 6, x: 0, y: 3)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(AppFont.heading(16))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(AppFont.caption(12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(AppSpacing.md)
            .glassCard(cornerRadius: AppRadius.xl)
        }
        .buttonStyle(.plain)
    }
}

