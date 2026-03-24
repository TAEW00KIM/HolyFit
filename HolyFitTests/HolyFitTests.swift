import Testing
import Foundation
import SwiftData
@testable import HolyFit

// MARK: - Test helpers

/// Creates an in-memory ModelContainer for testing
private func makeTestContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(
        for: Exercise.self,
             WorkoutSession.self,
             WorkoutEntry.self,
             WorkoutSet.self,
             MealEntry.self,
             WorkoutTemplate.self,
             TemplateEntry.self,
        configurations: config
    )
}

// MARK: - Issue 1: Cancelled workout cleanup

@Suite("Cancelled Workout Tests")
struct CancelledWorkoutTests {

    @Test("Deleting session removes it from DB")
    func cancelledSessionIsDeleted() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        // Create a session (simulating onAppear insert)
        let session = WorkoutSession()
        context.insert(session)
        try context.save()

        // Verify it exists
        let countBefore = try context.fetchCount(FetchDescriptor<WorkoutSession>())
        #expect(countBefore == 1)

        // Cancel: delete and save (simulating cancelWorkout)
        context.delete(session)
        try context.save()

        // Verify it's gone
        let countAfter = try context.fetchCount(FetchDescriptor<WorkoutSession>())
        #expect(countAfter == 0)
    }

    @Test("Only completed sessions have endDate set")
    func completedSessionHasEndDate() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        // Create two sessions: one completed, one not
        let completed = WorkoutSession()
        completed.endDate = Date()
        context.insert(completed)

        let incomplete = WorkoutSession()
        // endDate is nil by default
        context.insert(incomplete)
        try context.save()

        // Query with endDate filter (same as WorkoutTabView @Query)
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.endDate != nil }
        )
        let completedSessions = try context.fetch(descriptor)

        #expect(completedSessions.count == 1)
        #expect(completedSessions.first?.id == completed.id)
    }

    @Test("Cancelled session with entries is fully deleted via cascade")
    func cancelledSessionCascadesEntries() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let exercise = Exercise(name: "벤치프레스", muscleGroup: .chest)
        context.insert(exercise)

        let session = WorkoutSession()
        context.insert(session)

        let entry = WorkoutEntry(order: 0, exercise: exercise, session: session)
        context.insert(entry)
        session.entries.append(entry)

        let set1 = WorkoutSet(order: 0, weight: 60, reps: 10)
        set1.entry = entry
        entry.sets.append(set1)
        try context.save()

        // Verify everything exists
        #expect(try context.fetchCount(FetchDescriptor<WorkoutEntry>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSet>()) == 1)

        // Cancel workout: delete session
        context.delete(session)
        try context.save()

        // Session cascade should delete entries and sets
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSession>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutEntry>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSet>()) == 0)
        // Exercise should remain (nullify rule)
        #expect(try context.fetchCount(FetchDescriptor<Exercise>()) == 1)
    }
}

// MARK: - Issue 2: Seed data

@Suite("Seed Data Tests")
struct SeedDataTests {

    @Test("Seed inserts exercises and returns true")
    func seedSucceeds() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let result = ExerciseSeedData.seed(into: context)
        #expect(result == true)

        let count = try context.fetchCount(FetchDescriptor<Exercise>())
        #expect(count > 50) // Should have 65+ exercises
    }

    @Test("Seed does not double-insert if called twice")
    func seedIdempotency() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        ExerciseSeedData.seed(into: context)
        let firstCount = try context.fetchCount(FetchDescriptor<Exercise>())

        // Simulating the guard: only seed if empty
        let existingCount = try context.fetchCount(FetchDescriptor<Exercise>())
        if existingCount == 0 {
            ExerciseSeedData.seed(into: context)
        }

        let secondCount = try context.fetchCount(FetchDescriptor<Exercise>())
        #expect(firstCount == secondCount)
    }

    @Test("All muscle groups have seed exercises")
    func allMuscleGroupsCovered() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        ExerciseSeedData.seed(into: context)
        let exercises = try context.fetch(FetchDescriptor<Exercise>())

        let coveredGroups = Set(exercises.map(\.muscleGroup))
        for group in MuscleGroup.allCases {
            #expect(coveredGroups.contains(group), "Missing muscle group: \(group.rawValue)")
        }
    }
}

// MARK: - Issue 3: Data reset

@Suite("Data Reset Tests")
struct DataResetTests {

    @Test("Reset deletes sessions, meals, and templates")
    func resetDeletesAllDataTypes() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        // Insert data of each type
        let session = WorkoutSession()
        session.endDate = Date()
        context.insert(session)

