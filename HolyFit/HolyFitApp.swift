import SwiftUI
import SwiftData

@main
struct HolyFitApp: App {
    @State private var healthKitManager = HealthKitManager()
    @AppStorage("appearanceMode") private var appearanceMode: String = "auto"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    let container: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            WorkoutSession.self,
            WorkoutEntry.self,
            WorkoutSet.self,
            MealEntry.self,
            WorkoutTemplate.self,
            TemplateEntry.self,
            BodyMeasurement.self
        ])
        let config = ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // 스토어 손상 시 새로 생성
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallbackConfig])
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(healthKitManager)
                .preferredColorScheme(colorScheme)
                .fullScreenCover(isPresented: Binding(
                    get: { !hasCompletedOnboarding },
                    set: { if !$0 { hasCompletedOnboarding = true } }
                )) {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
                .task {
                    purgeAbandonedSessions()
                    seedNewExercises()
                }
        }
        .modelContainer(container)
    }

    /// Add new exercises from seed data that don't exist yet (for existing users after update)
    private func seedNewExercises() {
        let context = container.mainContext
        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let existingNames = Set(existing.map(\.name))
        let allSeeds = ExerciseSeedData.allExercises()
        var added = false
        for exercise in allSeeds where !existingNames.contains(exercise.name) {
            context.insert(exercise)
            added = true
        }
        if added {
            try? context.save()
        }
    }

    /// Delete workout sessions that were never completed (app crash/force quit)
    private func purgeAbandonedSessions() {
        let context = container.mainContext
        let cutoff = Date().addingTimeInterval(-86400) // 24 hours ago
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { $0.endDate == nil && $0.startDate < cutoff }
        )
        guard let abandoned = try? context.fetch(descriptor), !abandoned.isEmpty else { return }
        for session in abandoned {
            context.delete(session)
        }
        try? context.save()
    }
}
