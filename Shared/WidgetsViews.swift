import SwiftUI
import UIKit

/// 一枚图标：真实 App 图标 > SF Symbol > Emoji > 名称首字，点击行为由调用方决定
struct ShortcutTile: View {
    let shortcut: Shortcut
    var shape: WidgetShape = .roundedSquare
    var iconSize: CGFloat = 24
    /// 点击后打开的目标（nil = 不可点）
    var linkURL: URL? = nil
    /// 小工具内交互总开关
    var interactive: Bool = true

    var body: some View {
        tileContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                // iOS 26 上 Link 直接贴在内容上会吞掉点击（渲染模式冲突），
                // 垫一层透明矩形再挂 Link 才能正常拉起目标 App
                if interactive, let url = linkURL {
                    Link(destination: url) {
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                    }
                }
            }
            .opacity(linkURL == nil ? 0.35 : 1)
            .accessibilityLabel(shortcut.name)
    }

    @ViewBuilder
    private var tileContent: some View {
        iconBackground
            .aspectRatio(1, contentMode: .fit)
            .overlay { iconContent }
            .clipShape(clipShape)
    }

    private var clipShape: AnyShape {
        switch shape {
        case .roundedSquare:
            return AnyShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        case .circle:
            return AnyShape(Circle())
        }
    }

    private var iconBackground: some View {
        clipShape.fill(Color(hex: shortcut.colorHex))
    }

    @ViewBuilder
    private var iconContent: some View {
        if let assetName = shortcut.iconAsset, let img = UIImage(named: assetName) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else if let symbolName = shortcut.symbolName {
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
    var actionMode: ActionMode = .preset
    var interactive: Bool = true

    var body: some View {
        VStack(spacing: 8) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 8) {
                    ForEach(rows[rowIndex]) { s in
                        ShortcutTile(shortcut: s, shape: shape, iconSize: iconSize,
                                     linkURL: s.effectiveURL(actionMode), interactive: interactive)
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
