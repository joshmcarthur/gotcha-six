import SwiftUI

@main
struct GotchaSixApp: App {
    @StateObject private var onboarding = OnboardingStore()
    @StateObject private var radar: RadarLink
    @StateObject private var session: SessionController

    init() {
        let radar = RadarLink()
        _radar = StateObject(wrappedValue: radar)
        _session = StateObject(wrappedValue: SessionController(radar: radar))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(onboarding)
                .environmentObject(radar)
                .environmentObject(session)
                .onAppear {
                    _ = CoreSmoke.touch()
                }
        }
    }
}
