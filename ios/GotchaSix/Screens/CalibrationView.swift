import SwiftUI

struct CalibrationView: View {
    @EnvironmentObject private var onboarding: OnboardingStore
    @StateObject private var player = FixturePlayer()
    @StateObject private var model = DemoCalibrationModel()
    @State private var scenario: FixtureScenario = .wallPass
    @State private var loadError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Calibration")
                .font(.largeTitle.weight(.bold))
            Text("Stand about 4–5 m from a wall, back to the wall, radar facing the wall. Tap Start, then take two or three steps backward.")
                .font(.body)
                .foregroundStyle(.secondary)

            CalibrationIllustration()
                .frame(maxWidth: .infinity)
                .frame(height: 160)

            readout

            switch model.outcome {
            case .running:
                controlsRunning
            case .passed:
                Text("The radar saw the close. You’re ready.")
                    .font(.body.weight(.semibold))
                Button("Continue") {
                    player.stop()
                    onboarding.completeDemoCalibration(passed: true)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            case .failed:
                Text("No close-up on the wall. In demo, try Wall pass — or skip for now.")
                    .font(.body)
                HStack {
                    Button("Try wall pass") {
                        start(scenario: .wallPass)
                    }
                    .buttonStyle(.bordered)
                    Button("Skip for now") {
                        player.stop()
                        onboarding.skipCalibration()
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
        .onChange(of: player.lastMotion) { _, _ in
            model.observe(
                motion: player.lastMotion,
                distanceM: player.lastDistanceM,
                isFinished: player.isFinished
            )
        }
        .onChange(of: player.lastDistanceM) { _, _ in
            model.observe(
                motion: player.lastMotion,
                distanceM: player.lastDistanceM,
                isFinished: player.isFinished
            )
        }
        .onChange(of: player.isFinished) { _, finished in
            model.observe(
                motion: player.lastMotion,
                distanceM: player.lastDistanceM,
                isFinished: finished
            )
        }
        .onDisappear { player.stop() }
    }

    private var readout: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Motion")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(player.lastMotion.capitalized)
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

    private var distanceLabel: String {
        if let d = player.lastDistanceM {
            return String(format: "%.1f m", d)
        }
        return "—"
    }

    @ViewBuilder
    private var controlsRunning: some View {
        if player.isPlaying {
            Text(scenario == .wallFail ? "Playing wall fail…" : "Playing wall pass…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Stop") { player.stop() }
                .buttonStyle(.bordered)
        } else {
            HStack(spacing: 12) {
                Button("Start") { start(scenario: .wallPass) }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                Button("Play fail") { start(scenario: .wallFail) }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }
            Button("Skip for now") {
                onboarding.skipCalibration()
            }
            .buttonStyle(.borderless)
        }
    }

    private func start(scenario: FixtureScenario) {
        self.scenario = scenario
        model.reset()
        do {
            try player.load(scenario)
            // Demo UI: accelerate long fail timeline.
            let speed = scenario == .wallFail ? 40.0 : 8.0
            player.start(speed: speed)
        } catch {
            loadError = error.localizedDescription
        }
    }
}
