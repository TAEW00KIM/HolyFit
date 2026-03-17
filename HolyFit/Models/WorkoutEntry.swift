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

    var totalVolume: Double {
        sets.reduce(0) { $0 + $1.weight * Double($1.reps) }
    }

    var maxWeight: Double {
        sets.map(\.weight).max() ?? 0
    }
}
