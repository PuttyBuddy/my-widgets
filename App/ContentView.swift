import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var shortcuts: [Shortcut] = ShortcutStore.shared.loadShortcuts()
    @State private var style: WidgetStyle = ShortcutStore.shared.loadStyle()
    @State private var shape: WidgetShape = ShortcutStore.shared.loadShape()
    @State private var appFontChoice: AppFont = ShortcutStore.shared.loadFont()
    @State private var appearance: AppAppearance = ShortcutStore.shared.loadAppearance()
    @State private var city: String = ShortcutStore.shared.loadCity()
    @State private var waterGoal: Int = ShortcutStore.shared.waterGoal()
    @State private var weatherStatus: String = ""
    @State private var weatherLoading = false
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
                    weatherSection
                    waterSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("我的小组件")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editorShortcut = Shortcut(name: "", emoji: "", symbol: nil, colorHex: "#0A84FF", urlString: "")
                        editorIsNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editorShortcut) { target in
                ShortcutEditor(shortcut: target, isNew: editorIsNew, shape: shape) { result in
                    applyEdit(of: target, result: result)
                }
            }
            .task {
                if ShortcutStore.shared.loadWeather() == nil {
                    await refreshWeather()
                }
            }
        }
    }

    // MARK: - 风格与形状

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
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
            Picker("图标形状", selection: $shape) {
                ForEach(WidgetShape.allCases) { s in
                    Text(s.rawValue).tag(s)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: shape) { _, newValue in
                ShortcutStore.shared.saveShape(newValue)
            }
            Picker("字体", selection: $appFontChoice) {
                ForEach(AppFont.allCases) { f in
                    Text(f.label).tag(f)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: appFontChoice) { _, newValue in
                ShortcutStore.shared.saveFont(newValue)
            }
            Picker("外观", selection: $appearance) {
                ForEach(AppAppearance.allCases) { a in
                    Text(a.label).tag(a)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: appearance) { _, newValue in
                ShortcutStore.shared.saveAppearance(newValue)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
    }

    // MARK: - 天气城市

    private var weatherSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("天气组件").font(.headline)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    TextField("城市名，如：上海", text: $city)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .onSubmit { ShortcutStore.shared.saveCity(city) }
                    Button("保存") { ShortcutStore.shared.saveCity(city) }
                        .buttonStyle(.bordered)
                }
                Button {
                    Task { await refreshWeather() }
                } label: {
                    if weatherLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("刷新天气数据").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(weatherLoading)
                if !weatherStatus.isEmpty {
                    Text(weatherStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
        }
    }

    private func refreshWeather() async {
        weatherLoading = true
        weatherStatus = "正在获取 \(city) 的天气…"
        do {
            let data = try await WeatherService.fetchWeather(city: ShortcutStore.shared.loadCity())
            ShortcutStore.shared.saveWeather(data)
            weatherStatus = "✅ \(data.city) \(data.conditionText) \(data.tempText)，湿度 \(data.humidity)%，日出 \(data.sunrise)"
        } catch {
            weatherStatus = "⚠️ 获取失败：\(error.localizedDescription)，组件会先用缓存数据"
        }
        weatherLoading = false
    }

    // MARK: - 喝水目标

    private var waterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("喝水组件").font(.headline)
            HStack {
                Text("每日目标：\(waterGoal) 杯")
                Spacer()
                Stepper("", onIncrement: {
                    waterGoal += 1
                    ShortcutStore.shared.saveWaterGoal(waterGoal)
                }, onDecrement: {
                    waterGoal = max(1, waterGoal - 1)
                    ShortcutStore.shared.saveWaterGoal(waterGoal)
                })
                .fixedSize()
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
        }
    }

    // MARK: - 桌面效果预览

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("桌面预览").font(.headline)
            LauncherGrid(shortcuts: shortcuts, columns: 5, shape: shape, iconSize: 18)
                .frame(height: 170)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
        }
    }

    // MARK: - 快捷方式列表

    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("快捷方式（\(shortcuts.count)）").font(.headline)
                Spacer()
                Button("重置为预设") {
                    shortcuts = Shortcut.presets
                    ShortcutStore.shared.saveShortcuts(shortcuts)
                }
                .font(.footnote)
            }
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
                ShortcutTile(shortcut: s, shape: shape, iconSize: 18)
                    .frame(width: 40, height: 40)
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
                        VStack(spacing: 4) {
                            ShortcutTile(shortcut: p, shape: .circle, iconSize: 20)
                                .frame(width: 36, height: 36)
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
    enum IconMode: String, CaseIterable, Identifiable {
        case symbol = "系统图标"
        case emoji = "Emoji"
        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var shortcut: Shortcut
    @State private var iconMode: IconMode
    private let isNew: Bool
    private let shape: WidgetShape
    private let onSave: (Shortcut?) -> Void

    private let palette = ["#0A84FF", "#30D158", "#FF9F0A", "#BF5AF2",
                           "#FF375F", "#5E5CE6", "#64D2FF", "#66D4CF",
                           "#FFD60A", "#8E8E93"]

    private let symbolCatalog = ["message.fill", "envelope.fill", "phone.fill", "camera.fill",
                                 "music.note", "music.note.list", "headphones", "play.fill",
                                 "play.tv.fill", "tv", "podcast", "book.fill",
                                 "gamecontroller.fill", "cart.fill", "bag.fill", "creditcard.fill",
                                 "banknote.fill", "fork.knife", "cup.and.saucer.fill", "car.fill",
                                 "airplane", "figure.walk", "house.fill", "gearshape.fill",
                                 "wifi", "moon.fill", "sun.max.fill", "cloud.sun.fill",
                                 "bolt.fill", "clock.fill", "calendar", "timer",
                                 "map.fill", "safari", "photo.fill", "heart.fill",
                                 "star.fill", "paintpalette.fill", "pencil", "note.text",
                                 "doc.text.fill", "folder.fill", "briefcase.fill", "graduationcap.fill",
                                 "pills.fill", "dumbbell.fill", "sportscourt.fill", "leaf.fill",
                                 "paperplane.fill", "waveform", "sparkles", "lightbulb.fill",
                                 "gift.fill", "ticket.fill", "scissors", "link"]

    init(shortcut: Shortcut, isNew: Bool, shape: WidgetShape, onSave: @escaping (Shortcut?) -> Void) {
        _shortcut = State(initialValue: shortcut)
        _iconMode = State(initialValue: isNew || shortcut.symbolName != nil ? .symbol : .emoji)
        self.isNew = isNew
        self.shape = shape
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("预览") {
                    HStack(spacing: 12) {
                        ShortcutTile(shortcut: shortcut, shape: shape, iconSize: 26)
                            .frame(width: 56, height: 56)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(shortcut.name.isEmpty ? "未命名" : shortcut.name)
                                .font(.subheadline)
                            Text(shortcut.urlString.isEmpty ? "未设置 Scheme" : shortcut.urlString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("图标") {
                    Picker("图标类型", selection: $iconMode) {
                        ForEach(IconMode.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    if iconMode == .symbol {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: 8)], spacing: 8) {
                            ForEach(symbolCatalog, id: \.self) { sym in
                                Button {
                                    shortcut.symbol = sym
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(hex: shortcut.colorHex))
                                        Image(systemName: sym)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundStyle(.white)
                                    }
                                    .frame(height: 48)
                                    .overlay {
                                        if shortcut.symbol == sym {
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.primary, lineWidth: 2)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        TextField("Emoji（如 💬）", text: $shortcut.emoji)
                    }
                }
                Section("基本信息") {
                    TextField("名称（如：微信）", text: $shortcut.name)
                    TextField("URL Scheme（如 weixin://）", text: $shortcut.urlString)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section("背景颜色") {
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
                        if iconMode == .emoji {
                            shortcut.symbol = nil
                        } else if (shortcut.symbol?.isEmpty ?? true) {
                            shortcut.symbol = "star.fill"   // 符号模式没选时给个默认
                        }
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
