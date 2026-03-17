import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var muscleGroup: MuscleGroup = .chest
    @State private var instructions = ""
    @State private var appeared = false

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Name field card
                    nameCard
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)

                    // Muscle group picker
                    muscleGroupCard
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)

                    // Notes field card
                    notesCard
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)

                    // Save button
                    saveButton
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxl + AppSpacing.xl)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("운동 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                        .font(AppFont.body(15))
                        .foregroundStyle(.secondary)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.78).delay(0.05)) {
                    appeared = true
                }
            }
        }
    }

    // MARK: - Name card

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardSectionHeader(title: "운동 이름", icon: "pencil.line", color: AppColors.accent)

            HStack(spacing: AppSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .fill(AppColors.accent.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "text.cursor")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.accent)
                }

                TextField("예: 벤치프레스", text: $name)
                    .font(AppFont.body(16))
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.md)
        }
        .glassCard(cornerRadius: AppRadius.xl)
    }

    // MARK: - Muscle group card

    private var muscleGroupCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            cardSectionHeader(title: "근육 부위", icon: "figure.arms.open", color: AppColors.info)

            // Colored chip grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 3),
                spacing: AppSpacing.sm
            ) {
                ForEach(MuscleGroup.allCases) { group in
                    MuscleChip(group: group, isSelected: muscleGroup == group) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            muscleGroup = group
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.md)
        }
        .glassCard(cornerRadius: AppRadius.xl)
    }

    // MARK: - Notes card

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardSectionHeader(title: "설명 (선택사항)", icon: "note.text", color: AppColors.warning)

            HStack(alignment: .top, spacing: AppSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .fill(AppColors.warning.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "note.text")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.warning)
                }
                .padding(.top, 2)

                TextField("운동 방법, 주의사항 등...", text: $instructions, axis: .vertical)
                    .font(AppFont.body(15))
                    .lineLimit(4...6)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.md)
        }
        .glassCard(cornerRadius: AppRadius.xl)
    }

    // MARK: - Save button

    private var saveButton: some View {
        Button {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let exercise = Exercise(
                name: trimmedName,
                muscleGroup: muscleGroup,
                instructions: instructions.trimmingCharacters(in: .whitespacesAndNewlines),
                isCustom: true
            )
            modelContext.insert(exercise)
            do {
                try modelContext.save()
            } catch {
                return
            }
            dismiss()
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold))
                Text("운동 저장")
                    .font(AppFont.body(16))
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                Group {
                    if isValid {
                        AnyView(AppColors.primaryGradient)
                    } else {
                        AnyView(Color(.systemFill))
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
            .shadow(
                color: isValid ? AppColors.gradientStart.opacity(0.4) : .clear,
                radius: 14,
                x: 0,
                y: 7
            )
        }
        .disabled(!isValid)
        .animation(.easeInOut(duration: 0.2), value: isValid)
    }

    // MARK: - Card section header

    private func cardSectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
            Text(title)
                .font(AppFont.caption(12))
                .fontWeight(.semibold)
                .foregroundStyle(Color(.secondaryLabel))
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.sm)
    }
}

// MARK: - Muscle Chip

private struct MuscleChip: View {
    let group: MuscleGroup
    let isSelected: Bool
    let action: () -> Void

    private var groupColor: Color {
        AppColors.muscleGroupColor(group)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.xs) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? groupColor
                                : groupColor.opacity(0.15)
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: group.icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(isSelected ? .white : groupColor)
                }

                Text(group.rawValue)
                    .font(AppFont.caption(11))
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? groupColor : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(
                        isSelected
                            ? groupColor.opacity(0.12)
                            : Color(.secondarySystemFill).opacity(0.5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .strokeBorder(
                                isSelected ? groupColor.opacity(0.4) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
