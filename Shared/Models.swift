import SwiftUI

/// 一个桌面快捷方式
struct Shortcut: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var emoji: String
    /// SF Symbol 名（iOS 系统图标库），非空时优先于 emoji 显示
    var symbol: String?
    var colorHex: String
    var urlString: String

    /// 把用户输入变成可跳转的 URL：没有 scheme 时自动补 "://"
    var url: URL? {
        let s = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        return s.contains("://") ? URL(string: s) : URL(string: s + "://")
    }

    /// SF Symbol 名（无则 nil）
    var symbolName: String? {
        if let s = symbol, !s.isEmpty { return s }
        return nil
    }

    /// 显示内容：emoji > 名称首字
    var glyph: String {
        emoji.isEmpty ? String(name.prefix(1)) : emoji
    }
}

/// 常用 App 预设（系统图标风格，彩色圆底 + 白色符号）
extension Shortcut {
    static let presets: [Shortcut] = [
        Shortcut(name: "微信", emoji: "", symbol: "message.fill", colorHex: "#07C160", urlString: "weixin://"),
        Shortcut(name: "支付宝", emoji: "", symbol: "creditcard.fill", colorHex: "#1677FF", urlString: "alipay://"),
        Shortcut(name: "淘宝", emoji: "", symbol: "bag.fill", colorHex: "#FF5000", urlString: "taobao://"),
        Shortcut(name: "哔哩哔哩", emoji: "", symbol: "play.tv.fill", colorHex: "#FB7299", urlString: "bilibili://"),
        Shortcut(name: "网易云音乐", emoji: "", symbol: "music.note", colorHex: "#DD0016", urlString: "orpheus://"),
        Shortcut(name: "抖音", emoji: "", symbol: "waveform", colorHex: "#1C1C1E", urlString: "snssdk1128://"),
        Shortcut(name: "YouTube", emoji: "", symbol: "play.fill", colorHex: "#FF3B30", urlString: "youtube://"),
        Shortcut(name: "Telegram", emoji: "", symbol: "paperplane.fill", colorHex: "#2AABEE", urlString: "tg://"),
        Shortcut(name: "Spotify", emoji: "", symbol: "music.note.list", colorHex: "#1DB954", urlString: "spotify://"),
        Shortcut(name: "信息", emoji: "", symbol: "message.fill", colorHex: "#34C759", urlString: "sms://"),
        Shortcut(name: "相机", emoji: "", symbol: "camera.fill", colorHex: "#6E6E73", urlString: "camera://"),
        Shortcut(name: "时钟", emoji: "", symbol: "clock.fill", colorHex: "#1C1C1E", urlString: "clock://"),
        Shortcut(name: "天气", emoji: "", symbol: "cloud.sun.fill", colorHex: "#4C9AFF", urlString: "weather://"),
        Shortcut(name: "日历", emoji: "", symbol: "calendar", colorHex: "#FF3B30", urlString: "calshow://"),
        Shortcut(name: "设置", emoji: "", symbol: "gearshape.fill", colorHex: "#8E8E93", urlString: "App-prefs://"),
        Shortcut(name: "浏览器", emoji: "", symbol: "safari", colorHex: "#3478F6", urlString: "https://www.google.com"),
    ]
}

/// 组件背景风格（rawValue 同时用作存储值和界面文案）
enum WidgetStyle: String, CaseIterable, Identifiable {
    case glass = "毛玻璃"
    case transparent = "透明"
    case dark = "深色"

    var id: String { rawValue }
}

/// 快捷图标形状
enum WidgetShape: String, CaseIterable, Identifiable {
    case roundedSquare = "圆角"
    case circle = "圆形"

    var id: String { rawValue }
}
