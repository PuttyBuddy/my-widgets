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
        daily: [
            DayForecast(weekday: "周四", symbol: "cloud.sun.fill", min: 20, max: 30),
            DayForecast(weekday: "周五", symbol: "sun.max.fill", min: 20, max: 30),
            DayForecast(weekday: "周六", symbol: "cloud.sun.fill", min: 18, max: 28),
            DayForecast(weekday: "周日", symbol: "cloud.rain.fill", min: 15, max: 25),
            DayForecast(weekday: "周一", symbol: "cloud.sun.fill", min: 17, max: 26),
            DayForecast(weekday: "周二", symbol: "sun.max.fill", min: 19, max: 29),
            DayForecast(weekday: "周三", symbol: "cloud.rain.fill", min: 16, max: 24)
        ],
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
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge,
                            .accessoryInline, .accessoryRectangular, .accessoryCircular])
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
                case .systemLarge, .systemMedium: weekCard(data)
                case .accessoryInline: inlinePill(data)
                case .accessoryRectangular: rectangularPill(data)
                case .accessoryCircular: circularUV(data)
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

    // MARK: 主卡片（左：实况；右上：湿度/降水/UVI；底部：一周预报）

    private func weekCard(_ data: WeatherData) -> some View {
        let big = family == .systemLarge
        let days = data.daily ?? []
        return VStack(alignment: .leading, spacing: big ? 10 : 6) {
            HStack(alignment: .top, spacing: 8) {
                // 左列：实况（图标与温度并排，对齐参考图）
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: big ? 10 : 7) {
                        Image(systemName: data.conditionSymbol)
                            .font(.system(size: big ? 34 : 27))
                            .foregroundStyle(conditionColor(data))
                        Text(data.tempText)
                            .font(appFont(font, big ? 36 : 28, .heavy))
                            .monospacedDigit()
                            .foregroundStyle(palette.ink)
                    }
                    Text("\(data.city), \(data.conditionText)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(palette.sub)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    HStack(spacing: 6) {
                        Text("↓ " + String(format: "%.0f°", data.tempMin))
                            .font(.system(size: 11, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(Color(hex: "#3E9BFF"))
                        Text("↑ " + String(format: "%.0f°", data.tempMax))
                            .font(.system(size: 11, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(Color(hex: "#FF7A59"))
                    }
                }
                Spacer(minLength: 4)
                // 右上：湿度 / 降水 / UVI
                HStack(spacing: big ? 12 : 8) {
                    metricBadge("drop.fill", "#4ECDC4", "\(data.humidity)%")
                    metricBadge("umbrella.fill", "#6BB5FF", "\(data.precipProb)%")
                    metricBadge("sun.max.fill", "#FF9F0A", data.uvText)
                }
            }
            Divider().opacity(0.15)
            // 底部：一周天气
            if days.isEmpty {
                Text("在主 App 里刷新一次天气")
                    .font(.system(size: 11))
                    .foregroundStyle(palette.sub)
                    .frame(maxWidth: .infinity)
            } else {
                HStack(spacing: 0) {
                    ForEach(days) { d in
                        VStack(spacing: 3) {
                            Text(d.weekday)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(palette.sub)
                                .lineLimit(1)
                            Image(systemName: d.symbol)
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: "#3E9BFF"))
                            Text(String(format: "%.0f-%.0f°", d.min, d.max))
                                .font(.system(size: 9, weight: .semibold))
                                .monospacedDigit()
                                .foregroundStyle(palette.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func metricBadge(_ symbol: String, _ colorHex: String, _ value: String) -> some View {
        let big = family == .systemLarge
        return VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: big ? 13 : 11, weight: .semibold))
                .foregroundStyle(Color(hex: colorHex))
                .frame(width: big ? 32 : 26, height: big ? 32 : 26)
                .background(Circle().fill(Color(hex: colorHex).opacity(isDark ? 0.25 : 0.15)))
            Text(value)
                .font(.system(size: big ? 13 : 11, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    // MARK: 锁屏胶囊（对标 Koco 胶囊组）

    private func inlinePill(_ data: WeatherData) -> some View {
        Text("\(data.humidity)% | \(data.precipProb)%")
    }

    private func rectangularPill(_ data: WeatherData) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(data.city)
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(1)
                Text("\(data.tempText) \(data.conditionText)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 3) {
                Text("UVI \(data.uvText)")
                    .font(.system(size: 11, weight: .bold))
                    .monospacedDigit()
                UVBar(value: data.uvIndex, ink: .primary, sub: .secondary)
                    .frame(width: 46, height: 12)
            }
        }
    }

    private func circularUV(_ data: WeatherData) -> some View {
        ZStack {
            Circle()
                .stroke(uvGradient, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .opacity(0.9)
            VStack(spacing: 0) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 11))
                Text(data.uvText)
                    .font(.system(size: 16, weight: .heavy))
                    .monospacedDigit()
            }
        }
        .padding(4)
    }

    private var uvGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.62, green: 0.55, blue: 0.95),
                     Color(red: 0.95, green: 0.45, blue: 0.45),
                     Color(red: 0.98, green: 0.75, blue: 0.35)],
            startPoint: .bottom, endPoint: .top
        )
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

// MARK: - 温度曲线（备用，当前布局未使用）
