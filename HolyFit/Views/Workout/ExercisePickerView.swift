import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup?
    @State private var selectedSubgroup: String?
    @State private var showAddExercise = false
    @State private var chipsAppeared = false

    let onSelect: (Exercise) -> Void

    private var availableSubgroups: [String] {
        guard let group = selectedMuscleGroup else { return [] }
        let subgroups = exercises
            .filter { $0.muscleGroup == group }
            .compactMap { $0.muscleSubgroup }
        var seen = Set<String>()
        return subgroups.filter { seen.insert($0).inserted }.sorted()
    }

    private var filteredExercises: [Exercise] {
        var result = exercises
        if let group = selectedMuscleGroup {
            result = result.filter { $0.muscleGroup == group }
        }
        if let subgroup = selectedSubgroup {
            result = result.filter { $0.muscleSubgroup == subgroup }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Muscle group filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        MuscleFilterChip(
                            title: "전체",
                            color: AppColors.accent,
                            isSelected: selectedMuscleGroup == nil
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedMuscleGroup = nil
                            }
                        }

                        ForEach(Array(MuscleGroup.allCases.enumerated()), id: \.element.id) { idx, group in
                            MuscleFilterChip(
                                title: group.rawValue,
                                icon: group.icon,
                                color: AppColors.muscleGroupColor(group),
                                isSelected: selectedMuscleGroup == group
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if selectedMuscleGroup == group {
                                        selectedMuscleGroup = nil
                                    } else {
                                        selectedMuscleGroup = group
                                    }
                                    selectedSubgroup = nil
                                }
                            }
                            .opacity(chipsAppeared ? 1 : 0)
                            .offset(y: chipsAppeared ? 0 : 8)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.75)
                                    .delay(Double(idx) * 0.04),
                                value: chipsAppeared
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                }
                .background(Color(.systemGroupedBackground))

                // Subgroup filter chips (2nd row)
                if !availableSubgroups.isEmpty, let group = selectedMuscleGroup {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.sm) {
                            MuscleFilterChip(
                                title: "전체",
                                color: AppColors.muscleGroupColor(group),
                                isSelected: selectedSubgroup == nil
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedSubgroup = nil
                                }
                            }
                            ForEach(availableSubgroups, id: \.self) { subgroup in
                                MuscleFilterChip(
                                    title: subgroup,
                                    color: AppColors.muscleGroupColor(group),
                                    isSelected: selectedSubgroup == subgroup
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedSubgroup = selectedSubgroup == subgroup ? nil : subgroup
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                    }
                    .background(Color(.systemGroupedBackground))
                }

                Divider()

                // Exercise list
                if filteredExercises.isEmpty {
                    emptyState
                } else {
                    List(filteredExercises) { exercise in
                        ExerciseListRow(exercise: exercise) {
                            onSelect(exercise)
                            dismiss()
                        }
                        .listRowInsets(EdgeInsets(
                            top: AppSpacing.xs,
                            leading: AppSpacing.md,
                            bottom: AppSpacing.xs,
                            trailing: AppSpacing.md
                        ))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .searchable(text: $searchText, prompt: "운동 검색")
            .navigationTitle("운동 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                        .font(AppFont.body(15))
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddExercise = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(AppColors.primaryGradient)
                    }
                }
            }
            .sheet(isPresented: $showAddExercise) {
                AddExerciseView()
            }
            .onAppear {
                withAnimation {
                    chipsAppeared = true
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.secondary)
            Text("운동을 찾을 수 없습니다")
                .font(AppFont.heading(17))
            Text("검색어 또는 필터를 변경해보세요")
                .font(AppFont.body(14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - MuscleFilterChip

struct MuscleFilterChip: View {
    let title: String
    var icon: String? = nil
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title)
                    .font(AppFont.caption(13))
            }
            .foregroundStyle(isSelected ? .white : color)
            .padding(.horizontal, AppSpacing.sm + 4)
            .padding(.vertical, 7)
            .background(
                isSelected
                    ? AnyShapeStyle(color)
                    : AnyShapeStyle(color.opacity(0.12))
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ExerciseListRow

struct ExerciseListRow: View {
    let exercise: Exercise
    let onTap: () -> Void

    private var muscleColor: Color {
        AppColors.muscleGroupColor(exercise.muscleGroup)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.sm) {
                // Left accent bar
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(muscleColor)
                    .frame(width: 4, height: 40)

                // Exercise info
                VStack(alignment: .leading, spacing: 3) {
                    Text(exercise.name)
                        .font(AppFont.heading(15))
                        .foregroundStyle(.primary)
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: exercise.muscleGroup.icon)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(muscleColor)
                        Text(exercise.muscleGroup.rawValue)
                            .font(AppFont.caption(12))
                            .foregroundStyle(muscleColor.opacity(0.85))
                        if let subgroup = exercise.muscleSubgroup {
                            Text(subgroup)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(muscleColor)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(muscleColor.opacity(0.12))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(muscleColor.opacity(0.25), lineWidth: 1))
                        }
                    }
                }

                Spacer()

                if exercise.isCustom {
                    Text("커스텀")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.info)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(AppColors.info.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppColors.info.opacity(0.25), lineWidth: 1))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .glassCard()
        }
        .buttonStyle(.plain)
    }
}

// Keep legacy FilterChip for any other callers
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        MuscleFilterChip(
            title: title,
            color: AppColors.accent,
            isSelected: isSelected,
            action: action
        )
    }
}
