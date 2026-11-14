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
            Text("An aid for awareness — not a substitute for looking.")
                .font(.body)
                .foregroundStyle(.secondary)
            WelcomeIllustration()
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .background(Color.secondary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
