import WidgetKit
import SwiftUI

// MARK: - 数据

struct WeatherEntry: TimelineEntry {
    let date: Date
    let data: WeatherData?
}

struct WeatherProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: .now, data: WeatherProvider.sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) {
        completion(WeatherEntry(date: .now, data: ShortcutStore.shared.loadWeather() ?? WeatherProvider.sample))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        let store = ShortcutStore.shared
        let city = store.loadCity()
        let cached = store.loadWeather()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now

        Task {
            var data = cached
            if let fresh = try? await WeatherService.fetchWeather(city: city) {
                store.saveWeather(fresh)
                data = fresh
            }
            completion(Timeline(entries: [WeatherEntry(date: .now, data: data)],
                                policy: .after(next)))
        }
    }

    static let sample = WeatherData(
        city: "北京", temp: 23, tempMin: 20, tempMax: 30, humidity: 50,
        windDir: "NE", precipProb: 30, uvIndex: 4,
        sunrise: "06:00", sunset: "18:00",
        conditionSymbol: "cloud.sun.fill", conditionText: "局部多云",
        hourlyTemps: [22, 22.5, 23, 24, 25, 26, 27, 27.5, 28, 27, 26, 25],
        fetchedAt: Date()
    )
}

// MARK: - 组件

struct WeatherWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeatherWidget", provider: WeatherProvider()) { entry in
            WeatherEntryView(entry: entry)
        }
        .configurationDisplayName("天气")
        .description("温度、紫外线指数、湿度、风向、降水和日出日落。城市在主 App 里设置。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct WeatherEntryView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var scheme
    var entry: WeatherEntry

    private var appearance: AppAppearance { ShortcutStore.shared.loadAppearance() }
    private var palette: WidgetPalette { WidgetPalette.resolve(appearance, scheme: scheme) }
    private var isDark: Bool {
        switch appearance {
        case .dark: return true
        case .light: return false
        case .system: return scheme == .dark
        }
    }
    private var font: AppFont { ShortcutStore.shared.loadFont() }

    var body: some View {
        Group {
            if let data = entry.data {
                switch family {
                case .systemLarge: largeCard(data)
                case .systemMedium: wideCard(data)
                default: smallCard(data)
                }
            } else {
                Text("打开主 App 设置城市")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.sub)
            }
        }
        .containerBackground(for: .widget) { palette.background }
    }

    // MARK: 大卡片（对标 Koco 大号天气）

    private func largeCard(_ data: WeatherData) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Image(systemName: data.conditionSymbol)
                        .font(.system(size: 40))
                        .foregroundStyle(conditionColor(data))
                    Text(data.conditionText)
                        .font(appFont(font, 12, .semibold))
                        .foregroundStyle(palette.sub)
                    Text(data.tempText)
                        .font(appFont(font, 30, .heavy))
                        .foregroundStyle(palette.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                UVIBar(value: data.uvIndex, ink: palette.ink, sub: palette.sub)
                    .frame(width: 30)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                          spacing: 8) {
                    badge("drop.fill", color: "#4ECDC4", value: "\(data.humidity)%")
                    badge("sunrise.fill", color: "#FFB56B", value: data.sunrise)
                    badge("moon.stars.fill", color: "#8E7CFF", value: data.sunset)
                    badge("wind", color: "#FF7EB3", value: data.windDir)
                    badge("umbrella.fill", color: "#6BB5FF", value: "\(data.precipProb)%")
                    badge("location.north.fill", color: "#4ED9A2", value: data.city)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(4)
    }

    // MARK: 宽条（对标 Koco 宽天气）

    private func wideCard(_ data: WeatherData) -> some View {
        HStack(spacing: 12) {
            Image(systemName: data.conditionSymbol)
                .font(.system(size: 30))
                .foregroundStyle(conditionColor(data))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("最高").font(.system(size: 11)).foregroundStyle(palette.sub)
                    Text(String(format: "%.0f°", data.tempMax)).font(appFont(font, 13, .bold)).foregroundStyle(.orange)
                }
                HStack(spacing: 4) {
                    Text("最低").font(.system(size: 11)).foregroundStyle(palette.sub)
                    Text(String(format: "%.0f°", data.tempMin)).font(appFont(font, 13, .bold)).foregroundStyle(Color(red: 0.35, green: 0.65, blue: 1))
                }
            }
            TempCurve(temps: data.hourlyTemps, ink: palette.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            VStack(alignment: .trailing, spacing: 2) {
                Text(data.city).font(appFont(font, 13, .bold)).foregroundStyle(palette.ink)
                HStack(spacing: 3) {
                    Image(systemName: "sunset.fill").font(.system(size: 10)).foregroundStyle(palette.sub)
                    Text(data.sunset).font(appFont(font, 12, .semibold)).foregroundStyle(palette.ink)
                }
            }
        }
        .padding(.horizontal, 6)
    }

    // MARK: 小号

    private func smallCard(_ data: WeatherData) -> some View {
        VStack(spacing: 4) {
            Image(systemName: data.conditionSymbol)
                .font(.system(size: 30))
                .foregroundStyle(conditionColor(data))
            Text(data.tempText)
                .font(appFont(font, 34, .heavy))
                .monospacedDigit()
                .foregroundStyle(palette.ink)
            Text(data.city)
                .font(appFont(font, 12, .semibold))
                .foregroundStyle(palette.ink.opacity(0.85))
            HStack(spacing: 8) {
                Label("\(data.humidity)%", systemImage: "drop.fill")
                Label("\(data.precipProb)%", systemImage: "umbrella.fill")
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(palette.sub)
        }
    }

    // MARK: - 部件

    private func badge(_ symbol: String, color: String, value: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: color))
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color(hex: color).opacity(isDark ? 0.22 : 0.16)))
            Text(value)
                .font(.system(size: 10, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    private func conditionColor(_ data: WeatherData) -> Color {
        switch data.conditionSymbol {
        case "sun.max.fill": return .yellow
        case "cloud.sun.fill": return isDark ? Color(white: 0.85) : Color(hex: "#3E9BFF")
        case "cloud.fill", "cloud.fog.fill": return isDark ? Color(white: 0.75) : .gray
        default: return isDark ? Color(white: 0.8) : Color(hex: "#5B8DEF")
        }
    }
}

// MARK: - 紫外线渐变条

struct UVIBar: View {
    let value: Double
    let ink: Color
    let sub: Color

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            VStack(alignment: .leading, spacing: 2) {
                Text("UVI").font(.system(size: 9, weight: .bold)).foregroundStyle(sub)
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [Color(red: 0.62, green: 0.55, blue: 0.95),
                                     Color(red: 0.95, green: 0.45, blue: 0.45),
                                     Color(red: 0.98, green: 0.75, blue: 0.35),
                                     Color(red: 0.45, green: 0.85, blue: 0.55)],
                            startPoint: .top, endPoint: .bottom))
                    // 当前值刻度点
                    let fraction = min(1, max(0, value / 11))
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .shadow(color: .black.opacity(0.3), radius: 1)
                        .offset(y: (h - 46) * fraction)
                        .padding(.vertical, 17)
                }
                .frame(maxHeight: .infinity)
                Text(String(format: "%.0f", value))
                    .font(.system(size: 11, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(ink)
                Text("LOW").font(.system(size: 8, weight: .bold)).foregroundStyle(sub)
            }
        }
    }
}

