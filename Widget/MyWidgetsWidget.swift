import WidgetKit
import SwiftUI

// MARK: - 数据

struct LauncherEntry: TimelineEntry {
    let date: Date
    let shortcuts: [Shortcut]
    let style: WidgetStyle
    let shape: WidgetShape
}

struct LauncherProvider: TimelineProvider {
    func placeholder(in context: Context) -> LauncherEntry {
        LauncherEntry(date: .now, shortcuts: Shortcut.presets, style: .glass, shape: .roundedSquare)
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
                      style: ShortcutStore.shared.loadStyle(),
                      shape: ShortcutStore.shared.loadShape())
    }
}

// MARK: - 组件声明

struct LauncherWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LauncherWidget", provider: LauncherProvider()) { entry in
            LauncherEntryView(entry: entry)
        }
        .configurationDisplayName("快速启动")
        .description("点击图标直接打开对应 App。在主 App 里编辑快捷方式、图标和风格。")
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
            LauncherGrid(shortcuts: Array(entry.shortcuts.prefix(6)),
                         columns: 3, shape: entry.shape, iconSize: 22)
        case .systemMedium:
            LauncherGrid(shortcuts: Array(entry.shortcuts.prefix(10)),
                         columns: 5, shape: entry.shape, iconSize: 28)
        case .systemLarge:
            LauncherGrid(shortcuts: Array(entry.shortcuts.prefix(21)),
                         columns: 7, shape: entry.shape, iconSize: 20)
        default:
            accessoryView
        }
    }

    /// 锁屏圆形组件：显示第一个快捷方式
    @ViewBuilder
    private var accessoryView: some View {
        if let first = entry.shortcuts.first {
            Group {
                if let symbolName = first.symbolName {
                    Image(systemName: symbolName)
                        .font(.system(size: 20))
                        .foregroundStyle(textColor)
                } else {
                    Text(first.glyph)
                        .font(.system(size: 20))
                }
            }
            .overlay {
                // 与主网格一致：iOS 26 需要 Link 垫在透明层上才能跳转
                if let url = first.url {
                    Link(destination: url) {
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                    }
                }
            }
        } else {
            Text("🚀")
                .font(.system(size: 20))
        }
    }
}
