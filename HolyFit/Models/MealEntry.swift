import Foundation
import SwiftData

@Model
class MealEntry {
    #Index<MealEntry>([\.date])

    var id: UUID
    var date: Date
    var category: MealCategory
    var foodName: String
    var calories: Int?
    var protein: Double?
    var carbs: Double?
    var fat: Double?
    var memo: String

    init(
        date: Date = .now,
        category: MealCategory,
        foodName: String,
        calories: Int? = nil,
        protein: Double? = nil,
        carbs: Double? = nil,
        fat: Double? = nil,
        memo: String = ""
    ) {
        self.id = UUID()
        self.date = date
        self.category = category
        self.foodName = foodName
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.memo = memo
    }
}
