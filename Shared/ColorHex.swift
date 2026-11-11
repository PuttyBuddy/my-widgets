import SwiftUI

extension Color {
    /// 支持 #RRGGBB 十六进制颜色
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        if s.count == 6 {
            self.init(red: r, green: g, blue: b)
        } else {
            self.init(red: 1, green: 1, blue: 1)
        }
    }
}
