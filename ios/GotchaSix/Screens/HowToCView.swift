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
            HowToCIllustration()
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .background(Color.secondary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
