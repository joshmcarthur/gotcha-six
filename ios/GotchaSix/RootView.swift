import SwiftUI

struct RootView: View {
    @EnvironmentObject private var onboarding: OnboardingStore

    var body: some View {
        Group {
            switch onboarding.route {
            case .welcome:
                WelcomeView()
            case .permissions:
                PermissionsView()
            case .howToA:
                HowToAView()
            case .howToB:
                HowToBView()
            case .howToC:
                HowToCView()
            case .findDevice:
                FindDeviceView()
            case .home:
                HomeView()
            }
        }
        .tint(Color("AccentColor"))
    }
}
