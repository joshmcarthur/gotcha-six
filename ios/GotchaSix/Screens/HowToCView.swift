import SwiftUI

struct HowToCView: View {
    @EnvironmentObject private var onboarding: OnboardingStore

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 24)
            Text("Phone in pocket")
                .font(.largeTitle.weight(.bold))
            Text("During a session the phone stays in a pocket. Glance the Live Activity on the lock screen when you need it.")
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
                onboarding.continueHowTo(from: .howToC)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
