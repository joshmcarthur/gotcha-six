import SwiftUI

struct FindDeviceView: View {
    @EnvironmentObject private var onboarding: OnboardingStore
    @State private var refreshToken = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 24)
            Text("Find device")
                .font(.largeTitle.weight(.bold))
            Text("Turn the unit on. It advertises as Gotcha Six.")
                .font(.body)
                .foregroundStyle(.secondary)

            List {
                Text("No devices yet")
                    .foregroundStyle(.secondary)
            }
            .listStyle(.plain)
            .frame(maxHeight: 220)
            .id(refreshToken)

            Text("Scanning arrives in the next slice. Continue to Home for now.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()
            HStack(spacing: 12) {
                Button("Retry") {
                    refreshToken += 1
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button("Continue") {
                    onboarding.finishFindDevice()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
