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
            TeachingImage(name: "TeachingHowToA")
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
