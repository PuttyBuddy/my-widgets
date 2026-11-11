import WidgetKit
import SwiftUI

// MARK: - 数据

struct LauncherEntry: TimelineEntry {
    let date: Date
    let shortcuts: [Shortcut]
    let style: WidgetStyle
}

struct LauncherProvider: TimelineProvider {
    func placeholder(in context: Context) -> LauncherEntry {
        LauncherEntry(date: .now, shortcuts: Shortcut.presets, style: .glass)
    }

    func getSnapshot(in context: Context, completion: @escaping (LauncherEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LauncherEntry>) -> Void) {
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }

    private func currentEntry() -> LauncherEntry {
        LauncherEntry(date: .now,
                      shortcuts: ShortcutStore.shared.loadShortcuts(),
                      style: ShortcutStore.shared.loadStyle())
    }
}

// MARK: - 组件声明

struct LauncherWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LauncherWidget", provider: LauncherProvider()) { entry in
            LauncherEntryView(entry: entry)
        }
        .configurationDisplayName("快速启动")
        .description("点击图标直接打开对应 App。在主 App 里编辑快捷方式和风格。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular])
    }
}

// MARK: - 界面

struct LauncherEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: LauncherEntry

    var body: some View {
        content
            .foregroundStyle(textColor)
            .containerBackground(for: .widget) { background }
    }

    /// 透明/深色风格下用白字，毛玻璃跟随系统深浅色
    private var textColor: Color {
        entry.style == .glass ? .primary : .white
    }

    @ViewBuilder
    private var background: some View {
        switch entry.style {
        case .glass:
            Rectangle().fill(.ultraThinMaterial)
        case .transparent:
            Color.clear
        case .dark:
            Color(red: 0.07, green: 0.07, blue: 0.09).opacity(0.85)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemSmall:
            LauncherGrid(shortcuts: Array(entry.shortcuts.prefix(4)),
                         columns: 2, textColor: textColor, emojiSize: 26)
        case .systemMedium:
            LauncherGrid(shortcuts: Array(entry.shortcuts.prefix(8)),
                         columns: 4, textColor: textColor, emojiSize: 24)
        case .systemLarge:
            LauncherGrid(shortcuts: Array(entry.shortcuts.prefix(12)),
                         columns: 4, textColor: textColor, emojiSize: 28)
        default:
            accessoryView
        }
    }

    /// 锁屏圆形组件：显示第一个快捷方式
    @ViewBuilder
    private var accessoryView: some View {
        if let first = entry.shortcuts.first {
            if let url = first.url {
                Link(destination: url) {
                    Text(first.glyph)
                        .font(.system(size: 22))
                }
            } else {
                Text(first.glyph)
                    .font(.system(size: 22))
            }
        } else {
            Text("🚀")
                .font(.system(size: 22))
        }
    }
}
