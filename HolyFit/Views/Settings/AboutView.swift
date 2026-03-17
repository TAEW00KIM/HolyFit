import SwiftUI

struct AboutView: View {
    @State private var logoAppeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // App logo hero
                logoSection

                // App info card
                infoCard

                Spacer(minLength: AppSpacing.xxl)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxl + AppSpacing.xl)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("앱 정보")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Logo hero section

    private var logoSection: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                // Glow layers
                Circle()
                    .fill(AppColors.gradientStart.opacity(0.2))
                    .frame(width: 130, height: 130)
                    .blur(radius: 20)

                Circle()
                    .fill(AppColors.gradientEnd.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .blur(radius: 12)

                // Icon container with gradient
                ZStack {
                    Circle()
                        .fill(AppColors.primaryGradient)
                        .frame(width: 88, height: 88)
                        .shadow(
                            color: AppColors.gradientStart.opacity(0.45),
                            radius: 20,
                            x: 0,
                            y: 10
                        )

                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .scaleEffect(logoAppeared ? 1.0 : 0.7)
            .opacity(logoAppeared ? 1.0 : 0)

            VStack(spacing: AppSpacing.xs) {
                Text("HolyFit")
                    .font(AppFont.title(30))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.gradientStart, AppColors.gradientEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("헬스루틴 + 식단 관리")
                    .font(AppFont.body(15))
                    .foregroundStyle(.secondary)
            }
            .opacity(logoAppeared ? 1.0 : 0)
            .offset(y: logoAppeared ? 0 : 10)
        }
        .padding(.vertical, AppSpacing.lg)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: AppRadius.xxl)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                logoAppeared = true
            }
        }
    }

    // MARK: - Info card

    private var infoCard: some View {
        VStack(spacing: 0) {
            AboutRow(
                icon: "number.circle.fill",
                iconColor: AppColors.accent,
                label: "버전",
                value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            )

            Divider()
                .padding(.leading, 52)
                .opacity(0.4)

            AboutRow(
                icon: "iphone",
                iconColor: AppColors.success,
                label: "플랫폼",
                value: "iOS 26+"
            )
        }
        .glassCard(cornerRadius: AppRadius.xl)
    }
}

// MARK: - About Row

private struct AboutRow: View {
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
