import Foundation
import SwiftData

@Model
class WorkoutSet {
    var id: UUID
    var order: Int
    var weight: Double
    var reps: Int
    var isDropSet: Bool
    var isTopSet: Bool
    var completedAt: Date?

    var entry: WorkoutEntry?

    init(order: Int, weight: Double = 0, reps: Int = 0, isDropSet: Bool = false, isTopSet: Bool = false) {
        self.id = UUID()
        self.order = order
        self.weight = weight
        self.reps = reps
        self.isDropSet = isDropSet
        self.isTopSet = isTopSet
        self.completedAt = nil
    }

    var volume: Double {
        weight * Double(reps)
    }

    /// Epley 공식: 1RM = weight × (1 + reps / 30)
    var estimatedOneRepMax: Double {
        guard reps > 0, weight > 0 else { return 0 }
        if reps == 1 { return weight }
        return weight * (1.0 + Double(reps) / 30.0)
    }
}
