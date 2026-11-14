import SwiftUI

struct HowToAView: View {
    @EnvironmentObject private var onboarding: OnboardingStore

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 24)
            Text("What it watches")
                .font(.largeTitle.weight(.bold))
            Text("The radar faces backward. One target: how far, and whether it is approaching or receding.")
                .font(.body)
            HowToAIllustration()
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .background(Color.secondary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Spacer()
            Button("Next") {
                onboarding.continueHowTo(from: .howToA)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
