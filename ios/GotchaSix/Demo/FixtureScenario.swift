import Foundation

enum FixtureScenario: String, CaseIterable, Identifiable {
    case wallPass = "wall_pass"
    case wallFail = "wall_fail"
    case alertApproach = "alert_approach"

    var id: String { rawValue }

    var resourceName: String { rawValue }

    var title: String {
        switch self {
        case .wallPass: return "Wall pass"
        case .wallFail: return "Wall fail"
        case .alertApproach: return "Approaching alert"
        }
    }

    var detail: String {
        switch self {
        case .wallPass: return "Step-back succeeds — approaching"
        case .wallFail: return "No close-up — timeout fail"
        case .alertApproach: return "Short closing target"
        }
    }
}
