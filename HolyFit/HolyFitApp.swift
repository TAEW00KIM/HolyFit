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
    @AppStorage("didMigrateSubgroups") private var didMigrateSubgroups = false
    @AppStorage("didMigrateLegsSubgroups") private var didMigrateLegsSubgroups = false

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
                    migrateExerciseSubgroups()
                    migrateLegsSubgroups()
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

    /// One-time migration to populate muscleSubgroup on existing exercises
    private func migrateExerciseSubgroups() {
        guard !didMigrateSubgroups else { return }
        let subgroupMap: [String: String] = [
            // 가슴 - 상부
            "인클라인 벤치프레스": "상부", "인클라인 덤벨프레스": "상부", "인클라인 덤벨 플라이": "상부",
            "인클라인 머신 프레스": "상부", "스미스 인클라인 프레스": "상부", "인클라인 스미스 프레스": "상부",
            "로우 케이블 크로스오버": "상부",
            // 가슴 - 하부
            "디클라인 벤치프레스": "하부", "디클라인 덤벨프레스": "하부", "디클라인 덤벨 플라이": "하부",
            "딥스": "하부", "어시스트 딥스": "하부", "하이 케이블 크로스오버": "하부",
            // 가슴 - 전체
            "벤치프레스": "전체", "덤벨 벤치프레스": "전체", "덤벨 플라이": "전체",
            "케이블 크로스오버": "전체", "머신 체스트 프레스": "전체", "스미스 머신 벤치프레스": "전체",
            "펙덱 플라이": "전체", "머신 플라이": "전체", "푸시업": "전체",
            "와이드 그립 벤치프레스": "전체", "클로즈그립 덤벨프레스": "전체",
            "원암 덤벨 벤치프레스": "전체", "원암 케이블 플라이": "전체",
            // 등 - 풀다운
            "랫풀다운": "풀다운", "클로즈그립 랫풀다운": "풀다운", "풀업": "풀다운",
            "어시스트 풀업": "풀다운", "친업": "풀다운", "와이드 그립 랫풀다운": "풀다운",
            "리버스 그립 랫풀다운": "풀다운", "뉴트럴 그립 랫풀다운": "풀다운",
            "와이드 그립 풀업": "풀다운", "뉴트럴 그립 풀업": "풀다운",
            "원암 랫풀다운": "풀다운", "케이블 풀오버": "풀다운",
            // 등 - 로우
            "바벨 로우": "로우", "덤벨 로우": "로우", "시티드 로우": "로우",
            "케이블 로우": "로우", "티바 로우": "로우", "펜들레이 로우": "로우",
            "머신 로우": "로우", "스미스 머신 로우": "로우", "와이드 그립 시티드 로우": "로우",
            "클로즈그립 시티드 로우": "로우", "리버스 그립 바벨 로우": "로우",
            "원암 덤벨 로우": "로우", "씰 로우": "로우", "체스트 서포트 로우": "로우",
            "메도우즈 로우": "로우", "원암 케이블 로우": "로우",
            // 등 - 데드리프트
            "데드리프트": "데드리프트", "컨벤셔널 데드리프트": "데드리프트", "스모 데드리프트": "데드리프트",
            // 어깨 - 전면
            "오버헤드 프레스": "전면", "덤벨 숄더 프레스": "전면", "머신 숄더 프레스": "전면",
            "스미스 머신 숄더 프레스": "전면", "아놀드 프레스": "전면", "프론트 레이즈": "전면",
            "바벨 프론트 레이즈": "전면", "랜드마인 프레스": "전면", "원암 덤벨 숄더 프레스": "전면",
            "원암 케이블 프론트 레이즈": "전면",
            // 어깨 - 측면
            "사이드 레터럴 레이즈": "측면", "케이블 사이드 레이즈": "측면", "머신 사이드 레이즈": "측면",
            "덤벨 사이드 레이즈": "측면", "업라이트 로우": "측면", "원암 사이드 레이즈": "측면",
            // 어깨 - 후면
            "페이스풀": "후면", "리어 델트 플라이": "후면", "리어 델트 머신": "후면",
            "벤트오버 리어 델트 레이즈": "후면", "케이블 리어 델트 플라이": "후면",
            // 어깨 - 전체
            "슈러그": "전체",
            // 이두 - 투암
            "바벨 컬": "투암", "이지바 컬": "투암", "덤벨 컬": "투암", "해머 컬": "투암",
            "프리처 컬": "투암", "머신 프리처 컬": "투암", "인클라인 덤벨 컬": "투암",
            "케이블 컬": "투암", "로프 해머 컬": "투암", "스파이더 컬": "투암",
            "리버스 컬": "투암", "와이드 그립 바벨 컬": "투암", "내로우 그립 바벨 컬": "투암",
            "크로스바디 해머 컬": "투암", "21s 컬": "투암", "케이블 해머 컬": "투암",
            // 이두 - 원암
            "컨센트레이션 컬": "원암", "원암 케이블 컬": "원암", "원암 프리처 컬": "원암",
            // 삼두 - 투암
            "트라이셉 푸시다운": "투암", "로프 푸시다운": "투암", "오버헤드 트라이셉 익스텐션": "투암",
            "케이블 오버헤드 익스텐션": "투암", "스컬 크러셔": "투암", "클로즈그립 벤치프레스": "투암",
            "삼두 딥스": "투암", "머신 딥스": "투암", "덤벨 오버헤드 익스텐션": "투암",
            "리버스 그립 푸시다운": "투암", "V바 푸시다운": "투암", "다이아몬드 푸시업": "투암",
            "벤치 딥스": "투암",
            // 삼두 - 원암
            "킥백": "원암", "원암 케이블 푸시다운": "원암", "원암 덤벨 오버헤드 익스텐션": "원암",
            "원암 케이블 킥백": "원암",
            // 하체 - 대퇴사두
            "스쿼트": "대퇴사두", "프론트 스쿼트": "대퇴사두", "스미스 머신 스쿼트": "대퇴사두",
            "핵 스쿼트": "대퇴사두", "레그 프레스": "대퇴사두", "레그 익스텐션": "대퇴사두",
            "불가리안 스플릿 스쿼트": "대퇴사두", "고블릿 스쿼트": "대퇴사두",
            "내로우 스탠스 스쿼트": "대퇴사두", "와이드 스탠스 스쿼트": "대퇴사두",
            "싱글 레그 레그프레스": "대퇴사두", "시시 스쿼트": "대퇴사두",
            "런지": "대퇴사두", "워킹 런지": "대퇴사두", "덤벨 런지": "대퇴사두",
            "원암 덤벨 런지": "대퇴사두", "스텝업": "대퇴사두", "싱글 레그 레그 익스텐션": "대퇴사두",
            // 하체 - 대퇴이두
            "레그 컬": "대퇴이두", "시티드 레그 컬": "대퇴이두",
            "루마니안 데드리프트": "대퇴이두", "스티프 레그 데드리프트": "대퇴이두",
            "덤벨 루마니안 데드리프트": "대퇴이두", "싱글 레그 레그컬": "대퇴이두",
            "싱글 레그 루마니안 데드리프트": "대퇴이두",
            // 하체 - 둔근
            "힙 쓰러스트": "둔근", "머신 힙 쓰러스트": "둔근", "바벨 힙 쓰러스트": "둔근",
            "힙 어브덕션": "둔근", "힙 어덕션": "둔근", "글루트 킥백 머신": "둔근",
            // 하체 - 카프
            "카프 레이즈": "카프", "시티드 카프 레이즈": "카프",
        ]
        let context = container.mainContext
        guard let exercises = try? context.fetch(FetchDescriptor<Exercise>()) else {
            didMigrateSubgroups = true
            return
        }
        var changed = false
        for exercise in exercises {
            if let subgroup = subgroupMap[exercise.name], exercise.muscleSubgroup == nil {
                exercise.muscleSubgroup = subgroup
                changed = true
            }
        }
        if changed { try? context.save() }
        didMigrateSubgroups = true
    }

    /// One-time migration to populate muscleSubgroup for leg exercises (added after initial migration)
    private func migrateLegsSubgroups() {
        guard !didMigrateLegsSubgroups else { return }
        let legsMap: [String: String] = [
            "스쿼트": "대퇴사두", "프론트 스쿼트": "대퇴사두", "스미스 머신 스쿼트": "대퇴사두",
            "핵 스쿼트": "대퇴사두", "레그 프레스": "대퇴사두", "레그 익스텐션": "대퇴사두",
            "불가리안 스플릿 스쿼트": "대퇴사두", "고블릿 스쿼트": "대퇴사두",
            "내로우 스탠스 스쿼트": "대퇴사두", "와이드 스탠스 스쿼트": "대퇴사두",
            "싱글 레그 레그프레스": "대퇴사두", "시시 스쿼트": "대퇴사두",
            "런지": "대퇴사두", "워킹 런지": "대퇴사두", "덤벨 런지": "대퇴사두",
            "원암 덤벨 런지": "대퇴사두", "스텝업": "대퇴사두", "싱글 레그 레그 익스텐션": "대퇴사두",
            "레그 컬": "대퇴이두", "시티드 레그 컬": "대퇴이두",
            "루마니안 데드리프트": "대퇴이두", "스티프 레그 데드리프트": "대퇴이두",
            "덤벨 루마니안 데드리프트": "대퇴이두", "싱글 레그 레그컬": "대퇴이두",
            "싱글 레그 루마니안 데드리프트": "대퇴이두",
            "힙 쓰러스트": "둔근", "머신 힙 쓰러스트": "둔근", "바벨 힙 쓰러스트": "둔근",
            "힙 어브덕션": "둔근", "힙 어덕션": "둔근", "글루트 킥백 머신": "둔근",
            "카프 레이즈": "카프", "시티드 카프 레이즈": "카프",
        ]
        let context = container.mainContext
        guard let exercises = try? context.fetch(FetchDescriptor<Exercise>()) else {
            didMigrateLegsSubgroups = true
            return
        }
        var changed = false
        for exercise in exercises {
            if let subgroup = legsMap[exercise.name], exercise.muscleSubgroup == nil {
                exercise.muscleSubgroup = subgroup
                changed = true
            }
        }
        if changed { try? context.save() }
        didMigrateLegsSubgroups = true
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
