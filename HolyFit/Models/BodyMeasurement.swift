import Foundation
import SwiftData

@Model
class BodyMeasurement {
    #Index<BodyMeasurement>([\.date])

    var id: UUID
    var date: Date
    var weight: Double
    var muscleMass: Double?
    var bodyFatPercentage: Double?
    var bmi: Double?

    init(
        date: Date = .now,
        weight: Double,
        muscleMass: Double? = nil,
        bodyFatPercentage: Double? = nil,
        bmi: Double? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.weight = weight
        self.muscleMass = muscleMass
        self.bodyFatPercentage = bodyFatPercentage
        self.bmi = bmi
    }
}
