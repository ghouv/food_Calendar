import Foundation
import CoreData

@MainActor
final class TodayMealsViewModel: ObservableObject {
    struct DailyCaloriesData: Identifiable {
        let id = UUID()
        let date: Date
        let calories: Int
    }

    struct MacroTotalData: Identifiable {
        let id = UUID()
        let name: String
        let grams: Int
    }

    @Published var selectedDate: Date
    @Published var mealsForSelectedDate: [MealEntity] = []
    var goal: HealthGoal = .maintain

    private let context: NSManagedObjectContext
    private let calendar = Calendar.current

    var totalCalories: Int {
        mealsForSelectedDate.reduce(0) { $0 + Int($1.calories) }
    }

    var totalCarbs: Int {
        mealsForSelectedDate.reduce(0) { $0 + Int($1.carbs) }
    }

    var totalProtein: Int {
        mealsForSelectedDate.reduce(0) { $0 + Int($1.protein) }
    }

    var totalFat: Int {
        mealsForSelectedDate.reduce(0) { $0 + Int($1.fat) }
    }

    var statusMessage: String {
        let target = goal.targetCalories
        if totalCalories < target - 200 {
            return "오늘은 아직 조금 더 먹어도 괜찮아요."
        } else if totalCalories > target + 200 {
            return "오늘은 칼로리가 살짝 많아요. 다음 끼니를 조절해 볼까요?"
        } else {
            return "목표에 잘 맞게 드시고 있어요."
        }
    }

    init(context: NSManagedObjectContext, date: Date = Date()) {
        self.context = context
        self.selectedDate = date
        fetchMealsForSelectedDate()
    }

    func addMeal(name: String, calories: Int, carbs: Int, protein: Int, fat: Int) {
        let meal = MealEntity(context: context)
        meal.id = UUID()
        meal.name = name
        meal.calories = Int64(calories)
        meal.carbs = Int64(carbs)
        meal.protein = Int64(protein)
        meal.fat = Int64(fat)
        meal.eatenAt = selectedDate

        do {
            try context.save()
            fetchMealsForSelectedDate()
        } catch {
            context.rollback()
            print("Failed to save meal: \(error.localizedDescription)")
        }
    }

    func deleteMeal(_ meal: MealEntity) {
        context.delete(meal)

        do {
            try context.save()
            fetchMealsForSelectedDate()
        } catch {
            context.rollback()
            print("Failed to delete meal: \(error.localizedDescription)")
        }
    }

    func deleteMeals(at offsets: IndexSet) {
        let meals = offsets.map { mealsForSelectedDate[$0] }
        meals.forEach { deleteMeal($0) }
    }

    func updateMeal(_ meal: MealEntity, name: String, calories: Int, carbs: Int, protein: Int, fat: Int) {
        meal.name = name
        meal.calories = Int64(calories)
        meal.carbs = Int64(carbs)
        meal.protein = Int64(protein)
        meal.fat = Int64(fat)

        do {
            try context.save()
            fetchMealsForSelectedDate()
        } catch {
            context.rollback()
            print("Failed to update meal: \(error.localizedDescription)")
        }
    }

    func changeSelectedDate(by days: Int) {
        if let newDate = calendar.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
            fetchMealsForSelectedDate()
        }
    }

    func meals(on date: Date) -> [MealEntity] {
        fetchMeals(on: date)
    }

    func calories(on date: Date) -> Int {
        meals(on: date).reduce(0) { $0 + Int($1.calories) }
    }

    func totalCalories(on date: Date) -> Int {
        calories(on: date)
    }

    func totalCarbs(on date: Date) -> Int {
        meals(on: date).reduce(0) { $0 + Int($1.carbs) }
    }

    func totalProtein(on date: Date) -> Int {
        meals(on: date).reduce(0) { $0 + Int($1.protein) }
    }

    func totalFat(on date: Date) -> Int {
        meals(on: date).reduce(0) { $0 + Int($1.fat) }
    }

    func last7DaysCalories() -> [DailyCaloriesData] {
        let days = (0..<7).compactMap { offset -> DailyCaloriesData in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: selectedDate) else {
                return DailyCaloriesData(date: Date(), calories: 0)
            }
            return DailyCaloriesData(date: day, calories: totalCalories(on: day))
        }
        return days.sorted { $0.date < $1.date }
    }

    func macrosForSelectedDate() -> [MacroTotalData] {
        let meals = meals(on: selectedDate)
        let carbs = meals.reduce(0) { $0 + Int($1.carbs) }
        let protein = meals.reduce(0) { $0 + Int($1.protein) }
        let fat = meals.reduce(0) { $0 + Int($1.fat) }

        return [
            MacroTotalData(name: "탄수화물", grams: carbs),
            MacroTotalData(name: "단백질", grams: protein),
            MacroTotalData(name: "지방", grams: fat)
        ]
    }

    private func fetchMealsForSelectedDate() {
        mealsForSelectedDate = fetchMeals(on: selectedDate)
    }

    private func fetchMeals(on date: Date) -> [MealEntity] {
        let request: NSFetchRequest<MealEntity> = MealEntity.fetchRequest()
        guard let bounds = dayBounds(for: date) else { return [] }

        request.predicate = NSPredicate(format: "(eatenAt >= %@) AND (eatenAt < %@)", bounds.start as NSDate, bounds.end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MealEntity.eatenAt, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch meals: \(error.localizedDescription)")
            return []
        }
    }

    private func dayBounds(for date: Date) -> (start: Date, end: Date)? {
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }
        return (startOfDay, endOfDay)
    }
}
