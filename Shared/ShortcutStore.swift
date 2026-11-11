import Foundation
import WidgetKit

/// 通过 App Group 在主 App 和组件之间共享数据
struct ShortcutStore {
    static let shared = ShortcutStore()
    static let appGroupID = "group.com.mywidgets.shared"

    private static let shortcutsKey = "shortcuts"
    private static let styleKey = "style"

    private let defaults: UserDefaults?

    private init() {
        defaults = UserDefaults(suiteName: ShortcutStore.appGroupID)
    }

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
}
