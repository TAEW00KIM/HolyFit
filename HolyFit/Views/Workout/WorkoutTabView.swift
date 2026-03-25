import SwiftUI
import SwiftData

struct WorkoutTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<WorkoutSession> { $0.endDate != nil },
        sort: \WorkoutSession.startDate,
        order: .reverse
    ) private var sessions: [WorkoutSession]
    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse) private var templates: [WorkoutTemplate]
    @Query private var allExercises: [Exercise]
    @State private var showActiveWorkout = false
    @State private var heroAppeared = false
    @State private var selectedTemplate: WorkoutTemplate? = nil
    @State private var selectedBuiltIn: BuiltInTemplate? = nil
    @State private var sessionToDelete: WorkoutSession? = nil
    @State private var selectedSession: WorkoutSession? = nil
    @State private var templateToDelete: WorkoutTemplate? = nil
    @State private var showRoutineGenerator = false
    @State private var expandedWeeks: Set<String> = ["이번 주"]

    private var todaysSessions: [WorkoutSession] {
        let calendar = Calendar.current
        return sessions.filter { calendar.isDateInToday($0.startDate) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // SECTION: 오늘 운동
                    VStack(spacing: AppSpacing.md) {
                        heroCard
                            .padding(.horizontal, AppSpacing.md)
                    }

                    // SECTION: 루틴
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        sectionHeader(title: "루틴", icon: "list.clipboard.fill")
                            .padding(.horizontal, AppSpacing.md)

                        routineGeneratorCard
                            .padding(.horizontal, AppSpacing.md)

                        if !templates.isEmpty {
                            templateSection
                        }

                        builtInSection
                    }

                    // SECTION: 기록
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        sectionHeader(title: "기록", icon: "calendar.badge.clock")
                            .padding(.horizontal, AppSpacing.md)

                        WorkoutCalendarCard()
                            .padding(.horizontal, AppSpacing.md)

                        if sessions.isEmpty {
                            emptyState
                        } else {
                            recentSessionsSection
                        }
                    }
                }
                .padding(.bottom, AppSpacing.lg)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("운동")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selectedSession) { session in
                WorkoutDetailView(session: session)
            }
            .fullScreenCover(isPresented: $showActiveWorkout, onDismiss: {
                selectedTemplate = nil
                selectedBuiltIn = nil
            }) {
                if let template = selectedTemplate {
                    ActiveWorkoutView(template: template)
                } else if let builtIn = selectedBuiltIn {
                    ActiveWorkoutView(builtIn: builtIn, allExercises: allExercises)
                } else {
                    ActiveWorkoutView()
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1)) {
                    heroAppeared = true
                }
            }
            .alert("삭제하시겠습니까?", isPresented: .init(
                get: { sessionToDelete != nil },
                set: { if !$0 { sessionToDelete = nil } }
            )) {
                Button("삭제", role: .destructive) {
                    if let session = sessionToDelete {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation {
                            modelContext.delete(session)
                            try? modelContext.save()
                            WidgetDataManager.updateWidgetData(context: modelContext)
                        }
                    }
                    sessionToDelete = nil
                }
                Button("취소", role: .cancel) {
                    sessionToDelete = nil
                }
            } message: {
                Text("이 운동 기록이 영구적으로 삭제됩니다.")
            }
            .alert("삭제하시겠습니까?", isPresented: .init(
                get: { templateToDelete != nil },
                set: { if !$0 { templateToDelete = nil } }
            )) {
                Button("삭제", role: .destructive) {
                    if let template = templateToDelete {
                        modelContext.delete(template)
                        try? modelContext.save()
                    }
                    templateToDelete = nil
                }
                Button("취소", role: .cancel) {
                    templateToDelete = nil
                }
            } message: {
                Text("이 루틴 템플릿이 삭제됩니다.")
            }
        }
        .sheet(isPresented: $showRoutineGenerator) {
            RoutineGeneratorView { template in
                selectedBuiltIn = template
                showActiveWorkout = true
            }
        }
    }

    // MARK: - Routine Generator Card

    private var routineGeneratorCard: some View {
        Button {
            showRoutineGenerator = true
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "dice.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppColors.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("루틴 자동 생성")
                        .font(AppFont.heading(16))
                        .foregroundStyle(.primary)
                    Text("내 기구에 맞는 운동 추천")
                        .font(AppFont.caption(12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(AppSpacing.md)
            .glassCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.accent)
            Text(title)
                .font(AppFont.heading(17))
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("오늘도")
                        .font(AppFont.heading(18))
                        .foregroundStyle(.secondary)
                    Text("도전하세요 💪")
                        .font(AppFont.title(28))
                        .foregroundStyle(.primary)
                }
                Spacer()
                // Today badge
                VStack(spacing: 2) {
                    Text("\(todaysSessions.count)")
                        .font(AppFont.stat(32))
                        .foregroundStyle(.primary)
                    Text("오늘 완료")
                        .font(AppFont.caption(11))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(AppColors.gradientStart.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .strokeBorder(AppColors.gradientStart.opacity(0.25), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            }

            // Stats row
            HStack(spacing: AppSpacing.md) {
                heroStatPill(
                    icon: "flame.fill",
                    value: "\(sessions.count)",
                    label: "총 운동"
                )
                heroStatPill(
                    icon: "scalemass.fill",
                    value: {
                        let vol = sessions.first.map { $0.totalVolume } ?? 0
                        if vol >= 1000 {
                            let f = NumberFormatter()
                            f.numberStyle = .decimal
                            f.maximumFractionDigits = 0
                            return f.string(from: NSNumber(value: vol)) ?? String(format: "%.0f", vol)
                        }
                        return String(format: "%.0f", vol)
                    }(),
                    label: "최근 볼륨(kg)"
                )
                heroStatPill(
                    icon: "clock.fill",
                    value: sessions.first?.duration.map { AppDateFormatter.durationString(from: $0) } ?? "--",
                    label: "최근 시간"
                )
            }

            // CTA Button
            Button {
                showActiveWorkout = true
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("운동 시작")
                        .font(AppFont.heading(17))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 50)
                .background(AppColors.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                .shadow(color: AppColors.gradientStart.opacity(0.35), radius: 12, x: 0, y: 6)
            }
            .scaleEffect(heroAppeared ? 1 : 0.92)
            .opacity(heroAppeared ? 1 : 0)
            .accessibilityLabel("운동 시작")
            .accessibilityHint("새 운동 세션을 시작합니다")
        }
        .padding(AppSpacing.lg)
        .background(
            LinearGradient(
                colors: [AppColors.gradientStart.opacity(0.1), Color.clear],
                startPoint: .top,
                endPoint: .center
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xxl, style: .continuous))
        .glassEffect(.regular, in: .rect(cornerRadius: AppRadius.xxl))
        .scaleEffect(heroAppeared ? 1 : 0.95)
        .opacity(heroAppeared ? 1 : 0)
    }

    private func heroStatPill(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppColors.accent)
                Text(value)
                    .font(AppFont.heading(15))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Text(label)
                .font(AppFont.caption(10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
        .background(Color.primary.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.09), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }

    // MARK: - Template Section

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("루틴 템플릿")
                    .font(AppFont.heading(18))
                Spacer()
                Text("\(templates.count)개")
                    .font(AppFont.caption(13))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, AppSpacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(templates) { template in
                        TemplateCard(template: template) {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            selectedTemplate = template
                            showActiveWorkout = true
                        } onDelete: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            templateToDelete = template
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
            }
        }
    }

    // MARK: - Built-in Section

    private var builtInSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("기본 루틴")
                    .font(AppFont.heading(18))
                Spacer()
                Text("\(BuiltInTemplates.all.count)개")
                    .font(AppFont.caption(13))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, AppSpacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(BuiltInTemplates.all) { template in
                        BuiltInTemplateCard(template: template) {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            selectedBuiltIn = template
                            showActiveWorkout = true
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
            }
        }
    }

    // MARK: - Sessions by Week

    private var sessionsByWeek: [(title: String, sessions: [WorkoutSession])] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let today = Date()
        guard let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)),
              let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) else {
            return [("최근 운동", sessions)]
        }

        var groups: [Date: [WorkoutSession]] = [:]
        for session in sessions {
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: session.startDate)) else { continue }
            groups[weekStart, default: []].append(session)
        }

        let sortedKeys = groups.keys.sorted(by: >)
        return sortedKeys.map { weekStart in
            let title: String
            if weekStart == thisWeekStart {
                title = "이번 주"
            } else if weekStart == lastWeekStart {
                title = "지난 주"
            } else {
                let weeksAgo = calendar.dateComponents([.weekOfYear], from: weekStart, to: thisWeekStart).weekOfYear ?? 0
                title = "\(weeksAgo)주 전"
            }
            return (title: title, sessions: groups[weekStart]!)
        }
    }

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(sessionsByWeek, id: \.title) { group in
                WeekGroupRow(
                    title: group.title,
                    sessions: group.sessions,
                    isExpanded: Binding(
                        get: { expandedWeeks.contains(group.title) },
                        set: { isExpanded in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if isExpanded { expandedWeeks.insert(group.title) }
                                else { expandedWeeks.remove(group.title) }
                            }
                        }
                    ),
                    onTap: { selectedSession = $0 },
                    onDelete: { sessionToDelete = $0 }
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.accent.opacity(0.6))

            VStack(spacing: AppSpacing.xs) {
                Text("아직 운동 기록이 없어요")
                    .font(AppFont.heading(18))
                Text("첫 운동을 시작해보세요!")
                    .font(AppFont.body(14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showActiveWorkout = true
            } label: {
                Text("운동 시작하기")
                    .font(AppFont.heading(15))
                    .foregroundStyle(.white)
                    .frame(maxWidth: 200)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColors.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            }
        }
        .padding(AppSpacing.xxl)
        .frame(maxWidth: .infinity)
        .glassCard()
        .padding(.horizontal, AppSpacing.md)
    }
}

