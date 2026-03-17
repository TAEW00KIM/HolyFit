import Foundation
import SwiftUI

enum MealCategory: String, Codable, CaseIterable, Identifiable {
    case breakfast = "아침"
    case lunch = "점심"
    case dinner = "저녁"
    case snack = "간식"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "cup.and.saucer.fill"
        }
    }

    var color: Color {
        switch self {
        case .breakfast: return Color(hex: "FDCB6E")
        case .lunch: return Color(hex: "74B9FF")
        case .dinner: return Color(hex: "6C5CE7")
        case .snack: return Color(hex: "00B894")
        }
    }
}
