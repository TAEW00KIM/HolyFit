import SwiftUI
import SwiftData

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showResetAlert = false
    @State private var showConfirmAlert = false
    @State private var isDeleting = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Warning banner
                warningCard

                // Destructive action card
                actionCard

                Spacer(minLength: AppSpacing.xxl)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxl + AppSpacing.xl)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("데이터 관리")
        .navigationBarTitleDisplayMode(.inline)
        // First confirmation
        .alert("데이터를 초기화하시겠습니까?", isPresented: $showResetAlert) {
            Button("취소", role: .cancel) { }
            Button("초기화", role: .destructive) {
                showConfirmAlert = true
            }
        } message: {
            Text("모든 운동 기록, 식단 기록, 루틴 템플릿, 체성분 기록이 삭제됩니다.")
        }
        // Second confirmation
        .alert("정말 삭제하시겠습니까?", isPresented: $showConfirmAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("이 작업은 되돌릴 수 없습니다.")
        }
        // Error alert
        .alert("오류", isPresented: $showErrorAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(resetErrorMessage)
        }
    }

    // MARK: - Warning card

    private var warningCard: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.danger.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.danger)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("주의")
                    .font(AppFont.heading(15))
                    .foregroundStyle(AppColors.danger)
                Text("아래 작업은 되돌릴 수 없습니다. 모든 운동 기록, 식단 기록, 루틴 템플릿, 체성분 기록이 영구적으로 삭제됩니다.")
                    .font(AppFont.body(14))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.danger.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(AppColors.danger.opacity(0.09), lineWidth: 0.5)
        )
    }

    // MARK: - Action card

    private var actionCard: some View {
        VStack(spacing: 0) {
            // Row content
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .fill(AppColors.danger)
                        .frame(width: 32, height: 32)
                    Image(systemName: "trash.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("모든 데이터 초기화")
                        .font(AppFont.body(15))
                        .foregroundStyle(AppColors.danger)
                    Text("운동 · 식단 · 템플릿 · 체성분 기록 삭제")
                        .font(AppFont.caption(12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(AppSpacing.md)

            Divider()
                .padding(.horizontal, AppSpacing.md)

            // Gradient delete button
            Button {
                showResetAlert = true
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    if isDeleting {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: "trash")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text(isDeleting ? "삭제 중..." : "데이터 초기화")
                        .font(AppFont.body(15))
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm + 4)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "C04E48"), Color(hex: "B8453F")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                .shadow(color: AppColors.danger.opacity(0.35), radius: 10, x: 0, y: 5)
            }
            .disabled(isDeleting)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.md)
        }
        .glassCard(cornerRadius: AppRadius.xl)
    }

    // MARK: - Data reset

    @State private var showErrorAlert = false
    @State private var resetErrorMessage = ""

    private func resetAllData() {
        isDeleting = true
        do {
            try modelContext.delete(model: WorkoutSession.self)
            try modelContext.delete(model: MealEntry.self)
            try modelContext.delete(model: WorkoutTemplate.self)
            try modelContext.delete(model: BodyMeasurement.self)
            try modelContext.save()
            // Clear widget shared data
            WidgetDataManager.updateWidgetData(context: modelContext)
        } catch {
            resetErrorMessage = "데이터 초기화에 실패했습니다: \(error.localizedDescription)"
            showErrorAlert = true
        }
        withAnimation {
            isDeleting = false
        }
    }
}
