import Foundation

enum HealthGoal {
    case loseWeight
    case bulkUp
    case maintain

    var targetCalories: Int {
        switch self {
        case .loseWeight:
            return 1800
        case .bulkUp:
            return 2600
        case .maintain:
            return 2200
        }
    }
}
