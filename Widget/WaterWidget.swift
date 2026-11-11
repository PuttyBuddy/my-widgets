import WidgetKit
import SwiftUI
import AppIntents

// MARK: - 交互意图（真机 +/− 按钮直接生效）

struct WaterAddIntent: AppIntent {
    static var title: LocalizedStringResource { "记一杯水" }
    func perform() async throws -> some IntentResult {
        ShortcutStore.shared.addWater(1)
        return .result()
    }
}

struct WaterRemoveIntent: AppIntent {
    static var title: LocalizedStringResource { "撤销一杯" }
    func perform() async throws -> some IntentResult {
        ShortcutStore.shared.addWater(-1)
        return .result()
    }
}

// MARK: - 数据

struct WaterEntry: TimelineEntry {
    let date: Date
    let count: Int
    let goal: Int
}

struct WaterProvider: TimelineProvider {
    func placeholder(in context: Context) -> WaterEntry {
        WaterEntry(date: .now, count: 3, goal: 8)
    }

    func getSnapshot(in context: Context, completion: @escaping (WaterEntry) -> Void) {
        completion(WaterEntry(date: .now, count: ShortcutStore.shared.currentWater(), goal: ShortcutStore.shared.waterGoal()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WaterEntry>) -> Void) {
        let entry = WaterEntry(date: .now, count: ShortcutStore.shared.currentWater(), goal: ShortcutStore.shared.waterGoal())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

// MARK: - 组件

struct WaterWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WaterWidget", provider: WaterProvider()) { entry in
            WaterEntryView(entry: entry)
        }
        .configurationDisplayName("喝水记录")
        .description("牛奶瓶刻度 + 加减按钮，点按即记录，跨天自动清零。")
        .supportedFamilies([.systemSmall])
    }
}

struct WaterEntryView: View {
    @Environment(\.colorScheme) private var scheme
    var entry: WaterEntry

    private var appearance: AppAppearance { ShortcutStore.shared.loadAppearance() }
    private var isDark: Bool {
        switch appearance {
        case .dark: return true
        case .light: return false
        case .system: return scheme == .dark
        }
    }
    private var ink: Color { isDark ? .white : Color(red: 0.10, green: 0.10, blue: 0.12) }
    private var waterColor: Color { isDark ? Color(red: 0.45, green: 0.75, blue: 0.95) : Color(red: 0.35, green: 0.62, blue: 0.90) }

    private var level: CGFloat {
        entry.goal <= 0 ? 0 : min(1, CGFloat(entry.count) / CGFloat(entry.goal))
    }

    var body: some View {
        HStack(spacing: 8) {
            BottleView(level: level, ink: ink, water: waterColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack(spacing: 10) {
                roundButton(icon: "minus", intent: WaterRemoveIntent())
                VStack(spacing: 0) {
                    Text("\(entry.count)")
                        .font(appFont(ShortcutStore.shared.loadFont(), 34, .bold))
                        .monospacedDigit()
                        .foregroundStyle(ink)
                        .minimumScaleFactor(0.5)
                    Text("杯")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.6))
                }
                roundButton(icon: "plus", intent: WaterAddIntent())
            }
            .frame(maxHeight: .infinity)
        }
        .padding(6)
        .containerBackground(for: .widget) {
            Color(red: isDark ? 0.09 : 0.99, green: isDark ? 0.09 : 0.99, blue: isDark ? 0.10 : 0.99)
        }
    }

    private func roundButton(icon: String, intent: some AppIntent) -> some View {
        Button(intent: intent) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(isDark ? Color.black : Color.white)
                .frame(width: 34, height: 34)
                .background(Circle().fill(ink))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 牛奶瓶 + 刻度

struct BottleView: View {
    let level: CGFloat
    let ink: Color
    let water: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let bottleW = min(w * 0.58, h * 0.62)
            let bottleH = bottleW * 1.5
            ZStack {
                // 左侧刻度线
                Path { p in
                    let marks = 14
                    let markH = bottleH * 0.92
                    for i in 0...marks {
                        let y = h * 0.5 - markH / 2 + markH * CGFloat(i) / CGFloat(marks)
                        let long = i % 7 == 0 ? w * 0.10 : w * 0.055
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: long, y: y))
                    }
                }
                .stroke(ink.opacity(0.55), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .frame(width: w * 0.14, alignment: .leading)
                .offset(x: 0)

                // 瓶身
                ZStack {
                    BottlePath()
                        .fill(ink.opacity(0.04))
                    // 水位填充
                    GeometryReader { g in
                        let fillH = g.size.height * level * 0.86 + g.size.height * 0.06
                        Rectangle()
                            .fill(water.opacity(0.85))
                            .frame(height: fillH)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                    .mask(BottlePath())
                    BottlePath()
                        .stroke(ink, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                }
                .frame(width: bottleW, height: bottleH)
                .overlay {
                    // 瓶身上的 WATER 竖排字
                    Text("WATER")
                        .font(.system(size: bottleW * 0.12, weight: .semibold))
                        .tracking(bottleW * 0.06)
                        .foregroundStyle(ink)
                        .rotationEffect(.degrees(90))
                        .offset(y: -bottleH * 0.02)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// 牛奶瓶轮廓：窄颈 + 圆肩 + 圆底
struct BottlePath: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let neckL = w * 0.34, neckR = w * 0.66
        let neckTop = h * 0.02, neckBottom = h * 0.20
        let shoulder = h * 0.34
        let bodyL = w * 0.08, bodyR = w * 0.92
        let bottom = h * 0.98

        p.move(to: CGPoint(x: neckL, y: neckTop))
        p.addLine(to: CGPoint(x: neckL, y: neckBottom))
        p.addQuadCurve(to: CGPoint(x: bodyL, y: shoulder),
                       control: CGPoint(x: neckL, y: neckBottom + (shoulder - neckBottom) * 0.85))
        p.addLine(to: CGPoint(x: bodyL, y: h * 0.82))
        p.addQuadCurve(to: CGPoint(x: w * 0.5, y: bottom),
                       control: CGPoint(x: bodyL, y: bottom))
        p.addQuadCurve(to: CGPoint(x: bodyR, y: h * 0.82),
                       control: CGPoint(x: bodyR, y: bottom))
        p.addLine(to: CGPoint(x: bodyR, y: shoulder))
        p.addQuadCurve(to: CGPoint(x: neckR, y: neckBottom),
                       control: CGPoint(x: neckR, y: neckBottom + (shoulder - neckBottom) * 0.85))
        p.addLine(to: CGPoint(x: neckR, y: neckTop))
        p.addQuadCurve(to: CGPoint(x: neckL, y: neckTop),
                       control: CGPoint(x: w * 0.5, y: h * 0.07))
        p.closeSubpath()
        return p
    }
}
