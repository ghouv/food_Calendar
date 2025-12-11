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

    struct DailySummary: Identifiable {
        let id = UUID()
        let date: Date
        let totalCalories: Int
        let totalCarbs: Int
        let totalProtein: Int
        let totalFat: Int
    }

    @Published var selectedDate: Date {
        didSet {
            let normalized = calendar.startOfDay(for: selectedDate)
            if normalized != selectedDate {
                selectedDate = normalized
                return
            }

            if !calendar.isDate(normalized, inSameDayAs: oldValue) {
                fetchMealsForSelectedDate()
            }
        }
    }
    @Published var mealsForSelectedDate: [MealEntity] = []
    @Published var filteredMealsForSelectedDate: [MealEntity] = []
    var goal: HealthGoal = .maintain
    let targetCaloriesPerDay: Int = 2000

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

    var goalCalories: Int {
        CalorieGoalManager.dailyGoal
    }

    var dailyProgress: Double {
        guard goalCalories > 0 else { return 0 }
        return Double(totalCalories) / Double(goalCalories)
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

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext, date: Date = Date()) {
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
        meal.eatenAt = calendar.startOfDay(for: selectedDate)
        meal.isFavorite = false

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
        let meals = offsets.map { filteredMealsForSelectedDate[$0] }
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

    func toggleFavorite(for meal: MealEntity) {
        meal.isFavorite.toggle()
        do {
            try context.save()
            fetchMealsForSelectedDate()
        } catch {
            context.rollback()
            print("Failed to toggle favorite: \(error.localizedDescription)")
        }
    }

    func favoriteMeals() -> [MealEntity] {
        let request: NSFetchRequest<MealEntity> = MealEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isFavorite == %@", NSNumber(value: true))
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \MealEntity.name, ascending: true),
            NSSortDescriptor(keyPath: \MealEntity.eatenAt, ascending: false)
        ]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch favorites: \(error.localizedDescription)")
            return []
        }
    }

    func allMeals() -> [MealEntity] {
        let request: NSFetchRequest<MealEntity> = MealEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MealEntity.eatenAt, ascending: false)]
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch meals: \(error.localizedDescription)")
            return []
        }
    }

    func addMeal(from favorite: MealEntity) {
        let meal = MealEntity(context: context)
        meal.id = UUID()
        meal.name = favorite.name
        meal.calories = favorite.calories
        meal.carbs = favorite.carbs
        meal.protein = favorite.protein
        meal.fat = favorite.fat
        meal.isFavorite = false
        meal.eatenAt = calendar.startOfDay(for: selectedDate)

        do {
            try context.save()
            fetchMealsForSelectedDate()
        } catch {
            context.rollback()
            print("Failed to add meal from favorite: \(error.localizedDescription)")
        }
    }

    func removeFavorites(at offsets: IndexSet, from favorites: [MealEntity]) {
        for index in offsets {
            let meal = favorites[index]
            meal.isFavorite = false
        }

        do {
            try context.save()
            fetchMealsForSelectedDate()
        } catch {
            context.rollback()
            print("Failed to remove favorites: \(error.localizedDescription)")
        }
    }

    func changeSelectedDate(by days: Int) {
        if let newDate = calendar.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
            fetchMealsForSelectedDate()
        }
    }

    func goTo(date: Date) {
        selectedDate = calendar.startOfDay(for: date)
        fetchMealsForSelectedDate()
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

    func weekDates(for date: Date) -> [Date] {
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }

    private func fetchMealsForSelectedDate() {
        mealsForSelectedDate = fetchMeals(on: selectedDate)
        filteredMealsForSelectedDate = mealsForSelectedDate
    }

    private func fetchMeals(on date: Date) -> [MealEntity] {
        let request: NSFetchRequest<MealEntity> = MealEntity.fetchRequest()
        let bounds = dayRange(for: date)

        request.predicate = NSPredicate(format: "(eatenAt >= %@) AND (eatenAt < %@)", bounds.start as NSDate, bounds.end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MealEntity.eatenAt, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch meals: \(error.localizedDescription)")
            return []
        }
    }

    private func dayRange(for date: Date) -> (start: Date, end: Date) {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return (start, end)
    }

    /// 최근 n일 동안의 일별 요약 데이터 (오늘 포함, 과거 방향)
    func dailySummaries(forLast days: Int) -> [DailySummary] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var result: [DailySummary] = []

        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let startOfDay = calendar.startOfDay(for: day)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }

            let mealsForDay = fetchMeals(on: startOfDay).filter { meal in
                guard let eatenAt = meal.eatenAt else { return false }
                return eatenAt >= startOfDay && eatenAt < endOfDay
            }

            let totalCalories = mealsForDay.reduce(0) { $0 + Int($1.calories) }
            let totalCarbs = mealsForDay.reduce(0) { $0 + Int($1.carbs) }
            let totalProtein = mealsForDay.reduce(0) { $0 + Int($1.protein) }
            let totalFat = mealsForDay.reduce(0) { $0 + Int($1.fat) }

            let summary = DailySummary(
                date: startOfDay,
                totalCalories: totalCalories,
                totalCarbs: totalCarbs,
                totalProtein: totalProtein,
                totalFat: totalFat
            )
            result.append(summary)
        }

        return result.sorted { $0.date < $1.date }
    }

    func totalCalories(in summaries: [DailySummary]) -> Int {
        summaries.reduce(0) { $0 + $1.totalCalories }
    }

    func macroTotals(in summaries: [DailySummary]) -> (carbs: Int, protein: Int, fat: Int) {
        let carbs = summaries.reduce(0) { $0 + $1.totalCarbs }
        let protein = summaries.reduce(0) { $0 + $1.totalProtein }
        let fat = summaries.reduce(0) { $0 + $1.totalFat }
        return (carbs, protein, fat)
    }

    func clearSearchFilter() {
        filteredMealsForSelectedDate = mealsForSelectedDate
    }

    func applySearchFilter(with keyword: String) {
        let lowercased = keyword.lowercased()
        filteredMealsForSelectedDate = mealsForSelectedDate.filter { meal in
            let name = (meal.name ?? "").lowercased()
            return name.contains(lowercased)
        }
    }

    func copyMealToToday(_ meal: MealEntity) {
        let newMeal = MealEntity(context: context)
        newMeal.id = UUID()
        newMeal.name = meal.name
        newMeal.calories = meal.calories
        newMeal.carbs = meal.carbs
        newMeal.protein = meal.protein
        newMeal.fat = meal.fat
        newMeal.eatenAt = calendar.startOfDay(for: Date())
        newMeal.isFavorite = false

        do {
            try context.save()
            fetchMealsForSelectedDate()
        } catch {
            context.rollback()
            print("Failed to copy meal to today: \\(error.localizedDescription)")
        }
    }
}
