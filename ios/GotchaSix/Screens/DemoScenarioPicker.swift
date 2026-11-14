import SwiftUI

struct DemoScenarioPicker: View {
    @EnvironmentObject private var onboarding: OnboardingStore
    @StateObject private var player = FixturePlayer()
    @State private var active: FixtureScenario?
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Demo · no hardware. Lines feed the real Rust parser.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Scenarios") {
                    ForEach(FixtureScenario.allCases) { scenario in
                        Button {
                            play(scenario)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(scenario.title)
                                    .foregroundStyle(.primary)
                                Text(scenario.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                if let active {
                    Section("Now playing") {
                        LabeledContent("Scenario", value: active.title)
                        LabeledContent("Motion", value: player.lastMotion.capitalized)
                        LabeledContent(
                            "Distance",
                            value: player.lastDistanceM.map { String(format: "%.1f m", $0) } ?? "—"
                        )
                        if player.isFinished {
                            Text("Finished")
                                .foregroundStyle(.secondary)
                        }
                        if active == .alertApproach, player.lastMotion == "approaching" {
                            SampleAlertCard()
                        }
                        Button("Stop") { player.stop() }
                    }
                }
                if let loadError {
                    Text(loadError).foregroundStyle(.red)
                }
            }
            .navigationTitle("Play demo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        player.stop()
                        onboarding.showDemoPicker = false
                    }
                }
            }
        }
        .onDisappear { player.stop() }
    }

    private func play(_ scenario: FixtureScenario) {
        active = scenario
        do {
            try player.load(scenario)
            let speed = scenario == .wallFail ? 40.0 : 8.0
            player.start(speed: speed)
        } catch {
            loadError = error.localizedDescription
        }
    }
}
