import Foundation
import SwiftData

@MainActor
let previewContainer: ModelContainer = {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Exercise.self, WorkoutSession.self, WorkoutEntry.self, WorkoutSet.self, MealEntry.self, WorkoutTemplate.self, TemplateEntry.self,
        configurations: config
    )

    // 샘플 운동 데이터
    let benchPress = Exercise(name: "벤치프레스", muscleGroup: .chest, instructions: "바벨을 가슴까지 내렸다 올리기")
    let squat = Exercise(name: "스쿼트", muscleGroup: .legs, instructions: "바벨을 메고 앉았다 일어서기")
    container.mainContext.insert(benchPress)
    container.mainContext.insert(squat)

    // 샘플 세션
    let session = WorkoutSession(startDate: Date().addingTimeInterval(-3600), notes: "좋은 컨디션")
    session.endDate = Date()
    container.mainContext.insert(session)

    let entry = WorkoutEntry(order: 0, exercise: benchPress, session: session)
    container.mainContext.insert(entry)

    let set1 = WorkoutSet(order: 0, weight: 60, reps: 12)
    set1.entry = entry
    let set2 = WorkoutSet(order: 1, weight: 80, reps: 8, isTopSet: true)
    set2.entry = entry
    let set3 = WorkoutSet(order: 2, weight: 60, reps: 10, isDropSet: true)
    set3.entry = entry
    container.mainContext.insert(set1)
    container.mainContext.insert(set2)
    container.mainContext.insert(set3)

    // 샘플 식단
    let meal1 = MealEntry(category: .breakfast, foodName: "계란 3개 + 토스트", calories: 450, protein: 25, carbs: 30, fat: 15)
    let meal2 = MealEntry(category: .lunch, foodName: "닭가슴살 샐러드", calories: 350, protein: 40, carbs: 10, fat: 8)
    container.mainContext.insert(meal1)
    container.mainContext.insert(meal2)

    return container
}()
