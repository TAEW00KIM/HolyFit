import SwiftUI
import SwiftData

struct WorkoutCompletionView: View {
    let session: WorkoutSession
    let onDismiss: () -> Void

    @State private var appeared = false

    private var volumeText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: session.totalVolume)) ?? "0"
    }

    private var durationText: String {
        guard let duration = session.duration else { return "0분" }
        return AppDateFormatter.durationString(from: duration)
    }

    private var exerciseVolumes: [(name: String, volume: String)] {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return session.sortedEntries.compactMap { entry in
            guard let exercise = entry.exercise else { return nil }
            let vol = formatter.string(from: NSNumber(value: entry.totalVolume)) ?? "0"
            return (name: exercise.name, volume: vol)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                Spacer()
                    .frame(height: AppSpacing.xxl)

                // Confetti emoji
                Text("\u{1F389}")
                    .font(.system(size: 64))

                // Title
                Text("운동 완료!")
                    .font(AppFont.title(28))
                    .foregroundStyle(AppColors.primaryGradient)

                // Summary stats card
                VStack(spacing: AppSpacing.md) {
                    statRow(label: "총 볼륨", value: "\(volumeText) kg")
                    Divider()
                    statRow(label: "운동 수", value: "\(session.exerciseCount) 종목")
                    Divider()
                    statRow(label: "총 세트", value: "\(session.totalSets) 세트")
                    Divider()
                    statRow(label: "소요 시간", value: durationText)
                }
                .padding(AppSpacing.md)
                .glassCard()
                .padding(.horizontal, AppSpacing.md)

                // Exercise breakdown card
                if !exerciseVolumes.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("종목별 볼륨 요약")
                            .font(AppFont.heading(15))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, AppSpacing.xs)

                        VStack(spacing: 0) {
                            ForEach(Array(exerciseVolumes.enumerated()), id: \.offset) { index, item in
                                HStack {
                                    Text(item.name)
                                        .font(AppFont.body(15))
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(item.volume) kg")
                                        .font(AppFont.heading(15))
                                        .foregroundStyle(AppColors.accent)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.sm)

                                if index < exerciseVolumes.count - 1 {
                                    Divider()
                                        .padding(.leading, AppSpacing.md)
                                }
                            }
                        }
                    }
                    .padding(AppSpacing.md)
                    .glassCard()
                    .padding(.horizontal, AppSpacing.md)
                }

                Spacer()
                    .frame(height: AppSpacing.lg)

                // Confirm button
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onDismiss()
                } label: {
                    Text("확인")
                        .font(AppFont.heading(17))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppColors.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                        .shadow(color: AppColors.gradientStart.opacity(0.4), radius: 16, x: 0, y: 8)
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
                    .frame(height: AppSpacing.xl)
            }
        }
        .background(Color(.systemGroupedBackground))
        .scaleEffect(appeared ? 1.0 : 0.9)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppFont.body(15))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(AppFont.heading(17))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}