// MARK: - WorkoutSessionRow

struct WorkoutSessionRow: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Date badge
            VStack(spacing: 2) {
                Text(dayString(from: session.startDate))
                    .font(AppFont.stat(24))
                    .foregroundStyle(AppColors.accent)
                Text(monthString(from: session.startDate))
                    .font(AppFont.caption(11))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 48)

            Rectangle()
                .fill(AppColors.accent.opacity(0.25))
                .frame(width: 1)
                .padding(.vertical, AppSpacing.xs)

            // Main content
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(weekdayString(from: session.startDate))
                    .font(AppFont.heading(15))

                HStack(spacing: AppSpacing.md) {
                    statLabel(icon: "figure.strengthtraining.traditional",
                              value: "\(session.exerciseCount)종목")
                    statLabel(icon: "repeat",
                              value: "\(session.totalSets)세트")
                    if let duration = session.duration {
                        statLabel(icon: "clock",
                                  value: AppDateFormatter.durationString(from: duration))
                    }
                }
            }

            Spacer()

            // Volume
            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedVolume(session.totalVolume))
                    .font(AppFont.heading(17))
                    .foregroundStyle(AppColors.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("kg")
                    .font(AppFont.caption(11))
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: true, vertical: false)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(AppSpacing.md)
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(weekdayString(from: session.startDate)), \(session.exerciseCount)종목, \(session.totalSets)세트")
    }

    private func statLabel(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(AppFont.caption(12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func dayString(from date: Date) -> String {
        AppDateFormatter.dayNumber.string(from: date)
    }

    private func monthString(from date: Date) -> String {
        AppDateFormatter.monthShort.string(from: date)
    }

    private func weekdayString(from date: Date) -> String {
        AppDateFormatter.weekday.string(from: date)
    }

    private func formattedVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            let formatted = NumberFormatter()
            formatted.numberStyle = .decimal
            formatted.maximumFractionDigits = 0
            return formatted.string(from: NSNumber(value: volume)) ?? String(format: "%.0f", volume)
        }
        return String(format: "%.0f", volume)
    }
}

