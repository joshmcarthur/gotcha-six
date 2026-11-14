import SwiftUI

struct CalibrationView: View {
    @EnvironmentObject private var onboarding: OnboardingStore
    @EnvironmentObject private var radar: RadarLink
    @StateObject private var player = FixturePlayer()
    @StateObject private var model = CalibrationModel()
    @State private var scenario: FixtureScenario = .wallPass
    @State private var loadError: String?
    @State private var liveRunning = false

    private var useLive: Bool { radar.isConnected }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Calibration")
                .font(.largeTitle.weight(.bold))
            Text(instructionCopy)
                .font(.body)
                .foregroundStyle(.secondary)

            TeachingImage(name: "TeachingCalibration")
                .frame(height: 160)

            readout

            switch model.outcome {
            case .running:
                controlsRunning
            case .passed:
                Text("The radar saw the close. You’re ready.")
                    .font(.body.weight(.semibold))
                Button("Continue") {
                    finish(passed: true)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            case .failed:
                Text(failCopy)
                    .font(.body)
                HStack {
                    if useLive {
                        Button("Try again") {
                            startLive()
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button("Try wall pass") {
                            startDemo(scenario: .wallPass)
                        }
                        .buttonStyle(.bordered)
                    }
                    Button("Skip for now") {
                        finish(passed: false)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            if let loadError {
                Text(loadError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .onChange(of: player.lastMotion) { _, _ in observeDemo() }
        .onChange(of: player.lastDistanceM) { _, _ in observeDemo() }
        .onChange(of: player.isFinished) { _, _ in observeDemo() }
        .onChange(of: radar.lastMotion) { _, _ in observeLive() }
        .onChange(of: radar.lastDistanceM) { _, _ in observeLive() }
        .onDisappear {
            player.stop()
            model.stopTimeout()
            liveRunning = false
        }
    }

    private var instructionCopy: String {
        if useLive {
            return "Stand about 4–5 m from a wall, back to the wall, radar facing the wall. Tap Start, then take two or three steps backward."
        }
        return "Demo mode: stand as if at a wall, or just tap Start to play a recorded step-back."
    }

    private var failCopy: String {
        if useLive {
            return "No close-up on the wall. Check the radar faces backward, then try again."
        }
        return "No close-up on the wall. In demo, try Wall pass — or skip for now."
    }

    private var readout: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Motion")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(motionLabel.capitalized)
                    .font(.title3.weight(.semibold))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Distance")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(distanceLabel)
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
            }
        }
        .padding(16)
        .background(Color("AccentColor").opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var motionLabel: String {
        useLive && liveRunning ? radar.lastMotion : player.lastMotion
    }

    private var distanceLabel: String {
        let d: Double? = useLive && liveRunning ? radar.lastDistanceM : player.lastDistanceM
        if let d {
            return String(format: "%.1f m", d)
        }
        return "—"
    }

    @ViewBuilder
    private var controlsRunning: some View {
        if useLive {
            if liveRunning {
                Text("Watching for approaching… (20 s)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("I’m done") {
                    // Keep running until pass/timeout; explicit stop is skip-like fail path.
                    model.stopTimeout()
                    if model.outcome == .running {
                        model.outcome = .failed
                    }
                    liveRunning = false
                }
                .buttonStyle(.bordered)
            } else {
                Button("Start") { startLive() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                Button("Skip for now") {
                    finish(passed: false)
                }
                .buttonStyle(.borderless)
            }
        } else if player.isPlaying {
            Text(scenario == .wallFail ? "Playing wall fail…" : "Playing wall pass…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Stop") { player.stop() }
                .buttonStyle(.bordered)
        } else {
            HStack(spacing: 12) {
                Button("Start") { startDemo(scenario: .wallPass) }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                Button("Play fail") { startDemo(scenario: .wallFail) }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }
            Button("Skip for now") {
                finish(passed: false)
            }
            .buttonStyle(.borderless)
        }
    }

    private func observeDemo() {
        guard !useLive else { return }
        model.observe(
            motion: player.lastMotion,
            distanceM: player.lastDistanceM,
            isFinished: player.isFinished
        )
    }

    private func observeLive() {
        guard useLive, liveRunning else { return }
        model.observe(
            motion: radar.lastMotion,
            distanceM: radar.lastDistanceM,
            isFinished: false
        )
    }

    private func startLive() {
        loadError = nil
        player.stop()
        model.reset()
        liveRunning = true
        model.startTimeout(seconds: 20)
    }

    private func startDemo(scenario: FixtureScenario) {
        self.scenario = scenario
        liveRunning = false
        model.reset()
        do {
            try player.load(scenario)
            let speed = scenario == .wallFail ? 40.0 : 8.0
            player.start(speed: speed)
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func finish(passed: Bool) {
        player.stop()
        model.stopTimeout()
        liveRunning = false
        if useLive {
            onboarding.completeLiveCalibration(passed: passed)
        } else {
            onboarding.completeDemoCalibration(passed: passed)
        }
    }
}
