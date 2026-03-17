import Foundation
import SwiftData

@Model
class Exercise {
    var id: UUID
    var name: String
    var muscleGroup: MuscleGroup
    var instructions: String
    var isCustom: Bool

    @Relationship(deleteRule: .deny, inverse: \WorkoutEntry.exercise)
    var entries: [WorkoutEntry] = []

    init(name: String, muscleGroup: MuscleGroup, instructions: String = "", isCustom: Bool = false) {
        self.id = UUID()
        self.name = name
        self.muscleGroup = muscleGroup
        self.instructions = instructions
        self.isCustom = isCustom
    }
}
