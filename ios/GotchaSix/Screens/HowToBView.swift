import SwiftUI
import UIKit

struct HowToBView: View {
    @EnvironmentObject private var onboarding: OnboardingStore
    @State private var showSampleCard = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 24)
            Text("The alert")
                .font(.largeTitle.weight(.bold))
            Text("This is the alert for something closing from behind.")
                .font(.body)

            if showSampleCard {
                SampleAlertCard()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()
            Button("Play alert") {
                playAlert()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button("Next") {
                onboarding.continueHowTo(from: .howToB)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .animation(.easeOut(duration: 0.25), value: showSampleCard)
        #if DEBUG
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-showSampleAlert") {
                playAlert()
            }
        }
        #endif
    }

    private func playAlert() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
        showSampleCard = true
    }
}

struct SampleAlertCard: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Live Activity")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Approaching · 12 m")
                    .font(.title3.weight(.semibold))
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color("AccentColor").opacity(0.15))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color("AccentColor").opacity(0.5), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier("sampleAlertCard")
    }
}
