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
    /// 自订跳转地址（动作模式为"自订跳转"时优先使用）
    var customUrl: String?
    /// 打包在 App 里的真实应用图标资源名（如 icon_weixin），优先级最高
    var iconAsset: String?

    /// 把用户输入变成可跳转的 URL：没有 scheme 时自动补 "://"
    var url: URL? {
        let s = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        return s.contains("://") ? URL(string: s) : URL(string: s + "://")
    }

    /// 按全局动作模式算出点击后的目标
    func effectiveURL(_ mode: ActionMode) -> URL? {
        switch mode {
        case .disabled:
            return nil
        case .preset:
            return url
        case .custom:
            if let c = customUrl?.trimmingCharacters(in: .whitespacesAndNewlines), !c.isEmpty {
                return c.contains("://") ? URL(string: c) : URL(string: c + "://")
            }
            return url
        }
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

/// 图标点按动作模式（对标 Koco 點按動作）
enum ActionMode: String, CaseIterable, Identifiable {
    case preset = "preset"
    case custom = "custom"
    case disabled = "disabled"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .preset: return "预设动作"
        case .custom: return "自订跳转"
        case .disabled: return "停用动作"
        }
    }
}

/// 常用 App 预设（真实图标从 App Store 拉取后打包，见 tools/fetch-icons.ps1）
extension Shortcut {
    static let presets: [Shortcut] = [
        Shortcut(name: "微信", emoji: "💬", symbol: nil, colorHex: "#07C160", urlString: "weixin://", iconAsset: "icon_weixin"),
        Shortcut(name: "支付宝", emoji: "💳", symbol: nil, colorHex: "#1677FF", urlString: "alipay://", iconAsset: "icon_zhifubao"),
        Shortcut(name: "淘宝", emoji: "🛍️", symbol: nil, colorHex: "#FF5000", urlString: "taobao://", iconAsset: "icon_taobao"),
        Shortcut(name: "哔哩哔哩", emoji: "📺", symbol: nil, colorHex: "#FB7299", urlString: "bilibili://", iconAsset: "icon_bilibili"),
        Shortcut(name: "网易云音乐", emoji: "🎧", symbol: nil, colorHex: "#DD0016", urlString: "orpheus://", iconAsset: "icon_wangyiyun"),
        Shortcut(name: "抖音", emoji: "🎵", symbol: nil, colorHex: "#1C1C1E", urlString: "snssdk1128://", iconAsset: "icon_douyin"),
        Shortcut(name: "小红书", emoji: "📕", symbol: nil, colorHex: "#FF2442", urlString: "xhsdiscover://", iconAsset: "icon_xhs"),
        Shortcut(name: "拼多多", emoji: "🛒", symbol: nil, colorHex: "#E02E24", urlString: "pinduoduo://", iconAsset: "icon_pdd"),
        Shortcut(name: "美团", emoji: "🍔", symbol: nil, colorHex: "#FFC300", urlString: "imeituan://", iconAsset: "icon_meituan"),
        Shortcut(name: "京东", emoji: "📦", symbol: nil, colorHex: "#E1251B", urlString: "openapp.jdmobile://", iconAsset: "icon_jd"),
        Shortcut(name: "微博", emoji: "🔥", symbol: nil, colorHex: "#E6162D", urlString: "sinaweibo://", iconAsset: "icon_weibo"),
        Shortcut(name: "QQ", emoji: "🐧", symbol: nil, colorHex: "#12B7F5", urlString: "mqq://", iconAsset: "icon_qq"),
        Shortcut(name: "高德地图", emoji: "🗺️", symbol: nil, colorHex: "#00B6C9", urlString: "iosamap://", iconAsset: "icon_gaode"),
        Shortcut(name: "YouTube", emoji: "▶️", symbol: nil, colorHex: "#FF3B30", urlString: "youtube://", iconAsset: "icon_youtube"),
        Shortcut(name: "Telegram", emoji: "✈️", symbol: nil, colorHex: "#2AABEE", urlString: "tg://", iconAsset: "icon_telegram"),
        Shortcut(name: "Spotify", emoji: "🎧", symbol: nil, colorHex: "#1DB954", urlString: "spotify://", iconAsset: "icon_spotify"),
        Shortcut(name: "信息", emoji: "💬", symbol: nil, colorHex: "#34C759", urlString: "sms://", iconAsset: nil),
        Shortcut(name: "相机", emoji: "📷", symbol: nil, colorHex: "#6E6E73", urlString: "camera://", iconAsset: nil),
        Shortcut(name: "时钟", emoji: "⏰", symbol: nil, colorHex: "#3A3A3C", urlString: "clock://", iconAsset: nil),
        Shortcut(name: "设置", emoji: "⚙️", symbol: nil, colorHex: "#8E8E93", urlString: "App-prefs://", iconAsset: nil),
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

    /// 界面文案：预设 = 苹果圆方，圆形 = 正圆
    var label: String {
        switch self {
        case .roundedSquare: return "预设"
        case .circle: return "圆形"
        }
    }
}

/// 快速启动组件的大尺寸布局
enum LauncherLayout: String, CaseIterable, Identifiable {
    case grid = "网格"
    case bubble = "气泡"

    var id: String { rawValue }
}

/// 组件字体
enum AppFont: String, CaseIterable, Identifiable {
    case system = "Default"
    case rounded = "Round"
    case serif = "Serif"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "默认"
        case .rounded: return "圆体"
        case .serif: return "衬线"
        }
    }
}

/// 组件外观
enum AppAppearance: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }
}
