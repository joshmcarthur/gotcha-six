import SwiftUI

/// Live path after BLE connect: wait for NUS notify + automatic preset.
struct SetupView: View {
    @EnvironmentObject private var onboarding: OnboardingStore
    @EnvironmentObject private var radar: RadarLink

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 24)
            Text("Setting up radar")
                .font(.largeTitle.weight(.bold))
            Text("Configuring the radar for rear range.")
                .font(.body)
                .foregroundStyle(.secondary)

            Text(statusCopy)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if radar.isSendingPreset {
                ProgressView()
                    .padding(.top, 8)
            }

            if let error = radar.lastError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Spacer()

            if readyForCalibration {
                Button("Continue to calibration") {
                    onboarding.continueFromLiveSetup()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                HStack(spacing: 12) {
                    Button("Retry preset") {
                        radar.sendPreset()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!radar.isConnected)

                    Button("Disconnect") {
                        radar.disconnect()
                        onboarding.backToFindDevice()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .onChange(of: radar.phase) { _, newPhase in
            if case .failed = newPhase {
                // Stay on setup with Retry / Disconnect.
            }
        }
    }

    private var readyForCalibration: Bool {
        radar.isConnected && !radar.isSendingPreset
    }

    private var statusCopy: String {
        if case .connecting = radar.phase {
            return "Connecting to the unit…"
        }
        if radar.isSendingPreset {
            return "Sending radar preset…"
        }
        if radar.isConnected {
            return "Preset sent. You can calibrate."
        }
        if case .failed(let message) = radar.phase {
            return message
        }
        return "Waiting for the unit…"
    }
}
