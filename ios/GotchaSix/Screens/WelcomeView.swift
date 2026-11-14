import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var onboarding: OnboardingStore

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 24)
            Text("Gotcha Six")
                .font(.largeTitle.weight(.bold))
            Text("Watches behind you while you run or ride.")
                .font(.title3)
            Text("It is an aid, not a substitute for looking.")
                .font(.body)
                .foregroundStyle(.secondary)
            // Illustration slot — slice 7
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.12))
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .overlay {
                    Text("Illustration")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            Spacer()
            Button("Continue") {
                onboarding.continueFromWelcome()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
