import WidgetKit
import SwiftUI

// MARK: - 数据

struct LauncherEntry: TimelineEntry {
    let date: Date
    let shortcuts: [Shortcut]
    let style: WidgetStyle
    let shape: WidgetShape
    let layout: LauncherLayout
    let actionMode: ActionMode
    let keepInteractions: Bool
}

struct LauncherProvider: TimelineProvider {
    func placeholder(in context: Context) -> LauncherEntry {
        LauncherEntry(date: .now, shortcuts: Shortcut.presets, style: .glass,
                      shape: .roundedSquare, layout: .grid, actionMode: .preset, keepInteractions: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (LauncherEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LauncherEntry>) -> Void) {
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }

    private func currentEntry() -> LauncherEntry {
        let store = ShortcutStore.shared
        return LauncherEntry(date: .now,
                             shortcuts: store.loadShortcuts(),
                             style: store.loadStyle(),
                             shape: store.loadShape(),
                             layout: store.loadLauncherLayout(),
                             actionMode: store.loadActionMode(),
                             keepInteractions: store.loadKeepInteractions())
    }
}

// MARK: - 组件声明

struct LauncherWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LauncherWidget", provider: LauncherProvider()) { entry in
            LauncherEntryView(entry: entry)
        }
        .configurationDisplayName("快速启动")
        .description("点击图标直接打开对应 App。应用、图标、背景和动作都在主 App 里配置。")
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

    /// 背景：用户选了图片就用图片，否则用默认材质
    @ViewBuilder
    private var background: some View {
        if let img = ShortcutStore.shared.loadBackgroundImage() {
            GeometryReader { g in
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: g.size.width, height: g.size.height)
                    .clipped()
            }
        } else {
            switch entry.style {
            case .glass:
                Rectangle().fill(.ultraThinMaterial)
            case .transparent:
                Color.clear
            case .dark:
                Color(red: 0.07, green: 0.07, blue: 0.09).opacity(0.85)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemSmall:
            LauncherGrid(shortcuts: Array(entry.shortcuts.prefix(6)),
                         columns: 3, shape: entry.shape, iconSize: 22,
                         actionMode: entry.actionMode, interactive: entry.keepInteractions)
        case .systemMedium:
            // 迷你应用（中）：3×7 = 21 个小图标，对标 Koco
            LauncherGrid(shortcuts: Array(entry.shortcuts.prefix(21)),
                         columns: 7, shape: entry.shape, iconSize: 16,
                         actionMode: entry.actionMode, interactive: entry.keepInteractions)
        case .systemLarge:
            if entry.layout == .bubble {
                BubbleIconLayout(shortcuts: Array(entry.shortcuts.prefix(21)),
                                 actionMode: entry.actionMode, interactive: entry.keepInteractions)
            } else {
                LauncherGrid(shortcuts: Array(entry.shortcuts.prefix(21)),
                             columns: 7, shape: entry.shape, iconSize: 20,
                             actionMode: entry.actionMode, interactive: entry.keepInteractions)
            }
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
                if entry.keepInteractions, let url = first.effectiveURL(entry.actionMode) {
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

// MARK: - 气泡布局（中心大图标 + 两圈环绕）

struct BubbleIconLayout: View {
    let shortcuts: [Shortcut]
    var actionMode: ActionMode = .preset
    var interactive: Bool = true

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                if let first = shortcuts.first {
                    bubbleTile(first, size: side * 0.36)
                        .position(center)
                }
                ForEach(ringItems(from: 1, capacity: 8), id: \.0.id) { item in
                    bubbleTile(item.0, size: side * 0.21)
                        .position(ringPosition(center, index: item.1, count: 8, radius: side * 0.335))
                }
                ForEach(ringItems(from: 9, capacity: 12), id: \.0.id) { item in
                    bubbleTile(item.0, size: side * 0.17)
                        .position(ringPosition(center, index: item.1, count: 12, radius: side * 0.47))
                }
            }
        }
    }

    private func ringItems(from start: Int, capacity: Int) -> [(Shortcut, Int)] {
        Array(shortcuts.dropFirst(start).prefix(capacity).enumerated())
            .map { ($0.element, $0.offset) }
    }

    private func ringPosition(_ center: CGPoint, index: Int, count: Int, radius: CGFloat) -> CGPoint {
        let angle = (Double(index) / Double(max(1, count))) * 2 * .pi - .pi / 2
        return CGPoint(x: center.x + CGFloat(cos(angle)) * radius,
                       y: center.y + CGFloat(sin(angle)) * radius)
    }

    private func bubbleTile(_ s: Shortcut, size: CGFloat) -> some View {
        ShortcutTile(shortcut: s, shape: .circle, iconSize: size * 0.48,
                     linkURL: s.effectiveURL(actionMode), interactive: interactive)
            .frame(width: size, height: size)
    }
}
