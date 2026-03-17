import Foundation

enum ExerciseEquipmentMap {
    static let mapping: [String: Set<Equipment>] = [
        // 가슴
        "벤치프레스": [.barbell, .flatBench],
        "인클라인 벤치프레스": [.barbell, .inclineBench],
        "디클라인 벤치프레스": [.barbell, .declineBench],
        "덤벨 벤치프레스": [.dumbbell, .flatBench],
        "인클라인 덤벨프레스": [.dumbbell, .inclineBench],
        "덤벨 플라이": [.dumbbell, .flatBench],
        "인클라인 덤벨 플라이": [.dumbbell, .inclineBench],
        "케이블 크로스오버": [.cableMachine],
        "로우 케이블 크로스오버": [.cableMachine],
        "머신 체스트 프레스": [.chestPressMachine],
        "인클라인 머신 프레스": [.chestPressMachine],
        "스미스 머신 벤치프레스": [.smithMachine, .flatBench],
        "스미스 인클라인 프레스": [.smithMachine, .inclineBench],
        "펙덱 플라이": [.pecDeck],
        "딥스": [.dipBar],
        "어시스트 딥스": [.assistMachine],
        "푸시업": [],

        // 등
        "데드리프트": [.barbell],
        "컨벤셔널 데드리프트": [.barbell],
        "스모 데드리프트": [.barbell],
        "바벨 로우": [.barbell],
        "덤벨 로우": [.dumbbell, .flatBench],
        "랫풀다운": [.latPulldownMachine],
        "클로즈그립 랫풀다운": [.latPulldownMachine],
        "시티드 로우": [.latPulldownMachine],
        "풀업": [.pullUpBar],
        "어시스트 풀업": [.assistMachine],
        "친업": [.pullUpBar],
        "케이블 로우": [.cableMachine],
        "티바 로우": [.tBarRow],
        "펜들레이 로우": [.barbell],
        "머신 로우": [.machineRow],
        "케이블 풀오버": [.cableMachine],
        "스미스 머신 로우": [.smithMachine],

        // 어깨
        "오버헤드 프레스": [.barbell],
        "덤벨 숄더 프레스": [.dumbbell],
        "머신 숄더 프레스": [.shoulderPressMachine],
        "스미스 머신 숄더 프레스": [.smithMachine],
        "아놀드 프레스": [.dumbbell],
        "사이드 레터럴 레이즈": [.dumbbell],
        "케이블 사이드 레이즈": [.cableMachine],
        "머신 사이드 레이즈": [.sideRaiseMachine],
        "프론트 레이즈": [.dumbbell],
        "페이스풀": [.cableMachine],
        "리어 델트 플라이": [.dumbbell],
        "리어 델트 머신": [.rearDeltMachine],
        "업라이트 로우": [.barbell],
        "슈러그": [.barbell],

        // 하체
        "스쿼트": [.barbell],
        "프론트 스쿼트": [.barbell],
        "스미스 머신 스쿼트": [.smithMachine],
        "핵 스쿼트": [.hackSquat],
        "레그 프레스": [.legPress],
        "레그 익스텐션": [.legExtensionMachine],
        "레그 컬": [.legCurlMachine],
        "시티드 레그 컬": [.legCurlMachine],
        "루마니안 데드리프트": [.barbell],
        "불가리안 스플릿 스쿼트": [.dumbbell],
        "힙 쓰러스트": [.barbell, .flatBench],
        "머신 힙 쓰러스트": [.hipThrustMachine],
        "카프 레이즈": [.calfRaiseMachine],
        "시티드 카프 레이즈": [.calfRaiseMachine],
        "런지": [.dumbbell],
        "워킹 런지": [.dumbbell],
        "고블릿 스쿼트": [.dumbbell],
        "힙 어브덕션": [.hipAbductorMachine],
        "힙 어덕션": [.hipAbductorMachine],
        "글루트 킥백 머신": [.gluteKickbackMachine],

        // 이두
        "바벨 컬": [.barbell],
        "이지바 컬": [.ezBar],
        "덤벨 컬": [.dumbbell],
        "해머 컬": [.dumbbell],
        "프리처 컬": [.ezBar, .preacherBench],
        "머신 프리처 컬": [.preacherCurlMachine],
        "인클라인 덤벨 컬": [.dumbbell, .inclineBench],
        "컨센트레이션 컬": [.dumbbell],
        "케이블 컬": [.cableMachine],
        "로프 해머 컬": [.cableMachine],
        "스파이더 컬": [.dumbbell, .inclineBench],

        // 삼두
        "트라이셉 푸시다운": [.cableMachine],
        "로프 푸시다운": [.cableMachine],
        "오버헤드 트라이셉 익스텐션": [.dumbbell],
        "케이블 오버헤드 익스텐션": [.cableMachine],
        "스컬 크러셔": [.ezBar, .flatBench],
        "클로즈그립 벤치프레스": [.barbell, .flatBench],
        "삼두 딥스": [.dipBar],
        "머신 딥스": [.dipMachine],
        "킥백": [.dumbbell],
        "덤벨 오버헤드 익스텐션": [.dumbbell],

        // 코어
        "플랭크": [],
        "크런치": [],
        "머신 크런치": [.abCrunchMachine],
        "케이블 크런치": [.cableMachine],
        "레그 레이즈": [],
        "러시안 트위스트": [],
        "행잉 레그 레이즈": [.pullUpBar],
        "행잉 니 레이즈": [.pullUpBar],
        "앱 롤아웃": [.abRoller],
        "사이드 플랭크": [],
        "우드찹": [.cableMachine],

        // 전신
        "버피": [],
        "터키쉬 겟업": [.kettlebell],
        "케틀벨 스윙": [.kettlebell],
        "클린 앤 프레스": [.barbell],
        "맨 메이커": [.dumbbell],
        "파머스 워크": [.dumbbell],

        // 유산소
        "러닝": [.treadmill],
        "사이클": [.stationaryBike],
        "로잉머신": [.rowingMachine],
        "줄넘기": [.jumpRope],
        "스프린트 인터벌": [.treadmill],
        "스텝퍼": [.stepper],
    ]

    /// Returns required equipment for an exercise name. Empty set = bodyweight/no equipment.
    static func equipment(for exerciseName: String) -> Set<Equipment> {
        mapping[exerciseName] ?? []
    }

    /// Check if exercise can be done with the given available equipment
    static func canPerform(_ exerciseName: String, with availableEquipment: Set<Equipment>) -> Bool {
        let required = equipment(for: exerciseName)
        if required.isEmpty { return true }
        return required.isSubset(of: availableEquipment)
    }
}
