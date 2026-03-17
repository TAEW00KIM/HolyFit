import Foundation
import SwiftData

@Model
class TemplateEntry {
    var id: UUID
    var order: Int
    var defaultSets: Int
    var defaultWeight: Double
    var defaultReps: Int

    var exercise: Exercise?
    var template: WorkoutTemplate?

    init(order: Int, exercise: Exercise? = nil, template: WorkoutTemplate? = nil,
         defaultSets: Int = 3, defaultWeight: Double = 0, defaultReps: Int = 10) {
        self.id = UUID()
        self.order = order
        self.exercise = exercise
        self.template = template
        self.defaultSets = defaultSets
        self.defaultWeight = defaultWeight
        self.defaultReps = defaultReps
    }
}
