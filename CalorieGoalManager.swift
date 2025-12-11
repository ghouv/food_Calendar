import Foundation

struct CalorieGoalManager {
    private static let key = "DailyCalorieGoal"

    static var dailyGoal: Int {
        let stored = UserDefaults.standard.integer(forKey: key)
        return stored == 0 ? 1800 : stored
    }

    static func setGoal(_ value: Int) {
        UserDefaults.standard.set(value, forKey: key)
    }
}