// MARK: - TemplateCard

struct TemplateCard: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    private var muscleGroups: [String] {
        let groups = template.sortedEntries.compactMap { $0.exercise?.muscleGroup.rawValue }
        var seen = Set<String>()
        return groups.filter { seen.insert($0).inserted }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header row
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .fill(AppColors.primaryGradient)
                        .frame(width: 36, height: 36)
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Button {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .accessibilityLabel("템플릿 옵션")
                .confirmationDialog("템플릿 삭제", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                    Button("삭제", role: .destructive) {
                        onDelete()
                    }
                    Button("취소", role: .cancel) { }
                } message: {
                    Text("\"\(template.name)\" 템플릿을 삭제하시겠습니까?")
                }
            }

            // Template name
            Text(template.name)
                .font(AppFont.heading(15))
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Exercise count
            Text("\(template.entries.count)종목")
                .font(AppFont.caption(12))
                .foregroundStyle(.secondary)

            // Muscle group chips
            if !muscleGroups.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.xs) {
                        ForEach(muscleGroups, id: \.self) { group in
                            Text(group)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppColors.accentLight)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(AppColors.accentLight.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Start button
            Button(action: onTap) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("시작")
                        .font(AppFont.caption(13))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(AppColors.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            }
        }
        .padding(AppSpacing.md)
        .frame(width: 160)
        .glassCard()
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }
}

