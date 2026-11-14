import SwiftUI

struct FindDeviceView: View {
    @EnvironmentObject private var onboarding: OnboardingStore

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 24)
            Text("Find device")
                .font(.largeTitle.weight(.bold))
            Text("Turn the unit on. It advertises as Gotcha Six. Real Bluetooth scanning arrives in a later update.")
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                Button {
                    onboarding.startDemoDevice()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Demo Gotcha Six")
                                .font(.body.weight(.semibold))
                            Text("Simulated unit · no hardware")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 4)
                }
                .buttonStyle(.plain)

                Divider()

                Text("No real devices nearby")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 14)
            }

            Spacer()

            Button("Continue without device") {
                onboarding.continueWithoutDevice()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
