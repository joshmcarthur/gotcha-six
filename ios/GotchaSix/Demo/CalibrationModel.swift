import Foundation

enum CalibrationOutcome: Equatable {
    case running
    case passed
    case failed
}

/// Watches motion/distance for calibration pass/fail (demo fixtures or live BLE).
@MainActor
final class CalibrationModel: ObservableObject {
    @Published var outcome: CalibrationOutcome = .running
    @Published var startDistanceM: Double?

    private let passCloserM: Double = 1.0
    private var timeoutTask: Task<Void, Never>?

    func reset() {
        timeoutTask?.cancel()
        timeoutTask = nil
        outcome = .running
        startDistanceM = nil
    }

    /// Live wall calibration: fail after `seconds` with no pass.
    func startTimeout(seconds: TimeInterval = 20) {
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard let self, !Task.isCancelled else { return }
            if self.outcome == .running {
                self.outcome = .failed
            }
        }
    }

    func stopTimeout() {
        timeoutTask?.cancel()
        timeoutTask = nil
    }

    func observe(motion: String, distanceM: Double?, isFinished: Bool = false) {
        guard outcome == .running else { return }

        if startDistanceM == nil, let d = distanceM {
            startDistanceM = d
        }

        if motion == "approaching",
           let start = startDistanceM,
           let d = distanceM,
           start - d >= passCloserM
        {
            stopTimeout()
            outcome = .passed
            return
        }

        // Demo fixtures: fail when the scenario ends without a pass.
        if isFinished, outcome == .running {
            stopTimeout()
            outcome = .failed
        }
    }
}
