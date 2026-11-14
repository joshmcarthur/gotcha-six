import ActivityKit
import SwiftUI
import WidgetKit

@main
struct GotchaSixActivityBundle: WidgetBundle {
    var body: some Widget {
        GotchaSixLiveActivity()
    }
}

struct GotchaSixLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GotchaSixActivityAttributes.self) { context in
            LiveActivityView(state: context.state)
                .padding(16)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.connection)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.distanceLabel)
                        .font(.caption.monospacedDigit())
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.motion)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Gotcha Six")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Text(shortMotion(context.state.motion))
                    .font(.caption2.weight(.semibold))
            } compactTrailing: {
                Text(context.state.distanceLabel)
                    .font(.caption2.monospacedDigit())
            } minimal: {
                Image(systemName: "dot.radiowaves.right")
            }
        }
    }

    private func shortMotion(_ motion: String) -> String {
        switch motion.lowercased() {
        case "approaching": return "←"
        case "receding": return "→"
        case "stationary": return "•"
        default: return "—"
        }
    }
}

struct LiveActivityView: View {
    let state: GotchaSixActivityAttributes.ContentState

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Gotcha Six")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(state.connection)
                    .font(.subheadline.weight(.semibold))
                Text(state.motion)
                    .font(.title3.weight(.semibold))
            }
            Spacer()
            Text(state.distanceLabel)
                .font(.title2.weight(.semibold).monospacedDigit())
        }
        .foregroundStyle(.white)
    }
}