// MARK: - BuiltInTemplateCard

struct BuiltInTemplateCard: View {
    let template: BuiltInTemplate
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header row
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .fill(AppColors.accentLight.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                .strokeBorder(AppColors.accentLight.opacity(0.35), lineWidth: 1)
                        )
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.accentLight)
                }
                Spacer()
                Text("기본")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.accentLight)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(AppColors.accentLight.opacity(0.12))
                    .clipShape(Capsule())
            }

            // Template name
            Text(template.name)
                .font(AppFont.heading(15))
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Exercise count
            Text("\(template.exercises.count)종목")
                .font(AppFont.caption(12))
                .foregroundStyle(.secondary)

            // Exercise list preview
            VStack(alignment: .leading, spacing: 2) {
                ForEach(template.exercises.prefix(3), id: \.exerciseName) { item in
                    HStack(spacing: AppSpacing.xs) {
                        Circle()
                            .fill(AppColors.accentLight.opacity(0.5))
                            .frame(width: 4, height: 4)
                        Text("\(item.exerciseName)  \(item.sets)×\(item.reps)")
                            .font(AppFont.caption(11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                if template.exercises.count > 3 {
                    Text("+ \(template.exercises.count - 3)종목 더")
                        .font(AppFont.caption(10))
                        .foregroundStyle(.tertiary)
                        .padding(.leading, AppSpacing.sm)
                }
            }

            // Start button
            Button(action: onTap) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("시작")
                        .font(AppFont.caption(13))
                }
                .foregroundStyle(AppColors.accentLight)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(AppColors.accentLight.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .strokeBorder(AppColors.accentLight.opacity(0.35), lineWidth: 1)
                )
            }
        }
        .padding(AppSpacing.md)
        .frame(width: 160)
        .contentShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(AppColors.accentLight.opacity(0.25), lineWidth: 1.5)
        )
    }
}

// MARK: - WeekGroupRow

struct WeekGroupRow: View {
    let title: String
    let sessions: [WorkoutSession]
    @Binding var isExpanded: Bool
    let onTap: (WorkoutSession) -> Void
    let onDelete: (WorkoutSession) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Text(title)
                        .font(AppFont.heading(16))
                        .foregroundStyle(.primary)

                    Text("\(sessions.count)회")
                        .font(AppFont.caption(12))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.primary.opacity(0.07))
                        .clipShape(Capsule())

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Sessions
            if isExpanded {
                VStack(spacing: AppSpacing.xs) {
                    ForEach(sessions) { session in
                        Button {
                            onTap(session)
                        } label: {
                            WorkoutSessionRow(session: session)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, AppSpacing.md)
                        .contextMenu {
                            Button { onTap(session) } label: {
                                Label("상세 보기", systemImage: "eye")
                            }
                            Button(role: .destructive) {
                                onDelete(session)
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }
                    }
                }
                .transition(.opacity)
            }
        }
    }
}