        let meal = MealEntry(category: .lunch, foodName: "치킨", calories: 500)
        context.insert(meal)

        let template = WorkoutTemplate(name: "테스트 루틴")
        context.insert(template)
        try context.save()

        // Verify data exists
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSession>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<MealEntry>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutTemplate>()) == 1)

        // Perform reset (same as DataManagementView.resetAllData)
        try context.delete(model: WorkoutSession.self)
        try context.delete(model: MealEntry.self)
        try context.delete(model: WorkoutTemplate.self)
        try context.save()

        // All should be gone
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSession>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<MealEntry>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutTemplate>()) == 0)
    }

    @Test("Reset preserves exercises")
    func resetKeepsExercises() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        // Seed exercises + add user data
        ExerciseSeedData.seed(into: context)
        let session = WorkoutSession()
        session.endDate = Date()
        context.insert(session)
        try context.save()

        let exerciseCountBefore = try context.fetchCount(FetchDescriptor<Exercise>())

        // Reset
        try context.delete(model: WorkoutSession.self)
        try context.delete(model: MealEntry.self)
        try context.delete(model: WorkoutTemplate.self)
        try context.save()

        // Exercises should remain
        let exerciseCountAfter = try context.fetchCount(FetchDescriptor<Exercise>())
        #expect(exerciseCountAfter == exerciseCountBefore)
    }

    @Test("Template cascade deletes template entries")
    func templateCascadeDeletesEntries() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let exercise = Exercise(name: "스쿼트", muscleGroup: .legs)
        context.insert(exercise)

        let template = WorkoutTemplate(name: "하체 루틴")
        context.insert(template)

        let entry = TemplateEntry(order: 0, exercise: exercise, template: template,
                                  defaultSets: 4, defaultWeight: 100, defaultReps: 5)
        context.insert(entry)
        template.entries.append(entry)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<TemplateEntry>()) == 1)

        // Delete template
        try context.delete(model: WorkoutTemplate.self)
        try context.save()

        // Cascade should remove entries
        #expect(try context.fetchCount(FetchDescriptor<TemplateEntry>()) == 0)
        // Exercise remains
        #expect(try context.fetchCount(FetchDescriptor<Exercise>()) == 1)
    }
}

// MARK: - Model logic tests

@Suite("WorkoutSet Calculations")
struct WorkoutSetTests {

    @Test("Volume = weight * reps")
    func volumeCalculation() {
        let set = WorkoutSet(order: 0, weight: 80, reps: 10)
        #expect(set.volume == 800)
    }

    @Test("Volume is zero when weight is zero")
    func volumeZeroWeight() {
        let set = WorkoutSet(order: 0, weight: 0, reps: 10)
        #expect(set.volume == 0)
    }

    @Test("1RM Epley formula: weight * (1 + reps/30)")
    func oneRepMaxEpley() {
        let set = WorkoutSet(order: 0, weight: 100, reps: 10)
        // 100 * (1 + 10/30) = 100 * 1.333... = 133.33...
        let expected = 100.0 * (1.0 + 10.0 / 30.0)
        #expect(abs(set.estimatedOneRepMax - expected) < 0.01)
    }

    @Test("1RM returns weight for single rep")
    func oneRepMaxSingleRep() {
        let set = WorkoutSet(order: 0, weight: 140, reps: 1)
        #expect(set.estimatedOneRepMax == 140)
    }

    @Test("1RM returns 0 when reps or weight is 0")
    func oneRepMaxZero() {
        let zeroReps = WorkoutSet(order: 0, weight: 100, reps: 0)
        #expect(zeroReps.estimatedOneRepMax == 0)

        let zeroWeight = WorkoutSet(order: 0, weight: 0, reps: 10)
        #expect(zeroWeight.estimatedOneRepMax == 0)
    }
}

@Suite("WorkoutSession Calculations")
struct WorkoutSessionTests {

    @Test("Duration is nil when endDate is nil")
    func durationNilWithoutEnd() {
        let session = WorkoutSession()
        #expect(session.duration == nil)
    }

    @Test("Duration calculates correctly")
    func durationCalculation() {
        let start = Date()
        let session = WorkoutSession(startDate: start)
        session.endDate = start.addingTimeInterval(3600) // 1 hour
        #expect(session.duration == 3600)
    }

    @Test("Total volume sums across entries and sets")
    func totalVolumeCalculation() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let exercise = Exercise(name: "벤치프레스", muscleGroup: .chest)
        context.insert(exercise)

