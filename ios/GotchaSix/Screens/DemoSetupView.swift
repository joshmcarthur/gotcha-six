import SwiftUI

struct DemoSetupView: View {
    @EnvironmentObject private var onboarding: OnboardingStore

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 24)
            Text("Setting up radar")
                .font(.largeTitle.weight(.bold))
            Text("Demo mode uses recorded radar lines through the same parser as a real unit. No Bluetooth.")
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Continue to calibration") {
                onboarding.continueFromDemoSetup()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
