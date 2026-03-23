import Foundation
import SwiftData

@Model
class WorkoutEntry {
    var id: UUID
    var order: Int

    var exercise: Exercise?
    var session: WorkoutSession?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.entry)
    var sets: [WorkoutSet] = []

    init(order: Int, exercise: Exercise? = nil, session: WorkoutSession? = nil) {
        self.id = UUID()
        self.order = order
        self.exercise = exercise
        self.session = session
    }

    var sortedSets: [WorkoutSet] {
        sets.sorted { $0.order < $1.order }
    }

    var isOneArm: Bool {
        guard let name = exercise?.name else { return false }
        return name.contains("원암") || name.contains("싱글")
    }

    var totalVolume: Double {
        let raw = sets.reduce(0) { $0 + $1.weight * Double($1.reps) }
        return isOneArm ? raw * 2 : raw
    }

    var maxWeight: Double {
        sets.map(\.weight).max() ?? 0
    }
}
