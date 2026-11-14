import ActivityKit
import Foundation

/// Shared between the app and the Live Activity extension.
struct GotchaSixActivityAttributes: ActivityAttributes {
    /// Fixed for the life of one session activity.
    public struct ContentState: Codable, Hashable {
        var connection: String
        var motion: String
        var distanceLabel: String
    }

    /// Unused fixed attributes; ActivityKit requires a non-empty outer type.
    var sessionId: String
}

extension GotchaSixActivityAttributes.ContentState {
    static let placeholder = Self(
        connection: "Connected",
        motion: "None",
        distanceLabel: "None"
    )

    static func disconnected() -> Self {
        Self(connection: "Disconnected", motion: "None", distanceLabel: "None")
    }
}
