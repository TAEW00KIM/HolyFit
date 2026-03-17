import SwiftUI
import SwiftData

struct RoutineGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var allExercises: [Exercise]

    @State private var selectedGoal: WorkoutGoal?
    @State private var selectedDuration: WorkoutDuration = .medium
    @State private var generatedRoutine: GeneratedRoutine?
    @State private var availableEquipment: Set<Equipment> = GymEquipmentStore.load()

    let onStartWorkout: (BuiltInTemplate) -> Void

    private func reloadEquipment() {
        availableEquipment = GymEquipmentStore.load()
    }

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.sm),
        GridItem(.flexible(), spacing: AppSpacing.sm),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    if !GymEquipmentStore.hasSetUp {
                        gymSetupPrompt
                    }
                    goalSection
                    durationSection
                    generateButton
                    if let routine = generatedRoutine, !routine.exercises.isEmpty {
                        routineResultSection(routine)
                        actionButtons(routine)
                    } else if let routine = generatedRoutine, routine.exercises.isEmpty {
                        VStack(spacing: AppSpacing.md) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundStyle(AppColors.warning)
                            Text("선택된 기구로 수행할 수 있는 운동이 없습니다")
                                .font(AppFont.heading(15))
                                .multilineTextAlignment(.center)
                            Text("설정 → 내 헬스장에서 기구를 추가해보세요")
                                .font(AppFont.caption(13))
                                .foregroundStyle(.secondary)
                        }
                        .padding(AppSpacing.lg)
                        .frame(maxWidth: .infinity)
                        .glassCard()
                    }
                }
                .padding(AppSpacing.md)
                .padding(.bottom, AppSpacing.lg)
            }
            .background(Color(.systemGroupedBackground))
            .onAppear { reloadEquipment() }
            .navigationTitle("루틴 생성")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                    .font(AppFont.body(15))
                }
            }
        }
    }

    // MARK: - Gym Setup Prompt

    @State private var showGymSetup = false

    private var gymSetupPrompt: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColors.warning)
                VStack(alignment: .leading, spacing: 2) {
                    Text("헬스장 기구를 먼저 등록해주세요")
                        .font(AppFont.heading(15))
                    Text("등록된 기구를 기반으로 루틴을 생성합니다")
                        .font(AppFont.caption(12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            NavigationLink(destination: MyGymView()) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("내 헬스장 기구 등록하기")
                        .font(AppFont.heading(14))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background(AppColors.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            }
        }
        .padding(AppSpacing.md)
        .glassCard()
    }

    // MARK: - Goal Selection

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("어떤 운동을 할까요?")
                .font(AppFont.heading(18))

            LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
                ForEach(WorkoutGoal.allCases) { goal in
                    goalCard(goal)
                }
            }
        }
    }

    private func goalCard(_ goal: WorkoutGoal) -> some View {
        let isSelected = selectedGoal == goal
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedGoal = goal
                generatedRoutine = nil
            }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: goal.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? AppColors.accent : .secondary)
                    .frame(width: 28)

                Text(goal.rawValue)
                    .font(AppFont.caption(13))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(isSelected ? AppColors.accent.opacity(0.08) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(
                        isSelected ? AppColors.accent : Color.primary.opacity(0.1),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .glassCard(cornerRadius: AppRadius.md)
    }

    // MARK: - Duration Selection

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("운동 시간")
                .font(AppFont.heading(18))

            HStack(spacing: AppSpacing.sm) {
                ForEach(WorkoutDuration.allCases) { duration in
                    durationPill(duration)
                }
            }
        }
    }

    private func durationPill(_ duration: WorkoutDuration) -> some View {
        let isSelected = selectedDuration == duration
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDuration = duration
                generatedRoutine = nil
            }
        } label: {
            Text(duration.rawValue)
                .font(AppFont.caption(14))
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    isSelected
                        ? AnyShapeStyle(AppColors.primaryGradient)
                        : AnyShapeStyle(Color(.systemFill))
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            generateRoutine()
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "dice.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("루틴 생성하기")
                    .font(AppFont.heading(17))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                selectedGoal != nil
                    ? AnyShapeStyle(AppColors.primaryGradient)
                    : AnyShapeStyle(Color(.systemGray3))
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .shadow(
                color: selectedGoal != nil ? AppColors.gradientStart.opacity(0.3) : .clear,
                radius: 12, x: 0, y: 6
            )
        }
        .disabled(selectedGoal == nil)
        .buttonStyle(.plain)
    }

    // MARK: - Result Section

    private func routineResultSection(_ routine: GeneratedRoutine) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("생성된 루틴")
                    .font(AppFont.heading(18))
                Spacer()
                Text("\(routine.exercises.count)종목")
                    .font(AppFont.caption(13))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                ForEach(Array(routine.exercises.enumerated()), id: \.offset) { index, item in
                    exerciseRow(index: index, item: item)

                    if index < routine.exercises.count - 1 {
                        Divider()
                            .padding(.leading, AppSpacing.xl)
                    }
                }
            }
            .glassCard()
        }
    }

    private func exerciseRow(index: Int, item: (exerciseName: String, sets: Int, reps: Int)) -> some View {
        let exercise = allExercises.first { $0.name == item.exerciseName }
        let muscleColor = exercise.map { AppColors.muscleGroupColor($0.muscleGroup) } ?? AppColors.accent

        return HStack(spacing: AppSpacing.md) {
            // Number
            Text("\(index + 1)")
                .font(AppFont.mono(13))
                .foregroundStyle(.secondary)
                .frame(width: 20, alignment: .center)

            // Muscle group dot
            Circle()
                .fill(muscleColor)
                .frame(width: 8, height: 8)

            // Exercise name
            VStack(alignment: .leading, spacing: 2) {
                Text(item.exerciseName)
                    .font(AppFont.body(15))
                    .lineLimit(1)
                if let group = exercise?.muscleGroup {
                    Text(group.rawValue)
                        .font(AppFont.caption(11))
                        .foregroundStyle(muscleColor.opacity(0.8))
                }
            }

            Spacer()

            // Sets x Reps
            Text("\(item.sets) x \(item.reps)")
                .font(AppFont.mono(14))
                .foregroundStyle(AppColors.accent)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - Action Buttons

    private func actionButtons(_ routine: GeneratedRoutine) -> some View {
        HStack(spacing: AppSpacing.md) {
            // Regenerate
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                generateRoutine()
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                    Text("다시 생성")
                        .font(AppFont.heading(15))
                }
                .foregroundStyle(AppColors.accent)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(AppColors.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .strokeBorder(AppColors.accent.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Start workout
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                let template = BuiltInTemplate(
                    name: routine.name,
                    exercises: routine.exercises
                )
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onStartWorkout(template)
                }
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("이 루틴으로 시작")
                        .font(AppFont.heading(15))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(AppColors.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                .shadow(color: AppColors.gradientStart.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func generateRoutine() {
        guard let goal = selectedGoal else { return }
        generatedRoutine = RoutineGenerator.generate(
            goal: goal,
            duration: selectedDuration,
            availableEquipment: availableEquipment,
            allExercises: allExercises
        )
    }
}
