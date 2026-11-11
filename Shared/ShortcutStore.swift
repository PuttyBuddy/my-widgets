import Foundation
import WidgetKit

/// 通过 App Group 在主 App 和组件之间共享数据与设置
struct ShortcutStore {
    static let shared = ShortcutStore()
    static let appGroupID = "group.com.mywidgets.shared"

    private static let shortcutsKey = "shortcuts"
    private static let styleKey = "style"
    private static let shapeKey = "shape"
    private static let fontKey = "app_font"
    private static let appearanceKey = "app_appearance"
    private static let cityKey = "weather_city"
    private static let weatherKey = "weather_data"
    private static let waterCountKey = "water_count"
    private static let waterDateKey = "water_date"
    private static let waterGoalKey = "water_goal"

    private let defaults: UserDefaults?

    private init() {
        defaults = UserDefaults(suiteName: ShortcutStore.appGroupID)
    }

    // MARK: - 快捷方式

    func loadShortcuts() -> [Shortcut] {
        guard let data = defaults?.data(forKey: ShortcutStore.shortcutsKey),
              let list = try? JSONDecoder().decode([Shortcut].self, from: data) else {
            return Shortcut.presets
        }
        return list
    }

    func saveShortcuts(_ list: [Shortcut]) {
        guard let data = try? JSONEncoder().encode(list) else { return }
        defaults?.set(data, forKey: ShortcutStore.shortcutsKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - 风格 / 形状 / 字体 / 外观

    func loadStyle() -> WidgetStyle {
        if let raw = defaults?.string(forKey: ShortcutStore.styleKey),
           let style = WidgetStyle(rawValue: raw) {
            return style
        }
        return .glass
    }

    func saveStyle(_ style: WidgetStyle) {
        defaults?.set(style.rawValue, forKey: ShortcutStore.styleKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func loadShape() -> WidgetShape {
        if let raw = defaults?.string(forKey: ShortcutStore.shapeKey),
           let shape = WidgetShape(rawValue: raw) {
            return shape
        }
        return .roundedSquare
    }

    func saveShape(_ shape: WidgetShape) {
        defaults?.set(shape.rawValue, forKey: ShortcutStore.shapeKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func loadFont() -> AppFont {
        if let raw = defaults?.string(forKey: ShortcutStore.fontKey),
           let font = AppFont(rawValue: raw) {
            return font
        }
        return .system
    }

    func saveFont(_ font: AppFont) {
        defaults?.set(font.rawValue, forKey: ShortcutStore.fontKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func loadAppearance() -> AppAppearance {
        if let raw = defaults?.string(forKey: ShortcutStore.appearanceKey),
           let appearance = AppAppearance(rawValue: raw) {
            return appearance
        }
        return .system
    }

    func saveAppearance(_ appearance: AppAppearance) {
        defaults?.set(appearance.rawValue, forKey: ShortcutStore.appearanceKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - 天气

    func loadCity() -> String {
        let city = defaults?.string(forKey: ShortcutStore.cityKey) ?? ""
        return city.isEmpty ? "北京" : city
    }

    func saveCity(_ city: String) {
        defaults?.set(city, forKey: ShortcutStore.cityKey)
        WidgetCenter.shared.reloadTimelines(ofKind: "WeatherWidget")
    }

    func loadWeather() -> WeatherData? {
        guard let data = defaults?.data(forKey: ShortcutStore.weatherKey) else { return nil }
        return try? JSONDecoder().decode(WeatherData.self, from: data)
    }

    func saveWeather(_ weather: WeatherData) {
        guard let data = try? JSONEncoder().encode(weather) else { return }
        defaults?.set(data, forKey: ShortcutStore.weatherKey)
        WidgetCenter.shared.reloadTimelines(ofKind: "WeatherWidget")
    }

    // MARK: - 喝水

    func waterGoal() -> Int {
        let goal = defaults?.integer(forKey: ShortcutStore.waterGoalKey) ?? 0
        return goal > 0 ? goal : 8
    }

    func saveWaterGoal(_ goal: Int) {
        defaults?.set(max(1, goal), forKey: ShortcutStore.waterGoalKey)
        WidgetCenter.shared.reloadTimelines(ofKind: "WaterWidget")
    }

    /// 当前喝水杯数（跨天自动清零）
    func currentWater() -> Int {
        let today = Self.todayString()
        if defaults?.string(forKey: ShortcutStore.waterDateKey) != today {
            defaults?.set(0, forKey: ShortcutStore.waterCountKey)
            defaults?.set(today, forKey: ShortcutStore.waterDateKey)
        }
        return defaults?.integer(forKey: ShortcutStore.waterCountKey) ?? 0
    }

    func addWater(_ delta: Int) {
        let value = max(0, currentWater() + delta)
        defaults?.set(value, forKey: ShortcutStore.waterCountKey)
        WidgetCenter.shared.reloadTimelines(ofKind: "WaterWidget")
    }

    private static func todayString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }
}
