import SwiftUI
import SwiftData

// MARK: - Schema Versioning

enum HolyFitSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Exercise.self, WorkoutSession.self, WorkoutEntry.self,
         WorkoutSet.self, MealEntry.self, WorkoutTemplate.self,
         TemplateEntry.self, BodyMeasurement.self]
    }
}

enum HolyFitMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [HolyFitSchemaV1.self]
    }
    static var stages: [MigrationStage] { [] }
}

@main
struct HolyFitApp: App {
    @State private var healthKitManager = HealthKitManager()
    @AppStorage("appearanceMode") private var appearanceMode: String = "auto"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("didFixAbnormalDurations") private var didFixAbnormalDurations = false

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    let container: ModelContainer = {
        let schema = Schema(versionedSchema: HolyFitSchemaV1.self)
        let config = ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: HolyFitMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            // 마이그레이션 실패 시 DB 파일 삭제 후 재생성 (최후 수단)
            let storeURL = config.url
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("DB 복구 불가: \(error.localizedDescription)")
            }
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
                    seedExercises()
                    fixAbnormalDurations()
                    WidgetDataManager.updateWidgetData(context: container.mainContext)
                }
        }
        .modelContainer(container)
    }

    /// Seed exercises on first launch, and add new exercises after app updates
    private func seedExercises() {
        let context = container.mainContext
        let count = (try? context.fetchCount(FetchDescriptor<Exercise>())) ?? 0
        if count == 0 {
            // First launch: bulk seed
            _ = ExerciseSeedData.seed(into: context)
        } else {
            // Existing user: add only new exercises
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
    }

    /// One-time fix for sessions with abnormally long durations (caused by past-date endDate bug)
    private func fixAbnormalDurations() {
        guard !didFixAbnormalDurations else { return }
        let context = container.mainContext
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { $0.endDate != nil }
        )
        guard let sessions = try? context.fetch(descriptor) else { return }
        var fixed = false
        for session in sessions {
            guard let endDate = session.endDate else { continue }
            let duration = endDate.timeIntervalSince(session.startDate)
            if duration > 14400 {
                session.endDate = session.startDate.addingTimeInterval(5400)
                fixed = true
            }
        }
        if fixed { try? context.save() }
        didFixAbnormalDurations = true
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