        let session = WorkoutSession()
        context.insert(session)

        let entry = WorkoutEntry(order: 0, exercise: exercise, session: session)
        context.insert(entry)
        session.entries.append(entry)

        let set1 = WorkoutSet(order: 0, weight: 60, reps: 10) // 600
        set1.entry = entry
        entry.sets.append(set1)

        let set2 = WorkoutSet(order: 1, weight: 80, reps: 5) // 400
        set2.entry = entry
        entry.sets.append(set2)

        try context.save()

        #expect(session.totalVolume == 1000)
        #expect(session.totalSets == 2)
        #expect(session.exerciseCount == 1)
    }
}

// MARK: - Template model tests

@Suite("Template Tests")
struct TemplateTests {

    @Test("Template sortedEntries returns by order")
    func templateSortedEntries() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let ex1 = Exercise(name: "벤치프레스", muscleGroup: .chest)
        let ex2 = Exercise(name: "스쿼트", muscleGroup: .legs)
        context.insert(ex1)
        context.insert(ex2)

        let template = WorkoutTemplate(name: "전신 루틴")
        context.insert(template)

        // Insert in reverse order
        let entry2 = TemplateEntry(order: 1, exercise: ex2, template: template)
        let entry1 = TemplateEntry(order: 0, exercise: ex1, template: template)
        context.insert(entry2)
        context.insert(entry1)
        template.entries.append(contentsOf: [entry2, entry1])
        try context.save()

        let sorted = template.sortedEntries
        #expect(sorted.count == 2)
        #expect(sorted[0].exercise?.name == "벤치프레스")
        #expect(sorted[1].exercise?.name == "스쿼트")
    }

    @Test("TemplateEntry defaults are correct")
    func templateEntryDefaults() {
        let entry = TemplateEntry(order: 0)
        #expect(entry.defaultSets == 3)
        #expect(entry.defaultWeight == 0)
        #expect(entry.defaultReps == 10)
    }
}

// MARK: - MealEntry tests

@Suite("Meal Entry Tests")
struct MealEntryTests {

    @Test("MealEntry optional macros default to nil")
    func mealOptionalFields() {
        let meal = MealEntry(category: .breakfast, foodName: "토스트")
        #expect(meal.calories == nil)
        #expect(meal.protein == nil)
        #expect(meal.carbs == nil)
        #expect(meal.fat == nil)
        #expect(meal.memo == "")
    }

    @Test("MealEntry stores all provided values")
    func mealFullEntry() {
        let meal = MealEntry(
            category: .dinner,
            foodName: "닭가슴살",
            calories: 300,
            protein: 50,
            carbs: 5,
            fat: 8,
            memo: "소금 약간"
        )
        #expect(meal.foodName == "닭가슴살")
        #expect(meal.calories == 300)
        #expect(meal.protein == 50)
        #expect(meal.carbs == 5)
        #expect(meal.fat == 8)
        #expect(meal.category == .dinner)
    }

    @Test("MealCategory has all 4 values")
    func mealCategoryCount() {
        #expect(MealCategory.allCases.count == 4)
    }
}

// MARK: - MuscleGroup tests

@Suite("MuscleGroup Tests")
struct MuscleGroupTests {

    @Test("9 muscle groups exist")
    func muscleGroupCount() {
        #expect(MuscleGroup.allCases.count == 9)
    }

    @Test("Each muscle group has a Korean name")
    func muscleGroupKoreanNames() {
        let expectedNames = ["가슴", "등", "어깨", "하체", "이두", "삼두", "코어", "전신", "유산소"]
        let actualNames = MuscleGroup.allCases.map(\.rawValue)
        for name in expectedNames {
            #expect(actualNames.contains(name), "Missing: \(name)")
        }
    }

    @Test("Each muscle group has an SF Symbol icon")
    func muscleGroupIcons() {
        for group in MuscleGroup.allCases {
            #expect(!group.icon.isEmpty, "\(group.rawValue) has no icon")
        }
    }
}

// MARK: - Drop set & one-arm tests

@Suite("Drop Set Tests")
struct DropSetTests {

    @Test("Drop set flag is stored correctly")
    func dropSetFlag() {
        let normal = WorkoutSet(order: 0, weight: 80, reps: 10, isDropSet: false)
        let drop = WorkoutSet(order: 1, weight: 60, reps: 12, isDropSet: true)
        #expect(normal.isDropSet == false)
        #expect(drop.isDropSet == true)
    }

