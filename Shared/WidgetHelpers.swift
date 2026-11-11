import SwiftUI

/// 全局字体：按 AppFont 设置返回 SwiftUI 字体
func appFont(_ settings: AppFont, _ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
    switch settings {
    case .rounded: return .system(size: size, weight: weight, design: .rounded)
    case .serif: return .system(size: size, weight: weight, design: .serif)
    case .system: return .system(size: size, weight: weight)
    }
}

/// 农历日期字符串，如 "十月初四"
func lunarDateString(_ date: Date) -> String {
    let cal = Calendar(identifier: .chinese)
    let comps = cal.dateComponents([.month, .day, .isLeapMonth], from: date)
    let month = comps.month ?? 1
    let day = comps.day ?? 1
    let isLeap = comps.isLeapMonth ?? false
    let months = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"]
    let days = ["初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
                "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
                "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"]
    let mIdx = min(max(month, 1), 12) - 1
    let mName = (isLeap ? "闰" : "") + months[mIdx]
    return mName + "月" + days[min(max(day, 1), 30) - 1]
}

/// 公历日期 + 星期，如 "11月12日 周四"
func gregorianDateString(_ date: Date) -> String {
    let fmt = DateFormatter()
    fmt.locale = Locale(identifier: "zh_CN")
    fmt.dateFormat = "M月d日 EEE"
    return fmt.string(from: date)
}

/// 时钟/天气组件的配色（按外观设置解析）
struct WidgetPalette {
    let background: Color
    let ink: Color        // 主文字
    let sub: Color        // 次要文字

    static func resolve(_ appearance: AppAppearance, scheme: ColorScheme) -> WidgetPalette {
        let isDark: Bool
        switch appearance {
        case .dark: isDark = true
        case .light: isDark = false
        case .system: isDark = scheme == .dark
        }
        if isDark {
            return WidgetPalette(
                background: Color(red: 0.11, green: 0.11, blue: 0.13),
                ink: .white,
                sub: Color(white: 1, opacity: 0.55)
            )
        }
        return WidgetPalette(
            background: Color(red: 0.98, green: 0.98, blue: 0.99),
            ink: Color(red: 0.10, green: 0.10, blue: 0.12),
            sub: Color(white: 0, opacity: 0.45)
        )
    }
}
