import SwiftUI
import SwiftData

struct DietTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate = Date()
    @State private var showAddMeal = false
    @State private var selectedCategory: MealCategory = .breakfast
    @State private var mealToEdit: MealEntry? = nil

    private var mealsForDate: [MealEntry] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: selectedDate)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        let descriptor = FetchDescriptor<MealEntry>(
            predicate: #Predicate<MealEntry> { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.date)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    // 날짜 네비게이션
                    DateNavigationHeader(selectedDate: $selectedDate)
                        .padding(.horizontal, AppSpacing.md)

                    // 일일 매크로 요약
                    DailySummaryCard(meals: mealsForDate)
                        .padding(.horizontal, AppSpacing.md)

                    // 카테고리별 식단 카드
                    ForEach(MealCategory.allCases) { category in
                        let categoryMeals = mealsForDate.filter { $0.category == category }
                        MealCategoryCard(
                            category: category,
                            meals: categoryMeals,
                            onAdd: {
                                selectedCategory = category
                                showAddMeal = true
                            },
                            onEdit: { meal in
                                mealToEdit = meal
                            },
                            onDelete: { meal in
                                withAnimation {
                                    modelContext.delete(meal)
                                    try? modelContext.save()
                                    WidgetDataManager.updateWidgetData(context: modelContext)
                                }
                            }
                        )
                        .padding(.horizontal, AppSpacing.md)
                    }

                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.top, AppSpacing.sm)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("식단")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddMeal) {
                AddMealEntryView(date: selectedDate, category: selectedCategory)
            }
            .sheet(item: $mealToEdit) { meal in
                AddMealEntryView(date: meal.date, category: meal.category, entryToEdit: meal)
            }
        }
    }
}

// MARK: - Date Navigation Header

struct DateNavigationHeader: View {
    @Binding var selectedDate: Date
    private let calendar = Calendar.current
    @State private var animationDirection: Int = 0

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    animationDirection = -1
                    selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(AppFont.body(15))
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular.interactive(), in: .circle)
            }
            .accessibilityLabel("이전 날짜")
            .accessibilityHint("하루 이전으로 이동합니다")

            Spacer()

            VStack(spacing: 2) {
                Text(dateDisplayText)
                    .font(AppFont.heading(18))
                    .foregroundStyle(.primary)
                if !calendar.isDateInToday(selectedDate) {
                    Text(fullDateText)
                        .font(AppFont.caption(12))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .contentTransition(.numericText())
            .accessibilityElement(children: .combine)
            .accessibilityLabel(calendar.isDateInToday(selectedDate) ? "오늘" : fullDateText)
            .accessibilityHint(calendar.isDateInToday(selectedDate) ? "" : "오늘 날짜로 이동하려면 날짜 화살표를 사용하세요")

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    animationDirection = 1
                    selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(AppFont.body(15))
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        calendar.isDateInToday(selectedDate)
                            ? Color.secondary.opacity(0.3)
                            : AppColors.accent
                    )
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular.interactive(), in: .circle)
            }
            .disabled(calendar.isDateInToday(selectedDate))
            .accessibilityLabel("다음 날짜")
            .accessibilityHint("하루 다음으로 이동합니다")
        }
    }

    private var dateDisplayText: String {
        if calendar.isDateInToday(selectedDate) {
            return "오늘"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "어제"
        } else {
            return AppDateFormatter.shortDate.string(from: selectedDate)
        }
    }

    private var fullDateText: String {
        AppDateFormatter.fullDate.string(from: selectedDate)
    }
}

// MARK: - Daily Summary Card

struct DailySummaryCard: View {
    let meals: [MealEntry]
    @AppStorage("profileTDEE") private var profileTDEE: Double = 2000

    private var totalCalories: Int { meals.compactMap(\.calories).reduce(0, +) }
    private var totalProtein: Double { meals.compactMap(\.protein).reduce(0, +) }
    private var totalCarbs: Double { meals.compactMap(\.carbs).reduce(0, +) }
    private var totalFat: Double { meals.compactMap(\.fat).reduce(0, +) }

    // Daily targets for progress bars
    private var targetCalories: Double { profileTDEE > 0 ? profileTDEE : 2000 }
    private let targetProtein: Double = 150
    private let targetCarbs: Double = 250
    private let targetFat: Double = 65

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Calorie ring + label
            HStack(alignment: .center, spacing: AppSpacing.lg) {
                CalorieRing(current: Double(totalCalories), target: targetCalories)
                    .frame(width: 90, height: 90)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("오늘 섭취")
                        .font(AppFont.caption(12))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(totalCalories)")
                            .font(AppFont.stat(32))
                            .foregroundStyle(AppColors.calories)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("kcal")
                            .font(AppFont.caption(14))
                            .foregroundStyle(.secondary)
                    }
                    Text("목표 \(Int(targetCalories))kcal")
                        .font(AppFont.caption(12))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("오늘 섭취 칼로리")
                .accessibilityValue("\(totalCalories)킬로칼로리, 목표 \(Int(targetCalories))킬로칼로리")

