import SwiftUI
import SwiftData

struct WorkoutCompletionView: View {
    let session: WorkoutSession
    let onDismiss: () -> Void

    @State private var appeared = false
    @AppStorage("rpeMode") private var rpeMode: String = "off"

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
                    .scaleEffect(appeared ? 1.0 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.1), value: appeared)

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

                // Per-entry RPE picker
                if rpeMode == "session" {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("종목별 운동 강도 (RPE)")
                            .font(AppFont.heading(15))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, AppSpacing.xs)

                        VStack(spacing: 0) {
                            ForEach(Array(session.sortedEntries.enumerated()), id: \.offset) { index, entry in
                                if let exercise = entry.exercise {
                                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                        HStack {
                                            Text(exercise.name)
                                                .font(AppFont.body(14))
                                                .foregroundStyle(.primary)
                                            Spacer()
                                            if let rpe = entry.rpe {
                                                Text(rpeLabel(Int(rpe)))
                                                    .font(AppFont.caption(12))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        HStack(spacing: 4) {
                                            ForEach(1...10, id: \.self) { v in
                                                Button {
                                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.75)) {
                                                        entry.rpe = entry.rpe == Double(v) ? nil : Double(v)
                                                    }
                                                } label: {
                                                    Text("\(v)")
                                                        .font(AppFont.mono(12))
                                                        .fontWeight(.semibold)
                                                        .frame(width: 28, height: 28)
                                                        .background(entry.rpe == Double(v) ? AppColors.accent : Color(.systemFill))
                                                        .foregroundStyle(entry.rpe == Double(v) ? .white : .primary)
                                                        .clipShape(Circle())
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, AppSpacing.md)
                                    .padding(.vertical, AppSpacing.sm)

                                    if index < session.sortedEntries.count - 1 {
                                        Divider().padding(.leading, AppSpacing.md)
                                    }
                                }
                            }
                        }
                        .glassCard()
                    }
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
        .sensoryFeedback(.success, trigger: appeared)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }

    private func rpeLabel(_ rpe: Int) -> String {
        switch rpe {
        case 10: return "한계"
        case 9: return "매우 힘듦"
        case 8: return "힘듦"
        case 7: return "약간 힘듦"
        case 5, 6: return "보통"
        default: return "쉬움"
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
