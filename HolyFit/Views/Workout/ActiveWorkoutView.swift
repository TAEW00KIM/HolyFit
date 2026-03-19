import SwiftUI
import SwiftData
import UIKit
import HealthKit

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(HealthKitManager.self) private var healthKitManager
    @AppStorage("healthKitEnabled") private var healthKitEnabled: Bool = false
    @State private var session: WorkoutSession
    @State private var showExercisePicker = false
    @State private var showCancelAlert = false
    @State private var elapsedSeconds = 0
    @State private var workoutTimer: Timer?
    @State private var isReordering = false
    @State private var showSaveTemplateSheet = false
    @State private var templateName = ""
    @State private var showSaveToast = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var entryPendingDeletion: WorkoutEntry?
    @State private var showDeleteEntryDialog = false
    @State private var showCompletion = false
    @State private var showDatePicker = false

    private let templateEntries: [(exercise: Exercise, weight: Double, reps: Int, sets: Int)]

    init() {
        _session = State(initialValue: WorkoutSession())
        templateEntries = []
    }

    init(template: WorkoutTemplate) {
        _session = State(initialValue: WorkoutSession())
        templateEntries = template.sortedEntries.compactMap { entry in
            guard let exercise = entry.exercise else { return nil }
            return (exercise: exercise, weight: entry.defaultWeight, reps: entry.defaultReps, sets: entry.defaultSets)
        }
    }

    init(builtIn: BuiltInTemplate, allExercises: [Exercise]) {
        _session = State(initialValue: WorkoutSession())
        let exerciseMap = Dictionary(allExercises.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        templateEntries = builtIn.exercises.compactMap { item in
            guard let exercise = exerciseMap[item.exerciseName] else { return nil }
            return (exercise: exercise, weight: 0, reps: item.reps, sets: item.sets)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if isReordering {
                    reorderList
                } else {
                    ScrollView {
                        VStack(spacing: AppSpacing.md) {
                            // Date selector + Timer header strip
                            dateSelector
                            timerStrip

                            if session.entries.isEmpty {
                                emptyState
                            } else {
                                ForEach(session.sortedEntries) { entry in
                                    WorkoutEntrySection(entry: entry) {
                                        entryPendingDeletion = entry
                                        showDeleteEntryDialog = true
                                    }
                                }
                                .padding(.horizontal, AppSpacing.md)
                            }

                            // Bottom padding so FAB doesn't cover last card
                            Color.clear.frame(height: 100)
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                }

                // Floating action button (hidden while reordering)
                if !isReordering {
                    floatingAddButton
                }
            }
            .navigationTitle("운동 중")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        showCancelAlert = true
                    }
                    .foregroundStyle(AppColors.danger)
                    .font(AppFont.body(15))
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !session.entries.isEmpty {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isReordering.toggle()
                            }
                        } label: {
                            Text(isReordering ? "완료" : "순서 변경")
                                .font(AppFont.caption(14))
                                .foregroundStyle(isReordering ? AppColors.success : AppColors.accentLight)
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        templateName = ""
                        showSaveTemplateSheet = true
                    } label: {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(session.entries.isEmpty ? .secondary : AppColors.accentLight)
                    }
                    .disabled(session.entries.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        finishWorkout()
                    }
                    .disabled(session.entries.isEmpty)
                    .font(AppFont.heading(15))
                    .foregroundStyle(session.entries.isEmpty ? .secondary : AppColors.success)
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView { exercise in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    addExercise(exercise)
                }
            }
            .sheet(isPresented: $showSaveTemplateSheet) {
                saveTemplateSheet
            }
            .alert("운동을 취소하시겠습니까?", isPresented: $showCancelAlert) {
                Button("계속하기", role: .cancel) { }
                Button("취소하기", role: .destructive) {
                    cancelWorkout()
                }
            } message: {
                Text("기록된 내용이 모두 삭제됩니다.")
            }
            .alert("오류", isPresented: $showErrorAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .confirmationDialog("운동 삭제", isPresented: $showDeleteEntryDialog, titleVisibility: .visible) {
                Button("삭제", role: .destructive) {
                    if let entryPendingDeletion {
                        deleteEntry(entryPendingDeletion)
                    }
                    entryPendingDeletion = nil
                }
                Button("취소", role: .cancel) {
                    entryPendingDeletion = nil
                }
            } message: {
                Text(deleteEntryMessage)
            }
            .fullScreenCover(isPresented: $showCompletion) {
                WorkoutCompletionView(session: session) {
                    showCompletion = false
                    dismiss()
                }
            }
            .onAppear {
                modelContext.insert(session)
                startWorkoutTimer()
                if !templateEntries.isEmpty {
                    populateFromTemplate()
                }
            }
            .onDisappear {
                workoutTimer?.invalidate()
            }
            .overlay(alignment: .top) {
                if showSaveToast {
                    toastBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(999)
                }
            }
        }
    }

    // MARK: - Reorder List

    private var reorderList: some View {
        List {
            Section {
                ForEach(session.sortedEntries) { entry in
                    ReorderRowView(entry: entry)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.md, bottom: AppSpacing.xs, trailing: AppSpacing.md))
                        .listRowSeparator(.hidden)
                }
                .onMove { indices, newOffset in
                    moveEntries(from: indices, to: newOffset)
                }
            } header: {
                Text("길게 눌러 순서를 변경하세요")
                    .font(AppFont.caption(12))
                    .foregroundStyle(.secondary)
                    .textCase(nil)
                    .padding(.bottom, AppSpacing.xs)
            }
        }
        .listStyle(.plain)
        .background(Color(.systemGroupedBackground))
        .environment(\.editMode, .constant(.active))
    }

    // MARK: - Subviews

    private var dateSelector: some View {
        Button {
            showDatePicker = true
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
                Text(dateLabel)
                    .font(AppFont.caption(13))
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(AppColors.accent.opacity(0.08))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.xs)
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                DatePicker(
                    "운동 날짜",
                    selection: Binding(
                        get: { session.startDate },
                        set: { session.startDate = $0 }
                    ),
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(AppColors.accent)
                .padding()
                .navigationTitle("운동 날짜 선택")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("완료") {
                            showDatePicker = false
                        }
                        .font(AppFont.heading(15))
                        .foregroundStyle(AppColors.accent)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private var dateLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(session.startDate) {
            return "오늘"
        } else if calendar.isDateInYesterday(session.startDate) {
            return "어제"
        } else {
            return Self.dateLabelFormatter.string(from: session.startDate)
        }
    }

    private static let dateLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E)"
        return f
    }()

    private var timerStrip: some View {
        HStack {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.accentLight)
                Text(elapsedTimeString)
                    .font(AppFont.mono(15))
                    .foregroundStyle(.primary)
            }
            Spacer()
            HStack(spacing: AppSpacing.md) {
                Label("\(session.exerciseCount)종목", systemImage: "figure.strengthtraining.traditional")
                    .font(AppFont.caption(12))
                    .foregroundStyle(.secondary)
                Label("\(session.totalSets)세트", systemImage: "repeat")
                    .font(AppFont.caption(12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.surfaceElevated)
    }

    private var floatingAddButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showExercisePicker = true
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                Text("운동 추가")
                    .font(AppFont.heading(16))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.primaryGradient)
            .clipShape(Capsule())
            .shadow(color: AppColors.gradientStart.opacity(0.4), radius: 16, x: 0, y: 8)
        }
        .padding(.bottom, AppSpacing.xl)
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.lg) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryGradient)
                    .frame(width: 72, height: 72)
                    .opacity(0.12)
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(AppColors.primaryGradient)
            }
            VStack(spacing: AppSpacing.xs) {
                Text("운동을 추가하세요")
                    .font(AppFont.heading(18))
                Text("아래 버튼으로 운동을 추가하세요")
                    .font(AppFont.body(14))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxl)
    }

    // MARK: - Helpers

    private var elapsedTimeString: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    private func startWorkoutTimer() {
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                elapsedSeconds += 1
            }
        }
    }

    private func addExercise(_ exercise: Exercise) {
        let entry = WorkoutEntry(order: session.entries.count, exercise: exercise, session: session)
        let firstSet = WorkoutSet(order: 0)
        firstSet.entry = entry
        entry.sets.append(firstSet)
        session.entries.append(entry)
    }

    private func cancelWorkout() {
        modelContext.delete(session)
        do {
            try modelContext.save()
        } catch {
            errorMessage = "운동 취소 처리에 실패했습니다: \(error.localizedDescription)"
            showErrorAlert = true
            return
        }
        dismiss()
    }

    private func finishWorkout() {
        // 과거 날짜 기록 시 endDate도 같은 날로 설정 (현재 경과 시간 반영)
        let now = Date()
        let endDate: Date
        if Calendar.current.isDateInToday(session.startDate) {
            endDate = now
        } else {
            // 과거 날짜: startDate + 실제 경과 시간
            endDate = session.startDate.addingTimeInterval(TimeInterval(elapsedSeconds))
        }
        session.endDate = endDate
        do {
            try modelContext.save()
        } catch {
            errorMessage = "운동 저장에 실패했습니다: \(error.localizedDescription)"
            showErrorAlert = true
            return
        }
        WidgetDataManager.updateWidgetData(context: modelContext)

        if healthKitEnabled && healthKitManager.isAvailable && healthKitManager.isAuthorized {
            let startDate = session.startDate
            Task {
                await healthKitManager.saveWorkout(
                    type: .traditionalStrengthTraining,
                    start: startDate,
                    end: endDate,
                    totalEnergyBurned: nil
                )
            }
        }

        showCompletion = true
    }

    private func moveEntries(from indices: IndexSet, to newOffset: Int) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        var sorted = session.sortedEntries
        sorted.move(fromOffsets: indices, toOffset: newOffset)
        for (index, entry) in sorted.enumerated() {
            entry.order = index
        }
    }

    private func deleteEntry(_ entry: WorkoutEntry) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        session.entries.removeAll { $0.id == entry.id }
        modelContext.delete(entry)

        for (index, remainingEntry) in session.sortedEntries.enumerated() {
            remainingEntry.order = index
        }

        do {
            try modelContext.save()
        } catch {
            errorMessage = "운동 삭제에 실패했습니다: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }

    private var deleteEntryMessage: String {
        let entryName = entryPendingDeletion?.exercise?.name ?? "운동"
        return "\"\(entryName)\"을(를) 오늘 기록에서 삭제하시겠습니까?"
    }

    private func populateFromTemplate() {
        for (index, item) in templateEntries.enumerated() {
            let entry = WorkoutEntry(order: index, exercise: item.exercise, session: session)
            for setIndex in 0..<max(1, item.sets) {
                let workoutSet = WorkoutSet(order: setIndex, weight: item.weight, reps: item.reps)
                workoutSet.entry = entry
                entry.sets.append(workoutSet)
            }
            session.entries.append(entry)
        }
    }

    private func saveTemplate() {
        let name = templateName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let template = WorkoutTemplate(name: name)
        modelContext.insert(template)
        for (index, entry) in session.sortedEntries.enumerated() {
            guard let exercise = entry.exercise else { continue }
            let lastSet = entry.sortedSets.last
            let templateEntry = TemplateEntry(
                order: index,
                exercise: exercise,
                template: template,
                defaultSets: max(1, entry.sets.count),
                defaultWeight: lastSet?.weight ?? 0,
                defaultReps: lastSet?.reps ?? 10
            )
            modelContext.insert(templateEntry)
            template.entries.append(templateEntry)
        }
        do {
            try modelContext.save()
        } catch {
            errorMessage = "템플릿 저장에 실패했습니다: \(error.localizedDescription)"
            showErrorAlert = true
            return
        }
        showSaveTemplateSheet = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            showSaveToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSaveToast = false
            }
        }
    }

    // MARK: - Save Template Sheet

    private var saveTemplateSheet: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("루틴 이름")
                        .font(AppFont.caption(13))
                        .foregroundStyle(.secondary)
                    TextField("예: 월요일 가슴 루틴", text: $templateName)
                        .font(AppFont.body(16))
                        .padding(AppSpacing.md)
                        .background(Color(.systemBackground).opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .stroke(AppColors.accentLight.opacity(0.3), lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("포함 운동 (\(session.entries.count)종목)")
                        .font(AppFont.caption(13))
                        .foregroundStyle(.secondary)
                    VStack(spacing: AppSpacing.xs) {
                        ForEach(session.sortedEntries) { entry in
                            HStack(spacing: AppSpacing.sm) {
                                Circle()
                                    .fill(entry.exercise.map { AppColors.muscleGroupColor($0.muscleGroup) } ?? AppColors.accent)
                                    .frame(width: 8, height: 8)
                                Text(entry.exercise?.name ?? "운동")
                                    .font(AppFont.body(14))
                                Spacer()
                                Text("\(entry.sets.count)세트")
                                    .font(AppFont.caption(12))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.xs)
                        }
                    }
                    .glassCard()
                }

                Spacer()
            }
            .padding(AppSpacing.lg)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("템플릿으로 저장")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        showSaveTemplateSheet = false
                    }
                    .font(AppFont.body(15))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        saveTemplate()
                    }
                    .disabled(templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .font(AppFont.heading(15))
                    .foregroundStyle(templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : AppColors.accentLight)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Toast

    private var toastBanner: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.success)
            Text("템플릿이 저장되었습니다")
                .font(AppFont.caption(14))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.surfaceElevated)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        .padding(.top, AppSpacing.sm)
    }
}

