import Foundation

struct Meal: Identifiable {
    let id: UUID
    var name: String
    var calories: Int
    var carbs: Int
    var protein: Int
    var fat: Int
    var eatenAt: Date

    init(id: UUID = UUID(), name: String, calories: Int, carbs: Int, protein: Int, fat: Int, eatenAt: Date) {
        self.id = id
        self.name = name
        self.calories = calories
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.eatenAt = eatenAt
    }
}
