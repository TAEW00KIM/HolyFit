import Foundation

enum Equipment: String, Codable, CaseIterable, Identifiable {
    // Free weights
    case barbell = "바벨"
    case dumbbell = "덤벨"
    case kettlebell = "케틀벨"
    case ezBar = "이지바"

    // Benches
    case flatBench = "플랫 벤치"
    case inclineBench = "인클라인 벤치"
    case declineBench = "디클라인 벤치"
    case preacherBench = "프리처 벤치"

    // Bars / Bodyweight stations
    case pullUpBar = "풀업바"
    case dipBar = "딥스바/평행봉"
    case abRoller = "ab 롤러"

    // Cable machines
    case cableMachine = "케이블 머신"
    case smithMachine = "스미스 머신"

    // Plate-loaded machines
    case legPress = "레그 프레스"
    case hackSquat = "핵 스쿼트"
    case tBarRow = "T바 로우"

    // Pin-loaded machines
    case chestPressMachine = "체스트 프레스 머신"
    case shoulderPressMachine = "숄더 프레스 머신"
    case latPulldownMachine = "랫풀다운/시티드 로우"
    case legExtensionMachine = "레그 익스텐션 머신"
    case legCurlMachine = "레그 컬 머신"
    case pecDeck = "펙덱 머신"
    case rearDeltMachine = "리어 델트 머신"
    case hipThrustMachine = "힙 쓰러스트 머신"
    case hipAbductorMachine = "힙 어브덕션/어덕션"
    case gluteKickbackMachine = "글루트 킥백 머신"
    case calfRaiseMachine = "카프 레이즈 머신"
    case machineRow = "머신 로우"
    case assistMachine = "어시스트 머신"
    case abCrunchMachine = "복근 머신"
    case sideRaiseMachine = "사이드 레이즈 머신"
    case dipMachine = "딥스 머신"
    case preacherCurlMachine = "프리처 컬 머신"

    // Cardio
    case treadmill = "트레드밀"
    case stationaryBike = "실내 자전거"
    case rowingMachine = "로잉머신"
    case stepper = "스텝퍼"
    case jumpRope = "줄넘기"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .barbell, .ezBar: return "figure.strengthtraining.traditional"
        case .dumbbell: return "dumbbell.fill"
        case .kettlebell: return "figure.cross.training"
        case .flatBench, .inclineBench, .declineBench, .preacherBench: return "bed.double.fill"
        case .pullUpBar: return "figure.climbing"
        case .dipBar: return "arrow.down.to.line"
        case .abRoller: return "circle.dotted"
        case .cableMachine: return "cable.connector"
        case .smithMachine: return "square.stack.3d.up"
        case .legPress, .hackSquat: return "figure.walk"
        case .tBarRow: return "t.square"
        case .chestPressMachine, .shoulderPressMachine, .latPulldownMachine,
             .legExtensionMachine, .legCurlMachine, .pecDeck, .rearDeltMachine,
             .hipThrustMachine, .hipAbductorMachine, .gluteKickbackMachine,
             .calfRaiseMachine, .machineRow, .assistMachine, .abCrunchMachine,
             .sideRaiseMachine, .dipMachine, .preacherCurlMachine:
            return "gearshape.fill"
        case .treadmill: return "figure.run"
        case .stationaryBike: return "bicycle"
        case .rowingMachine: return "oar.2.crossed"
        case .stepper: return "stairs"
        case .jumpRope: return "figure.jumprope"
        }
    }

    var category: EquipmentCategory {
        switch self {
        case .barbell, .dumbbell, .kettlebell, .ezBar:
            return .freeWeights
        case .flatBench, .inclineBench, .declineBench, .preacherBench:
            return .benches
        case .pullUpBar, .dipBar, .abRoller:
            return .bodyweight
        case .cableMachine, .smithMachine:
            return .cableSmith
        case .legPress, .hackSquat, .tBarRow:
            return .plateLoaded
        case .chestPressMachine, .shoulderPressMachine, .latPulldownMachine,
             .legExtensionMachine, .legCurlMachine, .pecDeck, .rearDeltMachine,
             .hipThrustMachine, .hipAbductorMachine, .gluteKickbackMachine,
             .calfRaiseMachine, .machineRow, .assistMachine, .abCrunchMachine,
             .sideRaiseMachine, .dipMachine, .preacherCurlMachine:
            return .pinLoaded
        case .treadmill, .stationaryBike, .rowingMachine, .stepper, .jumpRope:
            return .cardio
        }
    }
}

enum EquipmentCategory: String, CaseIterable, Identifiable {
    case freeWeights = "프리 웨이트"
    case benches = "벤치"
    case bodyweight = "맨몸/보조"
    case cableSmith = "케이블/스미스"
    case plateLoaded = "플레이트 로디드"
    case pinLoaded = "핀 로디드 머신"
    case cardio = "유산소"

    var id: String { rawValue }
}

enum GymEquipmentStore {
    private static let key = "myGymEquipment"
    private static let setupKey = "hasSetUpGym"

    static func save(_ equipment: Set<Equipment>) {
        let rawValues = equipment.map(\.rawValue)
        if let data = try? JSONEncoder().encode(rawValues) {
            UserDefaults.standard.set(data, forKey: key)
            UserDefaults.standard.set(true, forKey: setupKey)
        }
    }

    static func load() -> Set<Equipment> {
        guard let data = UserDefaults.standard.data(forKey: key),
              let rawValues = try? JSONDecoder().decode([String].self, from: data)
        else { return Set(Equipment.allCases) }
        return Set(rawValues.compactMap { Equipment(rawValue: $0) })
    }

    static var hasSetUp: Bool {
        UserDefaults.standard.bool(forKey: setupKey)
    }
}
