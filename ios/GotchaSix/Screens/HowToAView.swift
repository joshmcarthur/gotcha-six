import SwiftUI

struct HowToAView: View {
    @EnvironmentObject private var onboarding: OnboardingStore

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 24)
            Text("What it watches")
                .font(.largeTitle.weight(.bold))
            Text("The radar faces backward. It tracks one target: distance and whether that target is approaching or receding.")
                .font(.body)
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
