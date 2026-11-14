import Foundation

/// Plays lab-format fixture lines into `UniffiRadarEngine` on the fixture clock.
@MainActor
final class FixturePlayer: ObservableObject {
    struct LineEvent {
        let tMs: UInt64
        let line: String
    }

    @Published private(set) var lastMotion: String = "unknown"
    @Published private(set) var lastDistanceM: Double?
    @Published private(set) var isFinished = false
    @Published private(set) var isPlaying = false
    @Published private(set) var errorMessage: String?

    private var events: [LineEvent] = []
    private var playTask: Task<Void, Never>?
    private let engine = UniffiRadarEngine()

    var radarEngine: UniffiRadarEngine { engine }

    func load(_ scenario: FixtureScenario) throws {
        stop()
        errorMessage = nil
        isFinished = false
        lastMotion = "unknown"
        lastDistanceM = nil

        guard let url = Bundle.main.url(forResource: scenario.resourceName, withExtension: "txt") else {
            throw FixturePlayerError.missingResource(scenario.resourceName)
        }
        let text = try String(contentsOf: url, encoding: .utf8)
        events = Self.parse(text)
        if events.isEmpty {
            throw FixturePlayerError.emptyFixture(scenario.resourceName)
        }
    }

    func start(speed: Double = 1.0) {
        stop()
        guard !events.isEmpty else { return }
        engine.reset()
        isPlaying = true
        isFinished = false
        let speed = max(speed, 0.01)
        let events = self.events
        playTask = Task { [weak self] in
            var lastT: UInt64 = 0
            for event in events {
                if Task.isCancelled { return }
                let deltaMs = event.tMs >= lastT ? event.tMs - lastT : 0
                lastT = event.tMs
                let waitNs = UInt64(Double(deltaMs) * 1_000_000.0 / speed)
                if waitNs > 0 {
                    try? await Task.sleep(nanoseconds: waitNs)
                }
                if Task.isCancelled { return }
                await self?.push(line: event.line)
            }
            await MainActor.run {
                self?.isPlaying = false
                self?.isFinished = true
            }
        }
    }

    func stop() {
        playTask?.cancel()
        playTask = nil
        isPlaying = false
    }

    private func push(line: String) {
        var bytes = Array(line.utf8)
        bytes.append(UInt8(ascii: "\n"))
        let outs = engine.pushBytes(data: Data(bytes))
        for out in outs where out.kind == "target" || out.kind == "presence" {
            lastMotion = out.motion
            if let d = out.distanceM {
                lastDistanceM = Double(d)
            }
            if out.motion == "lost" {
                lastDistanceM = nil
            }
        }
    }

    static func parse(_ text: String) -> [LineEvent] {
        var out: [LineEvent] = []
        for raw in text.split(whereSeparator: \.isNewline) {
            let line = String(raw)
            if line.isEmpty { continue }
            let (tMs, payload) = stripTimePrefix(line)
            out.append(LineEvent(tMs: tMs, line: payload))
        }
        return out
    }

    /// Mirror of core `strip_time_prefix`: `<t_ms>\t<raw>` or plain line at t=0.
    static func stripTimePrefix(_ line: String) -> (UInt64, String) {
        guard let tab = line.firstIndex(of: "\t") else {
            return (0, line)
        }
        let tPart = line[..<tab]
        let rest = String(line[line.index(after: tab)...])
        if let t = Double(tPart), t >= 0 {
            return (UInt64(t), rest)
        }
        return (0, line)
    }
}

enum FixturePlayerError: LocalizedError {
    case missingResource(String)
    case emptyFixture(String)

    var errorDescription: String? {
        switch self {
        case .missingResource(let name):
            return "Missing fixture \(name).txt in the app bundle."
        case .emptyFixture(let name):
            return "Fixture \(name).txt has no lines."
        }
    }
}
