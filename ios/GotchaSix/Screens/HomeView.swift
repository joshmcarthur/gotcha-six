import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var onboarding: OnboardingStore

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 24)
                Text("Home")
                    .font(.largeTitle.weight(.bold))
                Text("Not connected")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("Pairing and sessions arrive in later slices. Replay the how-to anytime from the menu.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("More") {
                        Button("Replay how-to") {
                            onboarding.replayHowTo()
                        }
                    }
                }
            }
        }
    }
}
