import SwiftUI

/// 一个桌面快捷方式：图标 + 颜色 + 跳转链接
struct Shortcut: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var emoji: String
    var colorHex: String
    var urlString: String

    /// 把用户输入变成可跳转的 URL：没有 scheme 时自动补 "://"
    var url: URL? {
        let s = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        return s.contains("://") ? URL(string: s) : URL(string: s + "://")
    }

    /// 显示在方块上的字符：优先 emoji，否则取名称首字
    var glyph: String {
        emoji.isEmpty ? String(name.prefix(1)) : emoji
    }
}

/// 常用 App 预设（Scheme 都可以在 App 里随时改）
extension Shortcut {
    static let presets: [Shortcut] = [
        Shortcut(name: "微信", emoji: "💬", colorHex: "#07C160", urlString: "weixin://"),
        Shortcut(name: "支付宝", emoji: "💳", colorHex: "#1677FF", urlString: "alipay://"),
        Shortcut(name: "淘宝", emoji: "🛍️", colorHex: "#FF5000", urlString: "taobao://"),
        Shortcut(name: "哔哩哔哩", emoji: "📺", colorHex: "#FB7299", urlString: "bilibili://"),
        Shortcut(name: "网易云音乐", emoji: "🎧", colorHex: "#DD0016", urlString: "orpheus://"),
        Shortcut(name: "抖音", emoji: "🎵", colorHex: "#161823", urlString: "snssdk1128://"),
        Shortcut(name: "YouTube", emoji: "▶️", colorHex: "#FF0000", urlString: "youtube://"),
        Shortcut(name: "Telegram", emoji: "✈️", colorHex: "#2AABEE", urlString: "tg://"),
        Shortcut(name: "Spotify", emoji: "🎧", colorHex: "#1DB954", urlString: "spotify://"),
        Shortcut(name: "浏览器", emoji: "🌐", colorHex: "#5856D6", urlString: "https://www.google.com"),
    ]
}

/// 组件背景风格（rawValue 同时用作存储值和界面文案）
enum WidgetStyle: String, CaseIterable, Identifiable {
    case glass = "毛玻璃"
    case transparent = "透明"
    case dark = "深色"

    var id: String { rawValue }
}
