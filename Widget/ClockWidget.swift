import WidgetKit
import SwiftUI

/// 大字时钟 + 农历日期 + 圆形快捷方式（对标 Koco 时钟组件）
struct ClockEntry: TimelineEntry {
    let date: Date
    let shortcuts: [Shortcut]
}

struct ClockProvider: TimelineProvider {
    func placeholder(in context: Context) -> ClockEntry {
        ClockEntry(date: .now, shortcuts: Array(Shortcut.presets.prefix(4)))
    }

    func getSnapshot(in context: Context, completion: @escaping (ClockEntry) -> Void) {
        completion(ClockEntry(date: .now, shortcuts: Array(ShortcutStore.shared.loadShortcuts().prefix(4))))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClockEntry>) -> Void) {
        let entry = ClockEntry(date: .now, shortcuts: Array(ShortcutStore.shared.loadShortcuts().prefix(4)))
        // Text(.time) 会自行走秒，这里半小时刷新一次时间线即可
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct ClockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ClockWidget", provider: ClockProvider()) { entry in
            ClockEntryView(entry: entry)
        }
        .configurationDisplayName("时钟 + 快捷方式")
        .description("大字时钟、农历日期和最常用的四个快捷方式。")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct ClockEntryView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var scheme
    var entry: ClockEntry

    private var font: AppFont { ShortcutStore.shared.loadFont() }
    private var appearance: AppAppearance { ShortcutStore.shared.loadAppearance() }
    private var isDark: Bool {
        switch appearance {
        case .dark: return true
        case .light: return false
        case .system: return scheme == .dark
        }
    }

    var body: some View {
        ZStack {
            background
            VStack(spacing: isLarge ? 6 : 2) {
                // 大字时钟（自动走秒）
                Text(entry.date, style: .time)
                    .font(appFont(font, isLarge ? 62 : 42, .heavy))
                    .monospacedDigit()
                    .foregroundStyle(ink)
                    .minimumScaleFactor(0.6)
                Text(gregorianDateString(entry.date) + "  " + lunarDateString(entry.date))
                    .font(appFont(font, isLarge ? 15 : 12, .semibold))
                    .foregroundStyle(ink.opacity(0.85))
                    .minimumScaleFactor(0.7)
                HStack(spacing: isLarge ? 18 : 12) {
                    let mode = ShortcutStore.shared.loadActionMode()
                    let interactions = ShortcutStore.shared.loadKeepInteractions()
                    ForEach(entry.shortcuts) { s in
                        ShortcutTile(shortcut: s, shape: .circle, iconSize: isLarge ? 26 : 20,
                                     linkURL: s.effectiveURL(mode), interactive: interactions)
                    }
                }
                .padding(.top, isLarge ? 8 : 4)
            }
        }
        .containerBackground(for: .widget) { background }
    }

    private var isLarge: Bool { family == .systemLarge }

    private var ink: Color { isDark ? .white : Color(red: 0.10, green: 0.10, blue: 0.12) }

    /// Koco 同款壁纸渐变：深灰 → 藕粉
    private var background: some View {
        Group {
            if isDark {
                LinearGradient(
                    colors: [
                        Color(red: 0.16, green: 0.15, blue: 0.18),
                        Color(red: 0.34, green: 0.28, blue: 0.31),
                        Color(red: 0.62, green: 0.50, blue: 0.52)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.99, green: 0.98, blue: 0.99),
                        Color(red: 1.00, green: 0.90, blue: 0.89),
                        Color(red: 0.97, green: 0.82, blue: 0.82)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            }
        }
    }
}
