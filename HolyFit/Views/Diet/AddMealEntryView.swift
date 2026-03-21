import SwiftUI
import SwiftData

struct AddMealEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let date: Date
    let entryToEdit: MealEntry?

    @State private var category: MealCategory
    @State private var foodName = ""
    @State private var caloriesText = ""
    @State private var proteinText = ""
    @State private var carbsText = ""
    @State private var fatText = ""
    @State private var memo = ""
    @State private var recentFoods: [MealEntry] = []
    @FocusState private var focusedField: Field?

    fileprivate enum Field: Hashable {
        case name, calories, protein, carbs, fat, memo
    }

    private var isEditMode: Bool { entryToEdit != nil }

    private var canSave: Bool {
        !foodName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(date: Date, category: MealCategory, entryToEdit: MealEntry? = nil) {
        self.date = date
        self.entryToEdit = entryToEdit
        if let entry = entryToEdit {
            _category = State(initialValue: entry.category)
            _foodName = State(initialValue: entry.foodName)
            _caloriesText = State(initialValue: entry.calories.map(String.init) ?? "")
            _proteinText = State(initialValue: entry.protein.map { String(format: "%g", $0) } ?? "")
            _carbsText = State(initialValue: entry.carbs.map { String(format: "%g", $0) } ?? "")
            _fatText = State(initialValue: entry.fat.map { String(format: "%g", $0) } ?? "")
            _memo = State(initialValue: entry.memo)
        } else {
            _category = State(initialValue: category)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    // 카테고리 선택 (horizontal pills)
                    CategorySelectorSection(selected: $category)

                    // 최근 음식
                    if !recentFoods.isEmpty {
                        RecentFoodsSection(
                            recentFoods: recentFoods,
                            foodName: $foodName,
                            caloriesText: $caloriesText,
                            proteinText: $proteinText,
                            carbsText: $carbsText,
                            fatText: $fatText
                        )
                    }

                    // 음식 이름
                    FoodNameSection(foodName: $foodName, focusedField: $focusedField)

                    // 영양 정보
                    NutritionInputSection(
                        caloriesText: $caloriesText,
                        proteinText: $proteinText,
                        carbsText: $carbsText,
                        fatText: $fatText,
                        focusedField: $focusedField
                    )

                    // 메모
                    MemoSection(memo: $memo, focusedField: $focusedField)

                    // 저장 버튼
                    Button {
                        saveMeal()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text(isEditMode ? "수정하기" : "저장하기")
                                .font(AppFont.heading(17))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .gradientCard(cornerRadius: 14)
                    }
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.5)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)

                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.top, AppSpacing.md)
            }
            .background(Color(.systemGroupedBackground))
            .onAppear { loadRecentFoods() }
            .navigationTitle(isEditMode ? "식단 수정" : "식단 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                        .foregroundStyle(AppColors.accent)
                }
                ToolbarItem(placement: .keyboard) {
                    Button("완료") { focusedField = nil }
                }
            }
        }
    }

    private func saveMeal() {
        let validCalories = Int(caloriesText).flatMap { (0...10000).contains($0) ? $0 : nil }
        let validProtein = Double(proteinText).flatMap { $0.isFinite && (0...1000).contains($0) ? $0 : nil }
        let validCarbs = Double(carbsText).flatMap { $0.isFinite && (0...1000).contains($0) ? $0 : nil }
        let validFat = Double(fatText).flatMap { $0.isFinite && (0...1000).contains($0) ? $0 : nil }

        if let entry = entryToEdit {
            entry.category = category
            entry.foodName = foodName.trimmingCharacters(in: .whitespaces)
            entry.calories = validCalories
            entry.protein = validProtein
            entry.carbs = validCarbs
            entry.fat = validFat
            entry.memo = memo
        } else {
            let entry = MealEntry(
                date: date,
                category: category,
                foodName: foodName.trimmingCharacters(in: .whitespaces),
                calories: validCalories,
                protein: validProtein,
                carbs: validCarbs,
                fat: validFat,
                memo: memo
            )
            modelContext.insert(entry)
        }
        do {
            try modelContext.save()
        } catch {
            return
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        WidgetDataManager.updateWidgetData(context: modelContext)
        dismiss()
    }

    private func loadRecentFoods() {
        var descriptor = FetchDescriptor<MealEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 50

        let entries = (try? modelContext.fetch(descriptor)) ?? []
        var seen = Set<String>()
        var unique: [MealEntry] = []
        for entry in entries {
            let name = entry.foodName.trimmingCharacters(in: .whitespaces)
            if !name.isEmpty && seen.insert(name).inserted {
                unique.append(entry)
            }
            if unique.count >= 10 { break }
        }
        recentFoods = unique
    }
}

// MARK: - Category Selector

private struct CategorySelectorSection: View {
    @Binding var selected: MealCategory

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("분류")
                .font(AppFont.caption(13))
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppSpacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(MealCategory.allCases) { cat in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                selected = cat
                            }
                        } label: {
                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 14, weight: .semibold))
                                Text(cat.rawValue)
                                    .font(AppFont.caption(14))
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(selected == cat ? .white : cat.color)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm + 2)
                            .background(
                                Group {
                                    if selected == cat {
                                        cat.color
                                    } else {
                                        cat.color.opacity(0.12)
                                    }
                                }
                            )
                            .clipShape(Capsule())
                            .shadow(
                                color: selected == cat ? cat.color.opacity(0.35) : .clear,
                                radius: 6, x: 0, y: 3
                            )
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: selected)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
    }
}

// MARK: - Recent Foods Section

