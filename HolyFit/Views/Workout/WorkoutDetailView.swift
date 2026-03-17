import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var session: WorkoutSession
    @State private var appeared = false
    @State private var isEditing = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                summaryCard
                    .padding(.horizontal, AppSpacing.md)

                ForEach(session.sortedEntries) { entry in
                    exerciseCard(entry: entry)
                        .padding(.horizontal, AppSpacing.md)
                }

                if !session.notes.isEmpty || isEditing {
                    notesCard
                        .padding(.horizontal, AppSpacing.md)
                }

                Color.clear.frame(height: AppSpacing.lg)
            }
            .padding(.top, AppSpacing.md)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("운동 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if isEditing {
                        try? modelContext.save()
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isEditing.toggle()
                    }
                } label: {
                    Text(isEditing ? "완료" : "편집")
                        .font(AppFont.heading(15))
                        .foregroundStyle(isEditing ? AppColors.success : AppColors.accent)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.05)) {
                appeared = true
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("요약")
                    .font(AppFont.heading(13))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Text(AppDateFormatter.shortDate.string(from: session.startDate))
                    .font(AppFont.caption(13))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: AppSpacing.md) {
                summaryStatBlock(
                    icon: "scalemass.fill",
                    value: String(format: "%.0f", session.totalVolume),
                    unit: "kg",
                    label: "총 볼륨",
                    color: AppColors.accent
                )
                summaryStatBlock(
                    icon: "figure.strengthtraining.traditional",
                    value: "\(session.exerciseCount)",
                    unit: "종목",
                    label: "운동 수",
                    color: AppColors.info
                )
                summaryStatBlock(
                    icon: "repeat",
                    value: "\(session.totalSets)",
                    unit: "세트",
                    label: "총 세트",
                    color: AppColors.success
                )
                if let duration = session.duration {
                    summaryStatBlock(
                        icon: "clock.fill",
                        value: AppDateFormatter.durationString(from: duration),
                        unit: "",
                        label: "소요 시간",
                        color: AppColors.warning
                    )
                }
            }
        }
        .padding(AppSpacing.md)
        .gradientCard(cornerRadius: AppRadius.xxl)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
    }

    private func summaryStatBlock(
        icon: String,
        value: String,
        unit: String,
        label: String,
        color: Color
    ) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(AppFont.heading(17))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if !unit.isEmpty {
                    Text(unit)
                        .font(AppFont.caption(10))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            Text(label)
                .font(AppFont.caption(10))
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }

    // MARK: - Exercise Card

    private func exerciseCard(entry: WorkoutEntry) -> some View {
        let muscleColor = entry.exercise.map { AppColors.muscleGroupColor($0.muscleGroup) } ?? AppColors.accent

        return VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: AppSpacing.sm) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(muscleColor)
                    .frame(width: 4, height: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.exercise?.name ?? "운동")
                        .font(AppFont.heading(15))
                        .lineLimit(1)
                    if let group = entry.exercise?.muscleGroup {
                        Text(group.rawValue)
                            .font(AppFont.caption(11))
                            .foregroundStyle(muscleColor.opacity(0.85))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Volume badge
                VStack(alignment: .trailing, spacing: 1) {
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(String(format: "%.0f", entry.totalVolume))
                            .font(AppFont.heading(15))
                            .foregroundStyle(muscleColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("kg")
                            .font(AppFont.caption(10))
                            .foregroundStyle(.secondary)
                    }
                    Text("볼륨")
                        .font(AppFont.caption(10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.sm)

            // Volume progress bar
            let maxVol = session.sortedEntries.map { $0.totalVolume }.max() ?? 1
            let ratio = maxVol > 0 ? entry.totalVolume / maxVol : 0

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(muscleColor.opacity(0.08))
                        .frame(height: 3)
                    Rectangle()
                        .fill(muscleColor.opacity(0.5))
                        .frame(width: geo.size.width * ratio, height: 3)
                        .clipShape(Capsule())
                }
            }
            .frame(height: 3)
            .padding(.horizontal, AppSpacing.md)

            if isEditing {
                // Column headers for edit mode
                HStack {
                    Text("세트")
                        .frame(width: 32, alignment: .leading)
                    Text("중량 (kg)")
                        .frame(maxWidth: .infinity)
                    Text("횟수 (회)")
                        .frame(maxWidth: .infinity)
                    Text("")
                        .frame(width: 70)
                }
                .font(AppFont.caption(11))
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xs)
            }

            Divider()
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, isEditing ? 0 : AppSpacing.sm)

            // Set rows
            VStack(spacing: 0) {
                ForEach(entry.sortedSets) { set in
                    if isEditing {
                        EditableSetRow(workoutSet: set, accentColor: muscleColor)
                    } else {
                        detailSetRow(set: set, muscleColor: muscleColor)
                    }
                    if set.id != entry.sortedSets.last?.id {
                        Divider()
                            .padding(.leading, AppSpacing.md)
                    }
                }
            }
        }
        .glassCard()
    }

    private func detailSetRow(set: WorkoutSet, muscleColor: Color) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Text("\(set.order + 1)")
                .font(AppFont.mono(13))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .leading)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", set.weight))
                    .font(AppFont.heading(16))
                Text("kg")
                    .font(AppFont.caption(11))
                    .foregroundStyle(.secondary)
            }

            Text("×")
                .font(AppFont.body(14))
                .foregroundStyle(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("\(set.reps)")
                    .font(AppFont.heading(16))
                Text("회")
                    .font(AppFont.caption(11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Volume
            Text(String(format: "%.1f kg", set.volume))
                .font(AppFont.caption(12))
                .foregroundStyle(.secondary)

            // Badges
            HStack(spacing: 4) {
                if set.isTopSet {
                    setTypeBadge(label: "탑", color: AppColors.danger)
                }
                if set.isDropSet {
                    setTypeBadge(label: "드랍", color: AppColors.warning)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 11)
    }

    private func setTypeBadge(label: String, color: Color) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 1))
    }

    // MARK: - Notes Card

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("메모")
                .font(AppFont.heading(13))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            if isEditing {
                TextField("메모 입력", text: $session.notes, axis: .vertical)
                    .font(AppFont.body(15))
                    .lineLimit(5)
            } else {
                Text(session.notes)
                    .font(AppFont.body(15))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .glassCard()
    }
}

