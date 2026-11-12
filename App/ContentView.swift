import SwiftUI
import WidgetKit
import PhotosUI

struct ContentView: View {
    enum AppTab: Int, CaseIterable, Identifiable {
        case apps, style, actions

        var id: Int { rawValue }
        var icon: String {
            switch self {
            case .apps: return "square.grid.2x2.fill"
            case .style: return "globe.asia.australia.fill"
            case .actions: return "hand.tap.fill"
            }
        }
        var label: String {
            switch self {
            case .apps: return "应用"
            case .style: return "图标与背景"
            case .actions: return "动作"
            }
        }
    }

    @State private var tab: AppTab = .apps
    @State private var shortcuts: [Shortcut] = ShortcutStore.shared.loadShortcuts()
    @State private var shape: WidgetShape = ShortcutStore.shared.loadShape()
    @State private var layout: LauncherLayout = ShortcutStore.shared.loadLauncherLayout()
    @State private var appFontChoice: AppFont = ShortcutStore.shared.loadFont()
    @State private var appearance: AppAppearance = ShortcutStore.shared.loadAppearance()
    @State private var actionMode: ActionMode = ShortcutStore.shared.loadActionMode()
    @State private var keepInteractions: Bool = ShortcutStore.shared.loadKeepInteractions()
    @State private var city: String = ShortcutStore.shared.loadCity()
    @State private var waterGoal: Int = ShortcutStore.shared.waterGoal()
    @State private var weatherStatus: String = ""
    @State private var weatherLoading = false
    @State private var bgItem: PhotosPickerItem?
    @State private var bgThumb: UIImage?
    @State private var editorShortcut: Shortcut?
    @State private var editorIsNew = false

