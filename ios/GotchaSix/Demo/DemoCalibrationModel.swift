import Foundation

enum CalibrationOutcome: Equatable {
    case running
    case passed
    case failed
}

/// Watches fixture playback for calibration pass/fail.
@MainActor
final class DemoCalibrationModel: ObservableObject {
    @Published var outcome: CalibrationOutcome = .running
    @Published var startDistanceM: Double?

    private let passCloserM: Double = 1.0

    func reset() {
        outcome = .running
        startDistanceM = nil
    }

    func observe(motion: String, distanceM: Double?, isFinished: Bool) {
        guard outcome == .running else { return }

        if startDistanceM == nil, let d = distanceM {
            startDistanceM = d
        }

        if motion == "approaching",
           let start = startDistanceM,
           let d = distanceM,
           start - d >= passCloserM
        {
            outcome = .passed
            return
        }

        // Fail when the fail scenario (or pass scenario) ends without a pass.
        if isFinished, outcome == .running {
            outcome = .failed
        }
    }
}