// MARK: - Editable Set Row

struct EditableSetRow: View {
    @Bindable var workoutSet: WorkoutSet
    var accentColor: Color = AppColors.accent

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Text("\(workoutSet.order + 1)")
                .font(AppFont.mono(13))
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .leading)

            // Weight
            editableField(
                value: Binding(
                    get: { workoutSet.weight },
                    set: { workoutSet.weight = $0 }
                ),
                step: AppConstants.weightIncrement,
                isDecimal: true
            )

            // Reps
            editableField(
                value: Binding(
                    get: { Double(workoutSet.reps) },
                    set: { workoutSet.reps = Int($0) }
                ),
                step: 1,
                isDecimal: false
            )

            // Badges
            HStack(spacing: 4) {
                badgeToggle(label: "D", isOn: $workoutSet.isDropSet, activeColor: AppColors.warning)
                badgeToggle(label: "T", isOn: $workoutSet.isTopSet, activeColor: AppColors.danger)
            }
            .frame(width: 70)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 10)
    }

    private func editableField(
        value: Binding<Double>,
        step: Double,
        isDecimal: Bool
    ) -> some View {
        HStack(spacing: 0) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                value.wrappedValue = max(0, value.wrappedValue - step)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(accentColor)
                    .frame(width: 30, height: 34)
                    .background(accentColor.opacity(0.08))
            }

            TextField(
                "",
                text: Binding(
                    get: {
                        isDecimal ? String(format: "%.1f", value.wrappedValue) : String(format: "%.0f", value.wrappedValue)
                    },
                    set: { text in
                        if let parsed = Double(text), parsed >= 0 {
                            value.wrappedValue = parsed
                        }
                    }
                )
            )
            .font(AppFont.mono(14))
            .multilineTextAlignment(.center)
            .keyboardType(.decimalPad)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(Color(.systemBackground).opacity(0.5))

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                value.wrappedValue += step
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(accentColor)
                    .frame(width: 30, height: 34)
                    .background(accentColor.opacity(0.08))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .stroke(accentColor.opacity(0.15), lineWidth: 1)
        )
    }

    private func badgeToggle(label: String, isOn: Binding<Bool>, activeColor: Color) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            isOn.wrappedValue.toggle()
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(isOn.wrappedValue ? .white : .secondary)
                .frame(width: 30, height: 26)
                .background(isOn.wrappedValue ? activeColor : Color(.systemGray5))
                .clipShape(Capsule())
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isOn.wrappedValue)
        }
    }
}
