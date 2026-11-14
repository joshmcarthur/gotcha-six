import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var onboarding: OnboardingStore
    @EnvironmentObject private var radar: RadarLink

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 24)
                Text("Home")
                    .font(.largeTitle.weight(.bold))
                Text(connectionCopy)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text(calibrationCopy)
                    .font(.body)
                    .foregroundStyle(.secondary)

                if let distance = radar.lastDistanceM, radar.isConnected {
                    Text(String(format: "Last distance %.1f m · %@", distance, radar.lastMotion))
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                if !radar.isConnected {
                    Button(radar.storedPeripheralId == nil ? "Find device" : "Connect") {
                        if radar.storedPeripheralId != nil {
                            radar.reconnectStored()
                        } else {
                            onboarding.backToFindDevice()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                Text("Start session arrives next. Until then, reconnect the unit, recalibrate, or play demo fixtures.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("More") {
                        Button("Replay how-to") {
                            onboarding.replayHowTo()
                        }
                        Button("Recalibrate") {
                            onboarding.openRecalibrate()
                        }
                        Button("Play demo") {
                            onboarding.openDemoPicker()
                        }
                        if radar.storedPeripheralId != nil || radar.isConnected {
                            Button("Forget device", role: .destructive) {
                                radar.forgetDevice()
                            }
                        }
                    }
                }
            }
        }
    }

    private var connectionCopy: String {
        if radar.isConnected {
            return "Connected"
        }
        if radar.storedPeripheralId != nil {
            switch radar.phase {
            case .connecting, .scanning:
                return "Connecting…"
            case .failed(let message):
                return "Not connected · \(message)"
            default:
                return "Not connected · saved device"
            }
        }
        return "Not connected"
    }

    private var calibrationCopy: String {
        switch onboarding.calibrationStatus {
        case .incomplete:
            return "Calibration not done yet."
        case .demoPassed:
            return "Demo calibration passed."
        case .passed:
            return "Calibration passed."
        case .skipped:
            return "Calibration skipped — connect a unit later to prove the radar."
        }
    }
}