// MARK: - 温度曲线

struct TempCurve: View {
    let temps: [Double]
    let ink: Color

    var body: some View {
        GeometryReader { geo in
            let vals = temps.isEmpty ? [0.0, 0.0] : temps
            ZStack {
                curvePath(vals, in: geo.size)
                    .stroke(ink.opacity(0.65), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                Circle().fill(Color.orange).frame(width: 6, height: 6)
                    .position(point(at: 0, vals: vals, size: geo.size))
                Circle().fill(Color.orange).frame(width: 6, height: 6)
                    .position(point(at: vals.count - 1, vals: vals, size: geo.size))
            }
        }
    }

    private func point(at index: Int, vals: [Double], size: CGSize) -> CGPoint {
        guard !vals.isEmpty else { return CGPoint(x: 0, y: 0) }
        let lo = vals.min() ?? 0, hi = vals.max() ?? 1
        let span = max(1, hi - lo)
        let i = min(max(0, index), vals.count - 1)
        let x = size.width * CGFloat(i) / CGFloat(max(1, vals.count - 1))
        let y = size.height * (1 - CGFloat((vals[i] - lo) / span)) * 0.8 + size.height * 0.1
        return CGPoint(x: x, y: y)
    }

    private func curvePath(_ vals: [Double], in size: CGSize) -> Path {
        var path = Path()
        guard !vals.isEmpty else { return path }
        let lo = vals.min() ?? 0, hi = vals.max() ?? 1
        let span = max(1, hi - lo)
        for (i, t) in vals.enumerated() {
            let x = size.width * CGFloat(i) / CGFloat(max(1, vals.count - 1))
            let y = size.height * (1 - CGFloat((t - lo) / span)) * 0.8 + size.height * 0.1
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}
