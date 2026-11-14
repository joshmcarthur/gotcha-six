import SwiftUI

@main
struct GotchaSixApp: App {
    @StateObject private var onboarding = OnboardingStore()
    @StateObject private var radar = RadarLink()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(onboarding)
                .environmentObject(radar)
                .onAppear {
                    _ = CoreSmoke.touch()
                }
        }
    }
}
