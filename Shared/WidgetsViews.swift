import SwiftUI

/// 组件里的一格：点击后直接跳转目标 App（Link 会用 URL Scheme 拉起对应应用）
struct ShortcutTile: View {
    let shortcut: Shortcut
    let textColor: Color
    var emojiSize: CGFloat = 24

    var body: some View {
        Group {
            if let url = shortcut.url {
                Link(destination: url) { tileBody }
            } else {
                tileBody.opacity(0.35)
            }
        }
    }

    private var tileBody: some View {
        VStack(spacing: 3) {
            Text(shortcut.glyph)
                .font(.system(size: emojiSize, weight: .medium))
                .minimumScaleFactor(0.5)
            Text(shortcut.name)
                .font(.system(size: 9, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(textColor)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: shortcut.colorHex))
        )
    }
}

/// N 列网格（组件和主 App 预览共用）
struct LauncherGrid: View {
    let shortcuts: [Shortcut]
    let columns: Int
    let textColor: Color
    var emojiSize: CGFloat = 24

    var body: some View {
        VStack(spacing: 6) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    ForEach(rows[rowIndex]) { s in
                        ShortcutTile(shortcut: s, textColor: textColor, emojiSize: emojiSize)
                    }
                }
            }
        }
    }

    private var rows: [[Shortcut]] {
        stride(from: 0, to: shortcuts.count, by: columns).map { start in
            Array(shortcuts[start..<min(start + columns, shortcuts.count)])
        }
    }
}
