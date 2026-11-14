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
                Text(calibrationCopy)
                    .font(.body)
                    .foregroundStyle(.secondary)
                Text("Pairing and live sessions arrive next. Until then, replay the how-to or play demo radar fixtures.")
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
                        Button("Play demo") {
                            onboarding.openDemoPicker()
                        }
                    }
                }
            }
        }
    }

    private var calibrationCopy: String {
        switch onboarding.calibrationStatus {
        case .incomplete:
            return "Calibration not done yet."
        case .demoPassed:
            return "Demo calibration passed."
        case .skipped:
            return "Calibration skipped — connect a unit later to prove the radar."
        }
    }
}
