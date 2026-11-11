# MyWidgets — 自用 iOS 小组件（对标 Koco Widgets 核心玩法）

完全属于自己的桌面小组件 App：**点击组件图标直接跳转对应 App**，零广告、零付费、设计随你改。
代码推送到 GitHub，由 GitHub Actions 的 macOS 云端编译出 `.ipa`，再用 Sideloadly 装到 iPhone。

## 功能（v1）

| 功能 | 说明 |
|---|---|
| 快速启动组件 | 小号 2×2、中号 4×2、大号 4×3 网格，**点图标直达目标 App**（URL Scheme，无二次跳转） |
| 锁屏圆形组件 | 显示并跳转第一个快捷方式 |
| 三种背景风格 | 毛玻璃（跟随系统深浅色）/ 透明（透出壁纸）/ 深色 |
| 自定义快捷方式 | 名称、Emoji 图标、方块颜色、URL Scheme，支持删除 |
| 预设一键添加 | 微信 / 支付宝 / 淘宝 / B站 / 网易云 / 抖音 / YouTube / Telegram / Spotify… |

## 目录结构

```
project.yml                    XcodeGen 工程定义（不提交 .xcodeproj，由它生成）
App/                           主 App（编辑快捷方式、切换风格）
Widget/                        WidgetKit 小组件扩展
Shared/                        两边共用：数据模型 / App Group 存储 / 网格视图
tools/gen-icon.ps1             重新生成 App 图标
.github/workflows/build.yml    GitHub Actions 云端编译
```

数据通过 App Group `group.com.mywidgets.shared` 在主 App 和组件之间共享。

## 发布流程（每周 1 分钟）

### 1. 推送到 GitHub
```bash
git add .
git commit -m "update"
git push
```
Actions 会自动编译；进度见仓库的 **Actions** 页。完成后在该次运行页面底部
**Artifacts** 下载 `MyWidgets-ipa.zip`，解压得到 `MyWidgets-unsigned.ipa`。

### 2. 用 Sideloadly 安装到 iPhone
1. 数据线连接 iPhone（已在电脑上点过"信任"）
2. 打开 Sideloadly → 把 `.ipa` 拖进去
3. 填入你的 Apple ID（普通免费账号即可）
4. 点 **Start**，等进度条走完，iPhone 上出现"我的组件"
5. 首次安装需在手机上信任证书：**设置 → 通用 → VPN与设备管理 → 点你的 Apple ID → 信任**

### 3. 添加小组件
长按桌面空白处 → **+** → 搜"快速启动" → 选尺寸添加。
（锁定屏幕：长按锁屏 → 自定 → 添加小组件）

### 4. 7 天重签
免费 Apple ID 的签名 **7 天过期**，到期图标会变灰、组件失效。
重签 = 手机连电脑 → Sideloadly 里对同一个 ipa 再点一次 Start（数据不会丢）。

## 自己改设计

- **加组件样式**：改 `Widget/MyWidgetsWidget.swift` 里的 `background` / `content`
- **改图标**：改 `tools/gen-icon.ps1` 后重新运行它
- **加新组件类型**：在 `Widget/MyWidgetsBundle.swift` 注册新 Widget
- **改预设 App**：`Shared/Models.swift` 的 `presets`

## 已知限制

- 透明风格透出的是壁纸（iOS 组件没有真正的"镂空"能力，和 Koco 的原理一致）
- URL Scheme 跳转要求目标 App 自己注册了 scheme（常见大厂 App 都有；找不到 scheme 的 App 可以用"复制链接"类方案，后续版本可加）
- 免费账号：7 天重签 / 同设备最多 3 个侧载 App / 每周 10 个 App ID

## Troubleshooting

| 现象 | 处理 |
|---|---|
| Sideloadly 识别不到手机 | 重插数据线；手机上重新点"信任"；确认 Apple Mobile Device Service 在运行 |
| 安装后打开闪退/提示不受信任 | 设置 → 通用 → VPN与设备管理 → 信任开发者证书 |
| 组件显示"无可用内容" | 先打开一次主 App 再添加组件；确认 App Group 正常 |
| Actions 编译失败 | 看 Actions 页红叉的日志；通常是 Swift 语法或签名设置问题 |
