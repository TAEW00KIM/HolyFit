import SwiftUI

struct MyGymView: View {
    @State private var selectedEquipment: Set<Equipment> = GymEquipmentStore.load()

    private var groupedEquipment: [(EquipmentCategory, [Equipment])] {
        EquipmentCategory.allCases.map { category in
            let items = Equipment.allCases.filter { $0.category == category }
            return (category, items)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Header description
                    headerSection

                    // Category sections
                    ForEach(groupedEquipment, id: \.0) { category, items in
                        categorySection(category: category, items: items)
                    }

                    // Select all / Deselect all
                    bulkActionButtons

                    // Bottom spacer for fixed bar
                    Spacer(minLength: 80)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.lg)
            }

            // Fixed bottom summary bar
            summaryBar
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("내 헬스장")
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: selectedEquipment) { _, newValue in
            GymEquipmentStore.save(newValue)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryGradient)
                    .frame(width: 48, height: 48)
                Image(systemName: "building.2.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("사용 가능한 기구를 선택하세요")
                    .font(AppFont.body(15))
                    .foregroundStyle(.primary)
                Text("선택한 기구에 맞는 운동을 추천받을 수 있어요")
                    .font(AppFont.caption(13))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(AppSpacing.md)
        .glassCard()
    }

    // MARK: - Category Section

    @ViewBuilder
    private func categorySection(category: EquipmentCategory, items: [Equipment]) -> some View {
        let selectedCount = items.filter { selectedEquipment.contains($0) }.count

        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Category header
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: categoryIcon(category))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.gradientStart)
                Text(category.rawValue)
                    .font(AppFont.caption(12))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.secondaryLabel))
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()

                // Count badge — tappable to toggle all in category
                Button {
                    toggleCategory(items: items)
                } label: {
                    Text("\(selectedCount)/\(items.count)")
                        .font(AppFont.caption(12))
                        .fontWeight(.semibold)
                        .foregroundStyle(selectedCount == items.count ? AppColors.accent : .secondary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(
                            Capsule()
                                .fill(selectedCount == items.count
                                      ? AppColors.accent.opacity(0.12)
                                      : Color(.tertiarySystemFill))
                        )
                }
            }
            .padding(.horizontal, AppSpacing.xs)

            // Equipment rows
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element) { index, equipment in
                    equipmentRow(equipment: equipment)

                    if index < items.count - 1 {
                        Divider()
                            .padding(.leading, 52)
                            .opacity(0.4)
                    }
                }
            }
            .glassCard(cornerRadius: AppRadius.xl)
        }
    }

    // MARK: - Equipment Row

    private func equipmentRow(equipment: Equipment) -> some View {
        let isSelected = selectedEquipment.contains(equipment)

        return HStack(spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .fill(isSelected ? AppColors.accent : Color(.tertiarySystemFill))
                    .frame(width: 32, height: 32)
                Image(systemName: equipment.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .secondary)
            }

            Text(equipment.rawValue)
                .font(AppFont.body(15))
                .foregroundStyle(.primary)

            Spacer()

            Toggle("", isOn: Binding(
                get: { selectedEquipment.contains(equipment) },
                set: { newValue in
                    if newValue {
                        selectedEquipment.insert(equipment)
                    } else {
                        selectedEquipment.remove(equipment)
                    }
                }
            ))
            .tint(AppColors.accent)
            .labelsHidden()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 4)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedEquipment.contains(equipment) {
                    selectedEquipment.remove(equipment)
                } else {
                    selectedEquipment.insert(equipment)
                }
            }
        }
    }

    // MARK: - Bulk Actions

    private var bulkActionButtons: some View {
        HStack(spacing: AppSpacing.md) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedEquipment = Set(Equipment.allCases)
                }
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("전체 선택")
                        .font(AppFont.heading(14))
                }
                .foregroundStyle(AppColors.accent)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(AppColors.accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .strokeBorder(AppColors.accent, lineWidth: 1)
                )
            }

            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedEquipment.removeAll()
                }
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("전체 해제")
                        .font(AppFont.heading(14))
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                )
            }
        }
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        HStack {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
                Text("선택된 기구")
                    .font(AppFont.caption(13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(selectedEquipment.count)/\(Equipment.allCases.count)개")
                .font(AppFont.heading(15))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, AppSpacing.md + AppSpacing.xs)
        .padding(.vertical, AppSpacing.md)
        .glassCard(cornerRadius: 0)
    }

    // MARK: - Helpers

    private func toggleCategory(items: [Equipment]) {
        withAnimation(.easeInOut(duration: 0.3)) {
            let allSelected = items.allSatisfy { selectedEquipment.contains($0) }
            if allSelected {
                items.forEach { selectedEquipment.remove($0) }
            } else {
                items.forEach { selectedEquipment.insert($0) }
            }
        }
    }

    private func categoryIcon(_ category: EquipmentCategory) -> String {
        switch category {
        case .freeWeights: return "figure.strengthtraining.traditional"
        case .benches: return "bed.double.fill"
        case .bodyweight: return "figure.climbing"
        case .cableSmith: return "cable.connector"
        case .plateLoaded: return "circle.grid.2x2.fill"
        case .pinLoaded: return "gearshape.fill"
        case .cardio: return "figure.run"
        }
    }
}
