import Foundation

struct CalorieGoalManager {
    private static let key = "DailyCalorieGoal"

    /// Returns the stored daily calorie goal.
    /// If there is no stored value yet, return a reasonable default such as 1800.
    static var dailyGoal: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: key)
            return stored == 0 ? 1800 : stored
        }
        set {
            // Ignore invalid (non-positive) values.
            guard newValue > 0 else { return }
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}
