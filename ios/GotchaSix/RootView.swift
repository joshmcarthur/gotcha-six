import SwiftUI

struct RootView: View {
    @EnvironmentObject private var onboarding: OnboardingStore

    var body: some View {
        Group {
            switch onboarding.route {
            case .welcome:
                WelcomeView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .permissions:
                PermissionsView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .howToA:
                HowToAView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .howToB:
                HowToBView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .howToC:
                HowToCView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .findDevice:
                FindDeviceView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .demoSetup:
                DemoSetupView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .calibration:
                CalibrationView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .home:
                HomeView()
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.28), value: onboarding.route)
        .tint(Color("AccentColor"))
        .sheet(isPresented: $onboarding.showDemoPicker) {
            DemoScenarioPicker()
                .environmentObject(onboarding)
        }
    }
}
