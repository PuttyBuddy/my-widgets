import SwiftUI

/// 一枚图标：彩色圆底/圆角底 + SF Symbol 或 emoji，整块可点击直接跳转
struct ShortcutTile: View {
    let shortcut: Shortcut
    var shape: WidgetShape = .roundedSquare
    var iconSize: CGFloat = 24

    var body: some View {
        tileContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                // iOS 26 上 Link 直接贴在内容上会吞掉点击（渲染模式冲突），
                // 垫一层透明矩形再挂 Link 才能正常拉起目标 App
                if let url = shortcut.url {
                    Link(destination: url) {
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                    }
                }
            }
            .opacity(shortcut.url == nil ? 0.35 : 1)
            .accessibilityLabel(shortcut.name)
    }

    @ViewBuilder
    private var tileContent: some View {
        iconBackground
            .aspectRatio(1, contentMode: .fit)
            .overlay { iconContent }
    }

    @ViewBuilder
    private var iconBackground: some View {
        switch shape {
        case .roundedSquare:
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: shortcut.colorHex))
        case .circle:
            Circle()
                .fill(Color(hex: shortcut.colorHex))
        }
    }

    @ViewBuilder
    private var iconContent: some View {
        if let symbolName = shortcut.symbolName {
            Image(systemName: symbolName)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(.white)
        } else {
            Text(shortcut.glyph)
                .font(.system(size: iconSize, weight: .medium))
                .minimumScaleFactor(0.5)
        }
    }
}

/// N 列图标网格（组件和主 App 预览共用）
struct LauncherGrid: View {
    let shortcuts: [Shortcut]
    let columns: Int
    var shape: WidgetShape = .roundedSquare
    var iconSize: CGFloat = 24

    var body: some View {
        VStack(spacing: 8) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 8) {
                    ForEach(rows[rowIndex]) { s in
                        ShortcutTile(shortcut: s, shape: shape, iconSize: iconSize)
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
