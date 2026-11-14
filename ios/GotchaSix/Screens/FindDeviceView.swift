import SwiftUI

struct FindDeviceView: View {
    @EnvironmentObject private var onboarding: OnboardingStore
    @EnvironmentObject private var radar: RadarLink

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 24)
            Text("Find device")
                .font(.largeTitle.weight(.bold))
            Text("Turn the unit on. It advertises as Gotcha Six.")
                .font(.body)
                .foregroundStyle(.secondary)

            statusLine

            VStack(spacing: 0) {
                Button {
                    onboarding.startDemoDevice()
                } label: {
                    row(
                        title: "Demo Gotcha Six",
                        subtitle: "Simulated unit · no hardware",
                        showChevron: true
                    )
                }
                .buttonStyle(.plain)

                Divider()

                if radar.discovered.isEmpty {
                    Text(emptyListCopy)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 14)
                } else {
                    ForEach(radar.discovered) { device in
                        Button {
                            radar.connect(to: device.id)
                            onboarding.startLiveSetup()
                        } label: {
                            row(
                                title: device.name,
                                subtitle: "RSSI \(device.rssi) dBm",
                                showChevron: true
                            )
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }

            HStack(spacing: 12) {
                Button("Retry scan") {
                    radar.startScan()
                }
                .buttonStyle(.bordered)
                .disabled(radar.phase == .poweredOff || radar.phase == .unauthorized)

                Spacer()
            }

            if let error = radar.lastError, case .failed = radar.phase {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Spacer()

            Button("Continue without device") {
                radar.stopScan()
                onboarding.continueWithoutDevice()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .onAppear { radar.startScan() }
        .onDisappear {
            if case .scanning = radar.phase {
                radar.stopScan()
            }
        }
    }

    private var statusLine: some View {
        Text(phaseCopy)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private var phaseCopy: String {
        switch radar.phase {
        case .unknown:
            return "Checking Bluetooth…"
        case .poweredOff:
            return "Bluetooth is off. Turn it on to scan."
        case .unauthorized:
            return "Bluetooth access is off. Enable it in Settings."
        case .scanning:
            return "Scanning…"
        case .connecting:
            return "Connecting…"
        case .connected:
            return "Connected."
        case .idle:
            return "Ready to scan."
        case .failed(let message):
            return message
        }
    }

    private var emptyListCopy: String {
        switch radar.phase {
        case .scanning:
            return "No devices yet — keep the unit nearby and powered on."
        case .poweredOff, .unauthorized:
            return "Cannot scan until Bluetooth is available."
        default:
            return "No Gotcha Six devices nearby."
        }
    }

    private func row(title: String, subtitle: String, showChevron: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if showChevron {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 4)
    }
}
