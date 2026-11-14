import Foundation
import SwiftUI

enum AppRoute: Hashable {
    case welcome
    case permissions
    case howToA
    case howToB
    case howToC
    case findDevice
    case demoSetup
    case setup
    case calibration
    case home
}

enum CalibrationStatus: String {
    case incomplete
    case demoPassed
    case passed
    case skipped
}

@MainActor
final class OnboardingStore: ObservableObject {
    private static let completedKey = "gotchaSix.firstRunCompleted"
    private static let calibrationKey = "gotchaSix.calibrationStatus"

    @Published var route: AppRoute
    @Published var replayingHowTo = false
    @Published var calibrationStatus: CalibrationStatus
    @Published var showDemoPicker = false

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.calibrationKey) ?? CalibrationStatus.incomplete.rawValue
        calibrationStatus = CalibrationStatus(rawValue: raw) ?? .incomplete

        #if DEBUG
        if let forced = Self.routeFromLaunchArguments() {
            route = forced
            return
        }
        #endif
        let done = UserDefaults.standard.bool(forKey: Self.completedKey)
        route = done ? .home : .welcome
    }

    #if DEBUG
    private static func routeFromLaunchArguments() -> AppRoute? {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-route"), args.index(after: idx) < args.endIndex else {
            return nil
        }
        switch args[args.index(after: idx)] {
        case "welcome": return .welcome
        case "permissions": return .permissions
        case "howToA": return .howToA
        case "howToB": return .howToB
        case "howToC": return .howToC
        case "findDevice": return .findDevice
        case "demoSetup": return .demoSetup
        case "setup": return .setup
        case "calibration": return .calibration
        case "home": return .home
        default: return nil
        }
    }
    #endif

    func continueFromWelcome() {
        route = .permissions
    }

    func continueFromPermissions() {
        route = .howToA
    }

    func continueHowTo(from route: AppRoute) {
        switch route {
        case .howToA:
            self.route = .howToB
        case .howToB:
            self.route = .howToC
        case .howToC:
            if replayingHowTo {
                replayingHowTo = false
                self.route = .home
            } else {
                self.route = .findDevice
            }
        default:
            break
        }
    }

    func continueWithoutDevice() {
        setCalibration(.skipped)
        finishOnboardingToHome()
    }

    func startDemoDevice() {
        route = .demoSetup
    }

    func startLiveSetup() {
        route = .setup
    }

    func backToFindDevice() {
        route = .findDevice
    }

    func continueFromDemoSetup() {
        route = .calibration
    }

    func continueFromLiveSetup() {
        route = .calibration
    }

    func completeDemoCalibration(passed: Bool) {
        setCalibration(passed ? .demoPassed : .skipped)
        finishOnboardingToHome()
    }

    func completeLiveCalibration(passed: Bool) {
        setCalibration(passed ? .passed : .skipped)
        finishOnboardingToHome()
    }

    func skipCalibration() {
        setCalibration(.skipped)
        finishOnboardingToHome()
    }

    func openRecalibrate() {
        route = .calibration
    }

    func replayHowTo() {
        replayingHowTo = true
        route = .howToA
    }

    func openDemoPicker() {
        showDemoPicker = true
    }

    private func finishOnboardingToHome() {
        UserDefaults.standard.set(true, forKey: Self.completedKey)
        route = .home
    }

    private func setCalibration(_ status: CalibrationStatus) {
        calibrationStatus = status
        UserDefaults.standard.set(status.rawValue, forKey: Self.calibrationKey)
    }
}
