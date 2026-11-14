import Foundation
import SwiftUI

enum AppRoute: Hashable {
    case welcome
    case permissions
    case howToA
    case howToB
    case howToC
    case findDevice
    case home
}

@MainActor
final class OnboardingStore: ObservableObject {
    private static let completedKey = "gotchaSix.firstRunCompleted"

    @Published var route: AppRoute
    @Published var replayingHowTo = false

    init() {
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

    func finishFindDevice() {
        UserDefaults.standard.set(true, forKey: Self.completedKey)
        route = .home
    }

    func replayHowTo() {
        replayingHowTo = true
        route = .howToA
    }
}
