import Foundation
import SwiftData

@Model
class WorkoutSession {
    #Index<WorkoutSession>([\.startDate])

    var id: UUID
    var startDate: Date
    var endDate: Date?
    var notes: String

    @Relationship(deleteRule: .cascade, inverse: \WorkoutEntry.session)
    var entries: [WorkoutEntry] = []

    init(startDate: Date = .now, notes: String = "") {
        self.id = UUID()
        self.startDate = startDate
        self.notes = notes
    }

    var duration: TimeInterval? {
        guard let endDate else { return nil }
        return endDate.timeIntervalSince(startDate)
    }

    var totalVolume: Double {
        entries.reduce(0) { total, entry in
            total + entry.sets.reduce(0) { setTotal, set in
                setTotal + set.weight * Double(set.reps)
            }
        }
    }

    var exerciseCount: Int {
        entries.count
    }

    var totalSets: Int {
        entries.reduce(0) { $0 + $1.sets.filter { $0.weight > 0 || $0.reps > 0 }.count }
    }

    var sortedEntries: [WorkoutEntry] {
        entries.sorted { $0.order < $1.order }
    }
}
