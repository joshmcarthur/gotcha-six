import SwiftUI
import WidgetKit

/// Empty Live Activity extension stub. Slice 6 owns ActivityKit UI.
@main
struct GotchaSixActivityBundle: WidgetBundle {
    var body: some Widget {
        GotchaSixPlaceholderWidget()
    }
}

struct GotchaSixPlaceholderWidget: Widget {
    let kind = "GotchaSixPlaceholder"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlaceholderProvider()) { _ in
            Text("Gotcha Six")
                .font(.headline)
                .padding()
        }
        .configurationDisplayName("Gotcha Six")
        .description("Placeholder until the session Live Activity ships.")
        .supportedFamilies([.systemSmall])
    }
}

struct PlaceholderProvider: TimelineProvider {
    func placeholder(in _: Context) -> PlaceholderEntry {
        PlaceholderEntry(date: Date())
    }

    func getSnapshot(in _: Context, completion: @escaping (PlaceholderEntry) -> Void) {
        completion(PlaceholderEntry(date: Date()))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<PlaceholderEntry>) -> Void) {
        completion(Timeline(entries: [PlaceholderEntry(date: Date())], policy: .never))
    }
}

struct PlaceholderEntry: TimelineEntry {
    let date: Date
}