    @Test("Drop set volume calculated same as normal set")
    func dropSetVolume() {
        let drop = WorkoutSet(order: 0, weight: 60, reps: 12, isDropSet: true)
        #expect(drop.volume == 720)
    }
}

@Suite("One-Arm Exercise Tests")
struct OneArmTests {

    @Test("isOneArm detects 원암 in name")
    func detectsOneArmKorean() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let exercise = Exercise(name: "원암 덤벨 로우", muscleGroup: .back)
        context.insert(exercise)
        let entry = WorkoutEntry(order: 0, exercise: exercise)
        context.insert(entry)
        try context.save()

        #expect(entry.isOneArm == true)
    }

    @Test("isOneArm detects 싱글 in name")
    func detectsSingle() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let exercise = Exercise(name: "싱글 레그 프레스", muscleGroup: .legs)
        context.insert(exercise)
        let entry = WorkoutEntry(order: 0, exercise: exercise)
        context.insert(entry)
        try context.save()

        #expect(entry.isOneArm == true)
    }

    @Test("Normal exercise is not one-arm")
    func normalExerciseNotOneArm() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let exercise = Exercise(name: "벤치프레스", muscleGroup: .chest)
        context.insert(exercise)
        let entry = WorkoutEntry(order: 0, exercise: exercise)
        context.insert(entry)
        try context.save()

        #expect(entry.isOneArm == false)
    }

    @Test("One-arm totalVolume is doubled")
    func oneArmVolumeDoubled() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let exercise = Exercise(name: "원암 덤벨 컬", muscleGroup: .biceps)
        context.insert(exercise)

        let entry = WorkoutEntry(order: 0, exercise: exercise)
        context.insert(entry)

        let set1 = WorkoutSet(order: 0, weight: 20, reps: 10) // raw: 200
        set1.entry = entry
        entry.sets.append(set1)
        try context.save()

        // 원암 x2: 200 * 2 = 400
        #expect(entry.totalVolume == 400)
    }

    @Test("Normal exercise totalVolume not doubled")
    func normalVolumeNotDoubled() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let exercise = Exercise(name: "바벨 컬", muscleGroup: .biceps)
        context.insert(exercise)

        let entry = WorkoutEntry(order: 0, exercise: exercise)
        context.insert(entry)

        let set1 = WorkoutSet(order: 0, weight: 40, reps: 10) // 400
        set1.entry = entry
        entry.sets.append(set1)
        try context.save()

        #expect(entry.totalVolume == 400)
    }

    @Test("Session totalVolume includes one-arm multiplier")
    func sessionVolumeWithOneArm() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let oneArmEx = Exercise(name: "원암 덤벨 로우", muscleGroup: .back)
        let normalEx = Exercise(name: "랫풀다운", muscleGroup: .back)
        context.insert(oneArmEx)
        context.insert(normalEx)

        let session = WorkoutSession()
        context.insert(session)

        // One-arm entry: 20kg x 10 = 200 raw → 400 (x2)
        let entry1 = WorkoutEntry(order: 0, exercise: oneArmEx, session: session)
        context.insert(entry1)
        session.entries.append(entry1)
        let set1 = WorkoutSet(order: 0, weight: 20, reps: 10)
        set1.entry = entry1
        entry1.sets.append(set1)

        // Normal entry: 60kg x 10 = 600
        let entry2 = WorkoutEntry(order: 1, exercise: normalEx, session: session)
        context.insert(entry2)
        session.entries.append(entry2)
        let set2 = WorkoutSet(order: 0, weight: 60, reps: 10)
        set2.entry = entry2
        entry2.sets.append(set2)

        try context.save()

        // 400 + 600 = 1000
        #expect(session.totalVolume == 1000)
    }
}

// MARK: - Widget data filtering

@Suite("Widget Data Tests")
struct WidgetDataTests {

    @Test("Widget only counts completed sessions")
    func widgetCountsCompletedOnly() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        // Completed session (today)
        let completed = WorkoutSession()
        completed.endDate = Date()
        context.insert(completed)

        // Incomplete session (cancelled)
        let incomplete = WorkoutSession()
        context.insert(incomplete)
        try context.save()

        // Same query logic as WidgetDataManager (no force-unwrap in #Predicate)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.endDate != nil }
        )
        let allCompleted = try context.fetch(descriptor)
        let count = allCompleted.filter {
            guard let end = $0.endDate else { return false }
            return end >= startOfDay && end < endOfDay
        }.count
        #expect(count == 1)
    }
}
