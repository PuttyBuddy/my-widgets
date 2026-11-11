import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var shortcuts: [Shortcut] = ShortcutStore.shared.loadShortcuts()
    @State private var style: WidgetStyle = ShortcutStore.shared.loadStyle()
    @State private var editorShortcut: Shortcut?
    @State private var editorIsNew = false

    private let palette = ["#0A84FF", "#30D158", "#FF9F0A", "#BF5AF2",
                           "#FF375F", "#5E5CE6", "#64D2FF", "#66D4CF",
                           "#FFD60A", "#8E8E93"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    styleSection
                    if !shortcuts.isEmpty { previewSection }
                    shortcutsSection
                    presetSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("我的小组件")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editorShortcut = Shortcut(name: "", emoji: "🚀", colorHex: "#0A84FF", urlString: "")
                        editorIsNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editorShortcut) { target in
                ShortcutEditor(shortcut: target, isNew: editorIsNew) { result in
                    applyEdit(of: target, result: result)
                }
            }
        }
    }

    // MARK: - 风格选择

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("组件风格").font(.headline)
            Picker("组件风格", selection: $style) {
                ForEach(WidgetStyle.allCases) { s in
                    Text(s.rawValue).tag(s)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: style) { _, newValue in
                ShortcutStore.shared.saveStyle(newValue)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
    }

    // MARK: - 桌面效果预览

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("桌面预览").font(.headline)
            LauncherGrid(shortcuts: shortcuts, columns: 4, textColor: .primary, emojiSize: 18)
                .frame(height: 130)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
        }
    }

    // MARK: - 快捷方式列表

    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("快捷方式（\(shortcuts.count)）").font(.headline)
            VStack(spacing: 0) {
                ForEach(shortcuts) { s in
                    row(s)
                    Divider().padding(.leading, 56)
                }
            }
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
        }
    }

    private func row(_ s: Shortcut) -> some View {
        Button {
            editorShortcut = s
            editorIsNew = false
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: s.colorHex))
                    .frame(width: 40, height: 40)
                    .overlay(Text(s.glyph).font(.system(size: 20)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.name).font(.body)
                    Text(s.urlString).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 预设快速添加

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("快速添加预设").font(.headline)
            let existing = Set(shortcuts.map(\.name))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
                ForEach(Shortcut.presets) { p in
                    Button {
                        ShortcutStore.shared.saveShortcuts(shortcuts + [p])
                        shortcuts = ShortcutStore.shared.loadShortcuts()
                    } label: {
                        VStack(spacing: 2) {
                            Text(p.emoji).font(.system(size: 22))
                            Text(p.name).font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .disabled(existing.contains(p.name))
                }
            }
        }
    }

    // MARK: - 编辑回调

    private func applyEdit(of target: Shortcut, result: Shortcut?) {
        if let result {
            if let i = shortcuts.firstIndex(where: { $0.id == result.id }) {
                shortcuts[i] = result
            } else {
                shortcuts.append(result)
            }
        } else {
            shortcuts.removeAll { $0.id == target.id }
        }
        ShortcutStore.shared.saveShortcuts(shortcuts)
    }
}

// MARK: - 编辑/新建快捷方式

struct ShortcutEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var shortcut: Shortcut
    private let isNew: Bool
    private let onSave: (Shortcut?) -> Void

    private let palette = ["#0A84FF", "#30D158", "#FF9F0A", "#BF5AF2",
                           "#FF375F", "#5E5CE6", "#64D2FF", "#66D4CF",
                           "#FFD60A", "#8E8E93"]

    init(shortcut: Shortcut, isNew: Bool, onSave: @escaping (Shortcut?) -> Void) {
        _shortcut = State(initialValue: shortcut)
        self.isNew = isNew
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("预览") {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: shortcut.colorHex))
                            .frame(width: 56, height: 56)
                            .overlay(Text(shortcut.glyph).font(.system(size: 26)))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(shortcut.name.isEmpty ? "未命名" : shortcut.name)
                                .font(.subheadline)
                            Text(shortcut.urlString.isEmpty ? "未设置 Scheme" : shortcut.urlString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("基本信息") {
                    TextField("名称（如：微信）", text: $shortcut.name)
                    TextField("Emoji（如 💬，可留空取首字）", text: $shortcut.emoji)
                    TextField("URL Scheme（如 weixin://）", text: $shortcut.urlString)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section("方块颜色") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 8)], spacing: 8) {
                        ForEach(palette, id: \.self) { hex in
                            Button {
                                shortcut.colorHex = hex
                            } label: {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: hex))
                                    .frame(height: 36)
                                    .overlay {
                                        if hex == shortcut.colorHex {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                if !isNew {
                    Section {
                        Button("删除这个快捷方式", role: .destructive) {
                            onSave(nil)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "添加快捷方式" : "编辑快捷方式")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        onSave(shortcut)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(shortcut.name.trimmingCharacters(in: .whitespaces).isEmpty
                              || shortcut.urlString.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
