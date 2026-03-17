import Foundation

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest = "가슴"
    case back = "등"
    case shoulders = "어깨"
    case legs = "하체"
    case biceps = "이두"
    case triceps = "삼두"
    case core = "코어"
    case fullBody = "전신"
    case cardio = "유산소"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rowing"
        case .shoulders: return "figure.arms.open"
        case .legs: return "figure.walk"
        case .biceps: return "figure.curling"
        case .triceps: return "figure.strengthtraining.functional"
        case .core: return "figure.core.training"
        case .fullBody: return "figure.mixed.cardio"
        case .cardio: return "figure.run"
        }
    }
}
