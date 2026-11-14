import SwiftUI

struct HowToCView: View {
    @EnvironmentObject private var onboarding: OnboardingStore

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 24)
            Text("Phone in pocket")
                .font(.largeTitle.weight(.bold))
            Text("In a session the phone stays put. Glance the Live Activity when you need distance and motion.")
                .font(.body)
            TeachingImage(name: "TeachingHowToC")
            Spacer()
            Button("Next") {
                onboarding.continueHowTo(from: .howToC)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
