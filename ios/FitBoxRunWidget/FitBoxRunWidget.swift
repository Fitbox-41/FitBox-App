// FitBox — iOS home-screen widget ("Start a run").
//
// This is the WidgetKit source. It is NOT yet part of the Xcode project — it
// must be added as a Widget Extension target (see ios/FitBoxRunWidget/README.md).
// Tapping the widget opens the app via the `fitbox://start-run` deep link, which
// the Flutter side (app.dart) routes into the run flow — same behaviour as the
// Android widget, so there is no extra Flutter work per platform.

import WidgetKit
import SwiftUI

struct FitBoxRunEntry: TimelineEntry {
    let date: Date
}

struct FitBoxRunProvider: TimelineProvider {
    func placeholder(in context: Context) -> FitBoxRunEntry { FitBoxRunEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (FitBoxRunEntry) -> Void) {
        completion(FitBoxRunEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<FitBoxRunEntry>) -> Void) {
        completion(Timeline(entries: [FitBoxRunEntry(date: Date())], policy: .never))
    }
}

struct FitBoxRunWidgetEntryView: View {
    var entry: FitBoxRunProvider.Entry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x14181C), Color(hex: 0x0A0C0F)],
                startPoint: .top, endPoint: .bottom
            )
            VStack(spacing: 10) {
                Text("FITBOX")
                    .font(.system(size: 13, weight: .bold))
                    .italic()
                    .tracking(1.5)
                    .foregroundColor(.white)
                Text("▶  Start a run")
                    .font(.system(size: 15, weight: .bold))
                    .italic()
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: 0xE31E24), Color(hex: 0xB3141A)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .clipShape(Capsule())
            }
        }
        .widgetURL(URL(string: "fitbox://start-run"))
    }
}

@main
struct FitBoxRunWidget: Widget {
    let kind: String = "FitBoxRunWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FitBoxRunProvider()) { entry in
            FitBoxRunWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("FitBox — Start a run")
        .description("Start a run instantly.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: 1
        )
    }
}