// MARK: - WorkoutEntrySection

struct WorkoutEntrySection: View {
    @Environment(\.modelContext) private var modelContext
    let entry: WorkoutEntry
    let onDelete: () -> Void
    @State private var showRestTimer = false
    @AppStorage("defaultRestTimer") private var defaultRestTimer: Int = AppConstants.defaultRestTimerSeconds

    private var muscleColor: Color {
        entry.exercise.map { AppColors.muscleGroupColor($0.muscleGroup) } ?? AppColors.accent
    }

    private var completedSetsCount: Int {
        entry.sortedSets.filter { $0.completedAt != nil }.count
    }

    private var totalSetsCount: Int {
        entry.sets.count
    }

    private var allSetsCompleted: Bool {
        totalSetsCount > 0 && completedSetsCount == totalSetsCount
    }

    /// Find the most recent completed workout entry for the same exercise
    private var previousRecord: (date: Date, sets: [WorkoutSet])? {
        guard let exercise = entry.exercise else { return nil }
        // Use the Exercise -> entries inverse relationship
        let previousEntry = exercise.entries
            .filter { otherEntry in
                // Must belong to a completed session (endDate != nil) and not be this entry
                guard let session = otherEntry.session,
                      session.endDate != nil,
                      otherEntry.id != entry.id else { return false }
                return true
            }
            .compactMap { otherEntry -> (date: Date, sets: [WorkoutSet])? in
                guard let session = otherEntry.session else { return nil }
                return (date: session.startDate, sets: otherEntry.sortedSets)
            }
            .sorted { $0.date > $1.date }
            .first

        guard let previousEntry, !previousEntry.sets.isEmpty else { return nil }
        return previousEntry
    }

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M/d"
        return f
    }()

    private func formatDate(_ date: Date) -> String {
        Self.shortDateFormatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack(spacing: AppSpacing.sm) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(muscleColor)
                    .frame(width: 4, height: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.exercise?.name ?? "운동")
                        .font(AppFont.heading(16))
                        .lineLimit(1)
                    if let group = entry.exercise?.muscleGroup {
                        Text(group.rawValue)
                            .font(AppFont.caption(11))
                            .foregroundStyle(muscleColor.opacity(0.8))
                            .lineLimit(1)
                    }
                }

                Spacer()

                if completedSetsCount > 0 {
                    Text("\(completedSetsCount)/\(totalSetsCount) 세트 완료")
                        .font(AppFont.caption(11))
                        .foregroundStyle(allSetsCompleted ? AppColors.success : .secondary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(allSetsCompleted ? AppColors.success.opacity(0.12) : Color(.systemGray5))
                        )
                }

                // Timer button
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showRestTimer = true
                } label: {
                    Image(systemName: "timer")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(muscleColor)
                        .frame(width: 36, height: 36)
                        .background(muscleColor.opacity(0.12))
                        .clipShape(Circle())
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColors.danger)
                        .frame(width: 36, height: 36)
                        .background(AppColors.danger.opacity(0.12))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.sm)

            // Previous record
            if let record = previousRecord {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("지난 기록 (\(formatDate(record.date)))")
                        .font(AppFont.caption(11))
                        .foregroundStyle(.secondary)
                    ForEach(Array(record.sets.enumerated()), id: \.offset) { index, prevSet in
                        Text("\(index + 1)세트  \(String(format: "%.1f", prevSet.weight))kg \u{00d7} \(prevSet.reps)회")
                            .font(AppFont.caption(11))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.sm)
            }

            // Column headers
            HStack {
                Text("세트")
                    .frame(width: 32, alignment: .leading)
                Text("중량 (kg)")
                    .frame(maxWidth: .infinity)
                Text("횟수 (회)")
                    .frame(maxWidth: .infinity)
                Text("")
                    .frame(width: 94)
            }
            .font(AppFont.caption(11))
            .foregroundStyle(.secondary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.xs)

            Divider()
                .padding(.horizontal, AppSpacing.md)

            // Set rows
            VStack(spacing: 0) {
                ForEach(entry.sortedSets) { workoutSet in
                    SetRowView(workoutSet: workoutSet, accentColor: muscleColor) {
                        showRestTimer = true
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteSet(workoutSet, from: entry)
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                    }
                    if workoutSet.id != entry.sortedSets.last?.id {
                        Divider()
                            .padding(.leading, AppSpacing.md)
                    }
                }
            }

            // Add set row
            Divider()
                .padding(.horizontal, AppSpacing.md)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                addSet()
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("세트 추가")
                        .font(AppFont.caption(13))
                }
                .foregroundStyle(muscleColor)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
        }
        .glassCard()
        .sheet(isPresented: $showRestTimer) {
            RestTimerView(duration: defaultRestTimer)
                .id(defaultRestTimer)
                .presentationDetents([.medium])
        }
    }

    private func deleteSet(_ workoutSet: WorkoutSet, from entry: WorkoutEntry) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        entry.sets.removeAll { $0.id == workoutSet.id }
        modelContext.delete(workoutSet)
        // Re-order remaining sets
        for (index, remainingSet) in entry.sortedSets.enumerated() {
            remainingSet.order = index
        }
    }

    private func addSet() {
        let newOrder = entry.sets.count
        let newSet: WorkoutSet
        if let lastSet = entry.sortedSets.last {
            newSet = WorkoutSet(order: newOrder, weight: lastSet.weight, reps: lastSet.reps)
        } else {
            newSet = WorkoutSet(order: newOrder)
        }
        newSet.entry = entry
        entry.sets.append(newSet)
    }
}