private struct RecentFoodsSection: View {
    let recentFoods: [MealEntry]
    @Binding var foodName: String
    @Binding var caloriesText: String
    @Binding var proteinText: String
    @Binding var carbsText: String
    @Binding var fatText: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("최근 음식")
                .font(AppFont.caption(13))
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppSpacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(recentFoods, id: \.id) { entry in
                        Button {
                            fillFields(from: entry)
                        } label: {
                            VStack(spacing: 2) {
                                Text(entry.foodName)
                                    .font(AppFont.caption(13))
                                    .fontWeight(.semibold)
                                    .lineLimit(1)

                                if let cal = entry.calories {
                                    Text("\(cal)kcal")
                                        .font(AppFont.caption(11))
                                        .opacity(0.8)
                                }
                            }
                            .foregroundStyle(
                                foodName == entry.foodName ? .white : .primary
                            )
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                foodName == entry.foodName
                                    ? AnyShapeStyle(AppColors.accent)
                                    : AnyShapeStyle(Color(.systemFill))
                            )
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
    }

    private func fillFields(from entry: MealEntry) {
        foodName = entry.foodName
        caloriesText = entry.calories.map(String.init) ?? ""
        proteinText = entry.protein.map { String(format: "%g", $0) } ?? ""
        carbsText = entry.carbs.map { String(format: "%g", $0) } ?? ""
        fatText = entry.fat.map { String(format: "%g", $0) } ?? ""
    }
}

// MARK: - Food Name Section

private struct FoodNameSection: View {
    @Binding var foodName: String
    var focusedField: FocusState<AddMealEntryView.Field?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("음식 이름")
                .font(AppFont.caption(13))
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppSpacing.md)

            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 20)

                TextField("음식 이름 입력", text: $foodName)
                    .font(AppFont.body(16))
                    .focused(focusedField, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { focusedField.wrappedValue = .calories }
            }
            .padding(AppSpacing.md)
            .glassCard(cornerRadius: AppRadius.lg)
            .padding(.horizontal, AppSpacing.md)
        }
    }
}

// MARK: - Nutrition Input Section

private struct NutritionInputSection: View {
    @Binding var caloriesText: String
    @Binding var proteinText: String
    @Binding var carbsText: String
    @Binding var fatText: String
    var focusedField: FocusState<AddMealEntryView.Field?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("영양 정보 (선택)")
                .font(AppFont.caption(13))
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppSpacing.md)

            VStack(spacing: 0) {
                NutritionInputRow(
                    icon: "flame.fill",
                    label: "칼로리",
                    text: $caloriesText,
                    unit: "kcal",
                    color: AppColors.calories,
                    keyboardType: .numberPad,
                    focusedField: focusedField,
                    fieldTag: .calories,
                    isLast: false
                )
                Divider().padding(.leading, 52).opacity(0.4)
                NutritionInputRow(
                    icon: "bolt.fill",
                    label: "단백질",
                    text: $proteinText,
                    unit: "g",
                    color: AppColors.protein,
                    keyboardType: .decimalPad,
                    focusedField: focusedField,
                    fieldTag: .protein,
                    isLast: false
                )
                Divider().padding(.leading, 52).opacity(0.4)
                NutritionInputRow(
                    icon: "leaf.fill",
                    label: "탄수화물",
                    text: $carbsText,
                    unit: "g",
                    color: AppColors.carbs,
                    keyboardType: .decimalPad,
                    focusedField: focusedField,
                    fieldTag: .carbs,
                    isLast: false
                )
                Divider().padding(.leading, 52).opacity(0.4)
                NutritionInputRow(
                    icon: "drop.fill",
                    label: "지방",
                    text: $fatText,
                    unit: "g",
                    color: AppColors.fat,
                    keyboardType: .decimalPad,
                    focusedField: focusedField,
                    fieldTag: .fat,
                    isLast: true
                )
            }
            .glassCard(cornerRadius: AppRadius.lg)
            .padding(.horizontal, AppSpacing.md)
        }
    }
}

private struct NutritionInputRow: View {
    let icon: String
    let label: String
    @Binding var text: String
    let unit: String
    let color: Color
    let keyboardType: UIKeyboardType
    var focusedField: FocusState<AddMealEntryView.Field?>.Binding
    let fieldTag: AddMealEntryView.Field
    let isLast: Bool

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
            }

            Text(label)
                .font(AppFont.body(15))
                .foregroundStyle(.primary)

            Spacer()

            TextField("0", text: $text)
                .keyboardType(keyboardType)
                .multilineTextAlignment(.trailing)
                .frame(width: 72)
                .font(AppFont.mono(16))
                .foregroundStyle(.primary)
                .focused(focusedField, equals: fieldTag)

            Text(unit)
                .font(AppFont.caption(13))
                .foregroundStyle(.secondary)
                .frame(width: unit == "kcal" ? 32 : 12, alignment: .leading)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 2)
    }
}

// MARK: - Memo Section

private struct MemoSection: View {
    @Binding var memo: String
    var focusedField: FocusState<AddMealEntryView.Field?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("메모")
                .font(AppFont.caption(13))
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppSpacing.md)

            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: "note.text")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.accentLight)
                    .frame(width: 20)
                    .padding(.top, 1)

                TextField("메모 (선택사항)", text: $memo, axis: .vertical)
                    .font(AppFont.body(15))
                    .lineLimit(3)
                    .focused(focusedField, equals: .memo)
            }
            .padding(AppSpacing.md)
            .glassCard(cornerRadius: AppRadius.lg)
            .padding(.horizontal, AppSpacing.md)
        }
    }
}
