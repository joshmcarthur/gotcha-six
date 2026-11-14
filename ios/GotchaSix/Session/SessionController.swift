import ActivityKit
import Combine
import Foundation
import UIKit
import UserNotifications

/// Owns Start/End session, Live Activity updates, and approaching interrupts.
@MainActor
final class SessionController: ObservableObject {
    @Published private(set) var isSessionOn = false
    @Published private(set) var lastError: String?

    private let radar: RadarLink
    private var activity: Activity<GotchaSixActivityAttributes>?
    private var cancellables = Set<AnyCancellable>()
    private var dropTimer: Task<Void, Never>?
    private var lastActivityPush = Date.distantPast
    private var lastPushedMotion = ""
    private var lastPushedDistance: Double?
    private var lastPushedConnected = false
    private var lastAlertSequence: UInt64 = 0
    private var didNotifyDisconnect = false
    private let dropTimeoutSeconds: TimeInterval = 300
    private let minActivityInterval: TimeInterval = 1.0
    private let minDistanceDeltaM: Double = 0.5

    init(radar: RadarLink) {
        self.radar = radar
        bind()
    }

    func startSession() {
        lastError = nil
        guard radar.isConnected else {
            lastError = "Connect a Gotcha Six unit before starting a session."
            return
        }
        radar.beginSessionParsing()
        isSessionOn = true
        didNotifyDisconnect = false
        dropTimer?.cancel()
        lastAlertSequence = radar.alertSequence
        startActivity()
        pushActivity(force: true)
    }

    func endSession() {
        dropTimer?.cancel()
        dropTimer = nil
        isSessionOn = false
        didNotifyDisconnect = false
        radar.endSessionParsing()
        endActivity()
    }

    private func bind() {
        radar.$phase
            .receive(on: RunLoop.main)
            .sink { [weak self] phase in
                self?.handlePhase(phase)
            }
            .store(in: &cancellables)

        radar.$lastMotion
            .combineLatest(radar.$lastDistanceM, radar.$hasTarget)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _, _ in
                self?.pushActivity(force: false)
            }
            .store(in: &cancellables)

        radar.$alertSequence
            .receive(on: RunLoop.main)
            .sink { [weak self] seq in
                self?.handleAlertSequence(seq)
            }
            .store(in: &cancellables)
    }

    private func handlePhase(_ phase: RadarLink.Phase) {
        guard isSessionOn else { return }
        switch phase {
        case .connected:
            dropTimer?.cancel()
            dropTimer = nil
            didNotifyDisconnect = false
            radar.rearmSessionParsing()
            pushActivity(force: true)
        case .connecting, .scanning:
            pushActivity(force: true)
        case .idle, .failed, .poweredOff, .unauthorized, .unknown:
            pushActivity(force: true)
            if !didNotifyDisconnect {
                didNotifyDisconnect = true
                Task { await notifyLinkDrop() }
            }
            if radar.storedPeripheralId != nil, phase != .connecting, phase != .scanning {
                radar.reconnectStored()
            }
            startDropTimeoutIfNeeded()
        }
    }

    private func startDropTimeoutIfNeeded() {
        guard dropTimer == nil else { return }
        dropTimer = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(self?.dropTimeoutSeconds ?? 300) * 1_000_000_000)
            guard let self, !Task.isCancelled, self.isSessionOn, !self.radar.isConnected else { return }
            self.endSession()
        }
    }

    private func handleAlertSequence(_ seq: UInt64) {
        guard isSessionOn, seq > lastAlertSequence else { return }
        lastAlertSequence = seq
        let distance = radar.lastAlertDistanceM
        Task { await fireApproachingAlert(distanceM: distance) }
        pushActivity(force: true)
    }

    private func startActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            lastError = "Live Activities are disabled in Settings."
            return
        }
        let attributes = GotchaSixActivityAttributes(sessionId: UUID().uuidString)
        let state = currentContentState()
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func endActivity() {
        let activity = self.activity
        self.activity = nil
        guard let activity else { return }
        let finalState = currentContentState()
        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
    }

    private func pushActivity(force: Bool) {
        guard isSessionOn, let activity else { return }
        let state = currentContentState()
        let connected = radar.isConnected
        let motion = state.motion
        let distance = radar.hasTarget ? radar.lastDistanceM : nil

        let connectionChanged = connected != lastPushedConnected
        let motionChanged = motion != lastPushedMotion
        let distanceChanged: Bool = {
            switch (distance, lastPushedDistance) {
            case let (l?, r?):
                return abs(l - r) >= minDistanceDeltaM
            case (nil, nil):
                return false
            default:
                return true
            }
        }()
        let due = Date().timeIntervalSince(lastActivityPush) >= minActivityInterval
        guard force || connectionChanged || ((motionChanged || distanceChanged) && due) else {
            return
        }

        lastActivityPush = Date()
        lastPushedConnected = connected
        lastPushedMotion = motion
        lastPushedDistance = distance

        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    private func currentContentState() -> GotchaSixActivityAttributes.ContentState {
        let connection = radar.isConnected ? "Connected" : "Disconnected"
        let motion: String = {
            if !radar.isConnected { return "None" }
            if !radar.hasTarget { return displayMotion(radar.lastMotion) == "Lost" ? "None" : capitalize(radar.lastMotion) }
            return capitalize(radar.lastMotion)
        }()
        let distanceLabel: String = {
            if !radar.isConnected { return "None" }
            guard radar.hasTarget, let d = radar.lastDistanceM else { return "None" }
            return String(format: "%.0f m", d)
        }()
        return .init(connection: connection, motion: motion == "none" ? "None" : motion, distanceLabel: distanceLabel)
    }

    private func capitalize(_ raw: String) -> String {
        guard let first = raw.first else { return "None" }
        return String(first).uppercased() + raw.dropFirst()
    }

    private func displayMotion(_ raw: String) -> String {
        capitalize(raw)
    }

    private func fireApproachingAlert(distanceM: Double?) async {
        let body: String = {
            if let distanceM {
                return String(format: "Approaching · %.0f m", distanceM)
            }
            return "Approaching"
        }()

        if UIApplication.shared.applicationState == .active {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
        }

        await postTimeSensitive(title: "Gotcha Six", body: body)
    }

    private func notifyLinkDrop() async {
        await postTimeSensitive(title: "Gotcha Six", body: "Unit disconnected. Reconnecting…")
    }

    private func postTimeSensitive(title: String, body: String) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: "gotcha-six-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        try? await center.add(request)
    }
}
