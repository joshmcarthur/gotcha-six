import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var onboarding: OnboardingStore
    @EnvironmentObject private var radar: RadarLink
    @EnvironmentObject private var session: SessionController

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

                if session.isSessionOn {
                    Text("Session on")
                        .font(.title3.weight(.semibold))
                    if let distance = radar.lastDistanceM, radar.hasTarget {
                        Text(String(format: "%@ · %.1f m", radar.lastMotion.capitalized, distance))
                            .font(.body)
                            .foregroundStyle(.secondary)
                    } else if radar.isConnected {
                        Text("None")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                } else if let distance = radar.lastDistanceM, radar.isConnected, radar.hasTarget {
                    Text(String(format: "Last distance %.1f m · %@", distance, radar.lastMotion))
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                if let error = session.lastError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                sessionButton

                if !radar.isConnected, !session.isSessionOn {
                    Button(radar.storedPeripheralId == nil ? "Find device" : "Connect") {
                        if radar.storedPeripheralId != nil {
                            radar.reconnectStored()
                        } else {
                            onboarding.backToFindDevice()
                        }
                    }
                    .buttonStyle(.bordered)
                }

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
                                if session.isSessionOn {
                                    session.endSession()
                                }
                                radar.forgetDevice()
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var sessionButton: some View {
        if session.isSessionOn {
            Button("End session") {
                session.endSession()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        } else {
            Button("Start session") {
                session.startSession()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!radar.isConnected)
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
                return session.isSessionOn ? "Disconnected · reconnecting" : "Not connected · saved device"
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