    private let palette = ["#0A84FF", "#30D158", "#FF9F0A", "#BF5AF2",
                           "#FF375F", "#5E5CE6", "#64D2FF", "#66D4CF",
                           "#FFD60A", "#8E8E93"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                tabBar
                Group {
                    switch tab {
                    case .apps: appsTab
                    case .style: styleTab
                    case .actions: actionsTab
                    }
                }
            }
            .padding(.horizontal)
            .background(kocoPageBackground)
            .navigationTitle("我的小组件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if tab == .apps {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            editorShortcut = Shortcut(name: "", emoji: "", symbol: nil, colorHex: "#0A84FF", urlString: "")
                            editorIsNew = true
                        } label: {
                            Image(systemName: "plus")
                        }
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
                if bgThumb == nil {
                    bgThumb = ShortcutStore.shared.loadBackgroundImage()
                }
            }
        }
    }

    // MARK: - Koco 风格页面底色

    private var kocoPageBackground: some View {
        Color(red: 0.925, green: 0.92, blue: 0.965).ignoresSafeArea()
    }

    // MARK: - Koco 风格顶部页签

    private var tabBar: some View {
        HStack(spacing: 18) {
            ForEach(AppTab.allCases) { t in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { tab = t }
                } label: {
                    Image(systemName: t.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(tab == t ? Color(.systemBackground) : Color.primary)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(tab == t ? Color.primary : Color(.systemBackground)))
                }
                .accessibilityLabel(t.label)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 12)
        .background(Capsule().fill(Color(.systemBackground)))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }

    // MARK: - Koco 风格分段选择器（白色胶囊条 + 灰色选中块）

    private func kocoSegment(options: [(icon: String, label: String)],
                             selection: Binding<Int>) -> some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { i in
                Button {
                    selection.wrappedValue = i
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: options[i].icon)
                            .font(.system(size: 13, weight: .semibold))
                        Text(options[i].label)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(selection.wrappedValue == i ? Color.primary : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14)
                        .fill(selection.wrappedValue == i ? Color(.systemGray5) : .clear))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
    }

    // MARK: - 白色圆角卡片

    private func kocoCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
    }

    private func kocoLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 15, weight: .bold)).foregroundStyle(.primary)
    }

    // MARK: - 页签一：应用

    private var appsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !shortcuts.isEmpty { previewSection }
                shortcutsSection
                presetSection
                weatherSection
                waterSection
            }
            .padding(.vertical)
        }
    }

    // MARK: - 页签二：图标与背景

    private var styleTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                previewSection

                kocoLabel("图标形状（苹果预设 = 圆方）")
                kocoCard {
                    kocoSegment(
                        options: [("square.fill", "预设"), ("circle.fill", "圆形")],
                        selection: Binding(
                            get: { shape == .roundedSquare ? 0 : 1 },
                            set: { shape = $0 == 0 ? .roundedSquare : .circle }
                        )
                    )
                }

                kocoLabel("大组件布局")
                kocoCard {
                    kocoSegment(
                        options: [("square.grid.3x3.fill", "网格"), ("circle.grid.cross.fill", "气泡")],
                        selection: Binding(
                            get: { layout == .grid ? 0 : 1 },
                            set: { layout = $0 == 0 ? .grid : .bubble }
                        )
                    )
                }

                kocoLabel("字体")
                kocoCard {
                    kocoSegment(
                        options: [("textformat", "默认"), ("textformat.size", "圆体"), ("textformat.alt", "衬线")],
                        selection: Binding(
                            get: { AppFont.allCases.firstIndex(of: appFontChoice) ?? 0 },
                            set: { appFontChoice = AppFont.allCases[$0] }
                        )
                    )
                    .onChange(of: appFontChoice) { _, newValue in
                        ShortcutStore.shared.saveFont(newValue)
                    }
                }

                kocoLabel("外观")
                kocoCard {
                    kocoSegment(
                        options: [("circle.lefthalf.filled", "跟随系统"), ("sun.max.fill", "浅色"), ("moon.fill", "深色")],
                        selection: Binding(
                            get: { AppAppearance.allCases.firstIndex(of: appearance) ?? 0 },
                            set: { appearance = AppAppearance.allCases[$0] }
                        )
                    )
                    .onChange(of: appearance) { _, newValue in
                        ShortcutStore.shared.saveAppearance(newValue)
                    }
                }

                backgroundSection

                Button {
                    WidgetCenter.shared.reloadAllTimelines()
                } label: {
                    Label("添加并试用小工具", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color(red: 0.09, green: 0.09, blue: 0.11)))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical)
        }
    }

    // MARK: - 背景（对标 Koco 背景页：只保留图片）

    private var backgroundSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            kocoLabel("背景（仅在实底小工具生效）")
            kocoSegment(options: [("photo.fill", "图片")], selection: .constant(0))
            PhotosPicker(selection: $bgItem, matching: .images) {
                Label("从照片中选择", systemImage: "photo.badge.plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 999).fill(Color(.systemBackground)))
            }
            .buttonStyle(.plain)
            .onChange(of: bgItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        ShortcutStore.shared.saveBackgroundImage(data)
                        bgThumb = ShortcutStore.shared.loadBackgroundImage()
                    }
                    bgItem = nil
                }
            }
            if let thumb = bgThumb {
                HStack(spacing: 12) {
                    Image(uiImage: thumb)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 42)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Text("已设置图片背景")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("清除", role: .destructive) {
                        ShortcutStore.shared.clearBackgroundImage()
                        bgThumb = nil
                    }
                    .font(.footnote)
                }
            }
        }
    }

    // MARK: - 页签三：动作

    private var actionsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                kocoLabel("点按动作")
                kocoCard {
                    VStack(alignment: .leading, spacing: 10) {
                        kocoSegment(
                            options: [("app.fill", "预设动作"), ("link", "自订跳转"), ("minus.circle", "停用动作")],
                            selection: Binding(
                                get: { ActionMode.allCases.firstIndex(of: actionMode) ?? 0 },
                                set: { actionMode = ActionMode.allCases[$0] }
                            )
                        )
                        .onChange(of: actionMode) { _, newValue in
                            ShortcutStore.shared.saveActionMode(newValue)
                        }
                        Text(actionHint)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }

                kocoCard {
                    Toggle(isOn: $keepInteractions) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("保留小工具内操作").font(.body)
                            Text("开启后，小工具内的跳转、按钮和捷径操作仍会回应。")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onChange(of: keepInteractions) { _, newValue in
                        ShortcutStore.shared.saveKeepInteractions(newValue)
                    }
                }

                Button {
                    WidgetCenter.shared.reloadAllTimelines()
                } label: {
                    Label("添加并试用小工具", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color(red: 0.09, green: 0.09, blue: 0.11)))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical)
        }
    }

    private var actionHint: String {
        switch actionMode {
        case .preset:
            return "点击图标按应用预设的方式打开（URL Scheme）。"
        case .custom:
            return "点击图标优先打开你在应用页里填写的自订跳转地址；没填的应用退回预设打开。"
        case .disabled:
            return "所有图标点击都不做跳转，仅作展示。"
        }
    }

    // MARK: - 桌面效果预览（白卡 + 真实图标，锁定中组件真实比例 338:158）

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            kocoLabel("预览（中组件实际尺寸）")
            LauncherGrid(shortcuts: Array(shortcuts.prefix(21)), columns: 7, shape: shape, iconSize: 13,
                         actionMode: .preset, interactive: false)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 22).fill(Color(.systemBackground)))
                .aspectRatio(338.0 / 158.0, contentMode: .fit)
        }
    }

    // MARK: - 快捷方式列表

    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                kocoLabel("快捷方式（\(shortcuts.count)）")
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
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
        }
    }

    private func row(_ s: Shortcut) -> some View {
        Button {
            editorShortcut = s
            editorIsNew = false
        } label: {
            HStack(spacing: 12) {
                ShortcutTile(shortcut: s, shape: shape, iconSize: 18,
                             linkURL: nil, interactive: false)
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.name).font(.body)
                    Text(actionMode == .custom && s.customUrl?.isEmpty == false ? (s.customUrl ?? "") : s.urlString)
                        .font(.caption).foregroundStyle(.secondary)
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
            kocoLabel("快速添加预设")
            let existing = Set(shortcuts.map(\.name))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
                ForEach(Shortcut.presets) { p in
                    Button {
                        ShortcutStore.shared.saveShortcuts(shortcuts + [p])
                        shortcuts = ShortcutStore.shared.loadShortcuts()
                    } label: {
                        VStack(spacing: 4) {
                            ShortcutTile(shortcut: p, shape: .circle, iconSize: 20,
                                         linkURL: nil, interactive: false)
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

    // MARK: - 天气城市

    private var weatherSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            kocoLabel("天气组件")
            kocoCard {
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
            }
        }
    }

    private func refreshWeather() async {
        weatherLoading = true
        weatherStatus = "正在获取 \(city) 的天气…"
        do {
            let data = try await WeatherService.fetchWeather(city: ShortcutStore.shared.loadCity())
            ShortcutStore.shared.saveWeather(data)
            weatherStatus = "✅ \(data.city) \(data.conditionText) \(data.tempText)，湿度 \(data.humidity)%"
        } catch {
            weatherStatus = "⚠️ 获取失败：\(error.localizedDescription)，组件会先用缓存数据"
        }
        weatherLoading = false
    }

    // MARK: - 喝水目标

    private var waterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            kocoLabel("喝水组件")
            kocoCard {
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
                        ShortcutTile(shortcut: shortcut, shape: shape, iconSize: 26,
                                     linkURL: nil, interactive: false)
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
                    TextField("自订跳转（可选，动作=自订跳转时优先）", text: customUrlBinding)
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
                        if iconMode == .emoji {
                            shortcut.symbol = nil
                        } else if (shortcut.symbol?.isEmpty ?? true) {
                            shortcut.symbol = "star.fill"
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

    private var customUrlBinding: Binding<String> {
        Binding(
            get: { shortcut.customUrl ?? "" },
            set: { shortcut.customUrl = $0.trimmingCharacters(in: .whitespaces).isEmpty ? nil : $0 }
        )
    }
}