                Spacer()
            }

            Divider()
                .opacity(0.4)

            // Macro progress bars
            VStack(spacing: AppSpacing.sm) {
                MacroProgressRow(
                    label: "단백질",
                    value: totalProtein,
                    target: targetProtein,
                    unit: "g",
                    color: AppColors.protein
                )
                MacroProgressRow(
                    label: "탄수화물",
                    value: totalCarbs,
                    target: targetCarbs,
                    unit: "g",
                    color: AppColors.carbs
                )
                MacroProgressRow(
                    label: "지방",
                    value: totalFat,
                    target: targetFat,
                    unit: "g",
                    color: AppColors.fat
                )
            }
        }
        .padding(AppSpacing.md)
        .glassCard(cornerRadius: AppRadius.xl)
    }
}

struct CalorieRing: View {
    let current: Double
    let target: Double

    private var progress: Double { min(current / max(target, 1), 1.0) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.calories.opacity(0.15), lineWidth: 10)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [AppColors.calories, AppColors.calories.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

            VStack(spacing: 0) {
                Text("\(Int(progress * 100))%")
                    .font(AppFont.caption(12))
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.calories)
            }
        }
    }
}

struct MacroProgressRow: View {
    let label: String
    let value: Double
    let target: Double
    let unit: String
    let color: Color

    private var progress: Double { min(value / max(target, 1), 1.0) }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    Text(label)
                        .font(AppFont.caption(13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", value))
                        .font(AppFont.caption(13))
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("/ \(String(format: "%.0f", target))\(unit)")
                        .font(AppFont.caption(11))
                        .foregroundStyle(.tertiary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AppRadius.full, style: .continuous)
                        .fill(color.opacity(0.12))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: AppRadius.full, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(String(format: "%.1f", value))\(unit), 목표 \(String(format: "%.0f", target))\(unit)")
    }
}

// MARK: - Meal Category Card

struct MealCategoryCard: View {
    let category: MealCategory
    let meals: [MealEntry]
    let onAdd: () -> Void
    let onEdit: (MealEntry) -> Void
    let onDelete: (MealEntry) -> Void

    private var totalCalories: Int {
        meals.compactMap(\.calories).reduce(0, +)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Section header
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .fill(category.color.opacity(0.18))
                        .frame(width: 36, height: 36)
                    Image(systemName: category.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(category.color)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(category.rawValue)
                        .font(AppFont.heading(16))
                        .foregroundStyle(.primary)
                    if totalCalories > 0 {
                        Text("\(totalCalories) kcal")
                            .font(AppFont.caption(12))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button(action: onAdd) {
                    ZStack {
                        Circle()
                            .fill(AppColors.primaryGradient)
                            .frame(width: 32, height: 32)
                            .shadow(color: AppColors.gradientStart.opacity(0.35), radius: 6, x: 0, y: 3)
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, meals.isEmpty ? AppSpacing.md : AppSpacing.sm)

            // Meal rows or empty state
            if meals.isEmpty {
                EmptyCategoryPlaceholder()
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.md)
            } else {
                VStack(spacing: 0) {
                    ForEach(meals) { meal in
                        Button {
                            onEdit(meal)
                        } label: {
                            MealEntryRow(meal: meal)
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.sm)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation {
                                    onDelete(meal)
                                }
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }

                        if meal.id != meals.last?.id {
                            Divider()
                                .padding(.leading, AppSpacing.md)
                                .opacity(0.4)
                        }
                    }
                }
                .padding(.bottom, AppSpacing.sm)
            }
        }
        .glassCard(cornerRadius: AppRadius.xl)
    }
}

struct EmptyCategoryPlaceholder: View {
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: "plus.circle.dashed")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(.tertiary)
                Text("식단을 추가하세요")
                    .font(AppFont.caption(13))
                    .foregroundStyle(.quaternary)
            }
            .padding(.vertical, AppSpacing.md)
            Spacer()
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .foregroundStyle(.tertiary.opacity(0.3))
        )
    }
}

// MARK: - Meal Entry Row

struct MealEntryRow: View {
    let meal: MealEntry

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(meal.foodName)
                    .font(AppFont.body(15))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: AppSpacing.sm) {
                    if let p = meal.protein {
                        MacroBadge(label: "단", value: String(format: "%.0fg", p), color: AppColors.protein)
                    }
                    if let c = meal.carbs {
                        MacroBadge(label: "탄", value: String(format: "%.0fg", c), color: AppColors.carbs)
                    }
                    if let f = meal.fat {
                        MacroBadge(label: "지", value: String(format: "%.0fg", f), color: AppColors.fat)
                    }
                }
            }

            Spacer()

            if let cal = meal.calories {
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(cal)")
                        .font(AppFont.mono(15))
                        .foregroundStyle(AppColors.calories)
                    Text("kcal")
                        .font(AppFont.caption(11))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

struct MacroBadge: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(AppFont.caption(10))
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(value)
                .font(AppFont.caption(11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
    }
}
