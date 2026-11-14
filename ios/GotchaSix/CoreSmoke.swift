import Foundation

/// Touches the UniFFI surface so the Xcode link of `libgotcha_six_core.a` is real.
enum CoreSmoke {
    @discardableResult
    static func touch() -> Int {
        let engine = UniffiRadarEngine()
        engine.reset()
        return radarPresetCommands().count
    }
}
