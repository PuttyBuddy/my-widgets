import WidgetKit
import SwiftUI

/// 小号时钟：绿色日期徽章 + 大字时钟 + 天气行（对标 Koco 小时钟）
struct SmallClockEntry: TimelineEntry {
    let date: Date
}

struct SmallClockProvider: TimelineProvider {
    func placeholder(in context: Context) -> SmallClockEntry {
        SmallClockEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (SmallClockEntry) -> Void) {
        completion(SmallClockEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SmallClockEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [SmallClockEntry(date: .now)], policy: .after(next)))
    }
}

struct SmallClockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SmallClockWidget", provider: SmallClockProvider()) { entry in
            SmallClockEntryView(entry: entry)
        }
        .configurationDisplayName("小时钟")
        .description("日期徽章、大字时钟和当日温度范围。")
        .supportedFamilies([.systemSmall])
    }
}

struct SmallClockEntryView: View {
    @Environment(\.colorScheme) private var scheme
    var entry: SmallClockEntry

    private var font: AppFont { ShortcutStore.shared.loadFont() }
    private var appearance: AppAppearance { ShortcutStore.shared.loadAppearance() }
    private var palette: WidgetPalette { WidgetPalette.resolve(appearance, scheme: scheme) }

    var body: some View {
        VStack(spacing: 6) {
            Text(dateBadge)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color(hex: "#34C77B")))
            Text(entry.date, style: .time)
                .font(appFont(font, 42, .heavy))
                .monospacedDigit()
                .foregroundStyle(palette.ink)
                .minimumScaleFactor(0.6)
            weatherRow
        }
        .containerBackground(for: .widget) { palette.background }
    }

    private var dateBadge: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "zh_CN")
        fmt.dateFormat = "EEE, MM/dd"
        return fmt.string(from: entry.date)
    }

    @ViewBuilder
    private var weatherRow: some View {
        if let data = ShortcutStore.shared.loadWeather() {
            HStack(spacing: 6) {
                Image(systemName: data.conditionSymbol)
                    .font(.system(size: 14))
                    .foregroundStyle(.orange)
                Text(String(format: "%.0f°-%.0f°", data.tempMin, data.tempMax))
                    .font(appFont(font, 14, .bold))
                    .monospacedDigit()
                    .foregroundStyle(palette.ink)
            }
        } else {
            Text("在主 App 里设置天气")
                .font(.system(size: 11))
                .foregroundStyle(palette.sub)
        }
    }
}
