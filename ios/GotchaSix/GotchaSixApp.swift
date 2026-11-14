import SwiftUI

@main
struct GotchaSixApp: App {
    @StateObject private var onboarding = OnboardingStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(onboarding)
                .onAppear {
                    _ = CoreSmoke.touch()
                }
        }
    }
}