// MARK: - SetRowView

struct SetRowView: View {
    @Bindable var workoutSet: WorkoutSet
    var accentColor: Color = AppColors.accent
    var onSetCompleted: (() -> Void)?

    private var isCompleted: Bool {
        workoutSet.completedAt != nil
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // Set number
            Text("\(workoutSet.order + 1)")
                .font(AppFont.mono(13))
                .foregroundStyle(isCompleted ? AppColors.success : .secondary)
                .frame(width: 32, alignment: .leading)

            // Weight stepper
            stepperField(
                value: Binding(
                    get: { workoutSet.weight },
                    set: { workoutSet.weight = $0 }
                ),
                step: AppConstants.weightIncrement,
                format: "%.1f",
                minValue: 0
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("무게")
            .accessibilityValue(String(format: "%.1f킬로그램", workoutSet.weight))
            .opacity(isCompleted ? 0.6 : 1.0)

            // Reps stepper
            stepperField(
                value: Binding(
                    get: { Double(workoutSet.reps) },
                    set: { workoutSet.reps = Int($0) }
                ),
                step: 1,
                format: "%.0f",
                minValue: 0
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("횟수")
            .accessibilityValue("\(workoutSet.reps)회")
            .opacity(isCompleted ? 0.6 : 1.0)

            // Badges + Checkmark
            HStack(spacing: 4) {
                badgeToggle(
                    label: "D",
                    isOn: Binding(
                        get: { workoutSet.isDropSet },
                        set: { workoutSet.isDropSet = $0 }
                    ),
                    activeColor: AppColors.warning
                )
                .accessibilityLabel("드랍세트")
                .accessibilityValue(workoutSet.isDropSet ? "활성" : "비활성")
                badgeToggle(
                    label: "T",
                    isOn: Binding(
                        get: { workoutSet.isTopSet },
                        set: { workoutSet.isTopSet = $0 }
                    ),
                    activeColor: AppColors.danger
                )
                .accessibilityLabel("탑세트")
                .accessibilityValue(workoutSet.isTopSet ? "활성" : "비활성")

                // Completion checkmark
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if isCompleted {
                            workoutSet.completedAt = nil
                        } else {
                            workoutSet.completedAt = Date()
                            onSetCompleted?()
                        }
                    }
                } label: {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: isCompleted ? 22 : 20, weight: isCompleted ? .semibold : .regular))
                        .foregroundStyle(isCompleted ? AppColors.success : accentColor.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .scaleEffect(isCompleted ? 1.0 : 0.9)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCompleted)
                        .symbolEffect(.bounce, value: workoutSet.completedAt)
                }
                .accessibilityLabel("세트 완료")
                .accessibilityValue(isCompleted ? "완료됨" : "미완료")
            }
            .frame(width: 94)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .fill(isCompleted ? AppColors.success.opacity(0.04) : Color.clear)
        )
        .contentShape(Rectangle())
    }

    private func stepperField(
        value: Binding<Double>,
        step: Double,
        format: String,
        minValue: Double
    ) -> some View {
        HStack(spacing: 0) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                value.wrappedValue = max(minValue, value.wrappedValue - step)
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
                        let v = value.wrappedValue
                        return step >= 1 ? String(format: "%.0f", v) : String(format: "%.1f", v)
                    },
                    set: { text in
                        if let parsed = Double(text), parsed >= minValue {
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

    private func badgeToggle(
        label: String,
        isOn: Binding<Bool>,
        activeColor: Color
    ) -> some View {
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

// MARK: - ReorderRowView

struct ReorderRowView: View {
    let entry: WorkoutEntry

    private var muscleColor: Color {
        entry.exercise.map { AppColors.muscleGroupColor($0.muscleGroup) } ?? AppColors.accent
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Drag handle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary.opacity(0.6))

            // Muscle group indicator
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(muscleColor)
                .frame(width: 4, height: 36)

            // Exercise name and muscle group
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.exercise?.name ?? "운동")
                    .font(AppFont.heading(15))
                Text(entry.exercise?.muscleGroup.rawValue ?? "")
                    .font(AppFont.caption(11))
                    .foregroundStyle(muscleColor.opacity(0.8))
            }

            Spacer()

            // Set count badge
            Text("\(entry.sets.count)세트")
                .font(AppFont.caption(12))
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .glassCard()
    }
}
