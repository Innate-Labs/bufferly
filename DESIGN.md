# Bufferly Design Specification

版本：v0.1  
日期：2026-06-04  
状态：Draft  
目标平台：macOS  
设计目标：尽可能接近 Apple 原生体验  

## 1. 设计原则

Bufferly 的 UI 不追求炫技，不做网页感、SaaS 感或重型素材库。它应该像一个系统级 macOS 工具：安静、快速、清晰、可键盘驱动，并且在任何工作流里出现和消失都不打扰。

核心原则：

- 原生优先：使用 SwiftUI / AppKit 原生控件、系统字体、系统颜色和平台交互习惯。
- 内容优先：剪贴板内容是主角，装饰元素必须克制。
- 键盘优先：搜索、选择、粘贴、关闭、pin、删除都必须可以用键盘完成。
- 低打扰：面板呼出后快速完成任务，完成后自动隐藏。
- 本地可信：隐私和敏感内容状态要清楚，但不要制造焦虑。
- 高信息密度：像 Raycast 一样快，像 Paste 一样能扫读历史，但更开发者向。

## 2. Apple 原生约束

设计和实现应遵守以下 macOS 习惯：

- 使用系统字体：`.system` / SF Pro，不自定义品牌字体。
- 使用系统颜色：`primary`, `secondary`, `tertiary`, `accentColor`, `windowBackgroundColor`, `separatorColor` 等。
- 支持 Light / Dark / Auto 外观。
- 尊重系统 Accent Color，不强行指定高饱和品牌主色。
- 使用 vibrancy / material 时保持克制，避免模糊过强影响可读性。
- 窗口、菜单、快捷键、键盘导航遵守 macOS 平台预期。
- 主流程必须支持 Full Keyboard Access 语义。

## 3. 视觉方向

关键词：

- Native
- Quiet
- Precise
- Fast
- Dense
- Trustworthy

避免：

- 大面积渐变背景
- Web dashboard 风格
- 过度圆角卡片
- 明显 Tailwind/Web UI 味道
- 玻璃拟态过重导致文字不清楚
- 大标题营销页风格
- 花哨图标和插画

## 4. 核心界面

### 4.1 Quick Panel

Quick Panel 是 Bufferly 的核心界面，按全局快捷键呼出。

> 方向变更（见 §16-(a)）：自 v0.2 起 Quick Panel 由「居中竖向列表」改为 **Paste 式底部横向卡片墙**。下文已按新方向描述。

建议尺寸：

- 高度：约 392 pt（固定）。
- 宽度：按当前屏幕宽度铺开，左右各留 24 pt 边距，最大 1280 pt。
- 卡片：宽 200 pt、高 272 pt，横向排列。

位置：

- 贴当前屏幕**底部**居中，距底部约 24 pt（类似 Paste 的底部条）。
- 多显示器场景下显示在当前鼠标所在屏幕。

窗口行为：

- 非文档窗口。
- 不显示标准标题栏。
- 失焦后可自动隐藏，设置里允许关闭。
- `Esc` 关闭。
- 回车完成粘贴后自动关闭。

视觉：

- 背景使用 macOS material。
- 整体圆角约 20 pt，贴近系统浮层。
- 卡片为主角：彩色头部 + 白色正文，圆角 14 pt，轻阴影；选中卡片抬起放大并加 accentColor 描边。
- 外阴影轻，强调层级但不要漂浮感过强。

结构：

```text
+--------------------------------------------------------------+
| [search]            [剪贴板 | 已固定]  pinboard tabs     [x]  |
+--------------------------------------------------------------+
|  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐   →          |
|  │ type   │  │ type   │  │ type   │  │ type   │   横向滚动    |
|  │ time   │  │ time   │  │ time   │  │ time   │              |
|  ├────────┤  ├────────┤  ├────────┤  ├────────┤              |
|  │preview │  │preview │  │preview │  │preview │              |
|  │ source▸│  │ source▸│  │ source▸│  │ source▸│              |
|  └────────┘  └────────┘  └────────┘  └────────┘              |
+--------------------------------------------------------------+
| Footer: count / ←→ 选择 / Return 粘贴 / ⌘P 固定 / Esc 关闭    |
+--------------------------------------------------------------+
```

### 4.2 Search Field

搜索框是默认焦点。

要求：

- 呼出面板后立即可输入。
- Placeholder：`Search clips`
- 输入时实时过滤结果。
- 支持 `Command + F` 聚焦搜索，但默认已聚焦。
- 支持清空按钮。

视觉：

- 使用接近 `NSSearchField` 的样式。
- 高度 36-40 pt。
- 左侧搜索图标使用系统符号。
- 不做夸张边框。

### 4.3 Clip Card

> 方向变更（见 §16-(a)）：信息单元由「紧凑行」改为 **Paste 式卡片**。原 §4.3 Clip Row 的「不使用大卡片堆叠」已被本次决定否决。

Clip Card 是卡片墙的信息单元，富预览、可扫读。

尺寸：

- 宽 200 pt、高 272 pt，固定，避免横向滚动时跳动。

结构：

- 头部（高约 62 pt）：按类型着色（见 §9 类型色），显示类型名（白色粗体）+ 相对时间 + 右上类型图标。
- 正文（白色）：富预览，代码 / JSON / 命令用等宽字体，最多 8 行；底部一行显示来源 App + pin 按钮。

状态：

- Default：轻阴影，略微缩小（0.965）。
- Selected：抬起到原始大小 + accentColor 描边 + 更强阴影，并自动滚入视野中央。
- Pinned：pin 图标点亮为 accentColor。
- Sensitive blocked：正文用 lock 图标和脱敏文案，不显示明文。

### 4.4 Type Badge

类型标识要小而清楚，避免彩虹标签。

类型：

- Text
- URL
- JSON
- CMD
- Code
- Email
- Secret

建议：

- 使用 SF Symbols 图标 + 极短文本。
- Badge 宽度稳定，避免列表抖动。
- 色彩以系统 secondary/tertiary 为主。
- 只有 Secret 使用更明确的警示语义，但仍保持克制。

### 4.5 Pinned Area

Pinned 是主动复用区，不是历史区。

规则：

- 默认最多展示 3-5 条。
- 搜索时 pinned 也参与过滤。
- Pinned 区域为空时不显示大面积 empty state，只显示 Recent。
- Pin 操作可通过 `Command + P` 或行内按钮触发。

### 4.6 Recent Area

Recent 是默认历史流。

规则：

- 按最近复制时间倒序。
- 相同内容去重并更新 `updatedAt`。
- 右侧时间使用短格式：`now`, `2m`, `1h`, `Yesterday`。
- 长文本只显示前两行，详情后续用 Quick Look / Detail Popover。

### 4.7 Footer

Footer 只放辅助信息。

可显示：

- 当前结果数量。
- 当前选中项动作提示。
- 敏感过滤状态，例如 `Sensitive filter on`。

不要显示：

- 大段帮助文本。
- 产品宣传语。
- 功能说明。

## 5. 设置页

设置页使用 macOS 原生 Settings 风格。

分组：

1. General
   - Launch at login
   - Hide after paste
   - Max history count

2. Shortcuts
   - Show Bufferly
   - Pin selected clip
   - Delete selected clip
   - Paste as plain text

3. Privacy
   - Sensitive filtering
   - Store blocked placeholder
   - Clear history
   - Excluded apps

4. Developer
   - JSON formatting
   - URL tracking cleanup
   - Command detection
   - Code detection

视觉：

- 使用系统表单控件。
- 使用 sidebar 或 tab settings 取决于实现成本。
- 不自定义复杂设置组件。

## 6. 交互规则

### 6.1 快捷键

默认建议：

- 呼出 / 隐藏：`Option + Space`

备选：

- `Control + Space` 可能与输入法冲突，不建议默认。
- `Command + Shift + V` 常被“粘贴为纯文本”占用，不建议默认。

### 6.2 键盘操作

主面板：

- `Esc`：关闭。
- `Arrow Left / Right`：在卡片墙左右移动选中项（`Up / Down` 作为等效别名，见 §16-(a)）。
- `Enter`：复制并尝试粘贴选中项。
- `Option + Enter`：只复制到剪贴板，不自动粘贴。
- `Command + Enter`：粘贴为纯文本。
- `Command + P`：Pin / Unpin。
- `Command + Delete`：删除。
- `Command + K`：打开动作菜单。
- `Command + ,`：打开设置。

### 6.3 鼠标操作

- 单击选中。
- 双击粘贴。
- Hover 时显示行内操作。
- 右键显示上下文菜单。

上下文菜单：

- Paste
- Copy
- Paste as Plain Text
- Pin / Unpin
- Format JSON
- Clean URL
- Delete

## 7. 内容预览规则

### 7.1 Plain Text

- 保留原文本换行，但预览最多两行。
- 连续空白折叠为单个空格。

### 7.2 URL

- 主预览显示 domain + path。
- 次要信息显示完整 URL 或标题，后续可抓取。
- 动作：Clean URL。

### 7.3 JSON

- 合法 JSON 显示 `{}` icon。
- 预览显示第一层 key 或压缩后的前缀。
- 动作：Format JSON / Minify JSON。

### 7.4 Command

- 常见命令如 `git`, `npm`, `pnpm`, `cargo`, `swift`, `xcodebuild`, `curl` 标记为 CMD。
- 保留 monospace 预览。

### 7.5 Code

- 多行、含明显语法符号或代码关键字时标记为 Code。
- 不在 MVP 做完整语法高亮，避免性能和复杂度过早上升。

### 7.6 Sensitive

- 命中敏感规则时不显示原文。
- 预览文案：`Sensitive content hidden`
- 显示 lock icon。
- 默认不保存明文。

## 8. 动效

动效必须短、轻、系统感。

- 面板出现：80-120ms opacity + scale 0.98 -> 1。
- 面板关闭：60-90ms opacity。
- 卡片选择：~120ms ease-out 的抬起 / 缩放过渡（见 §16-(a)），无弹跳。
- 选中卡片滚入视野：~160ms ease-out。
- 删除：轻微 fade/collapse，避免夸张动画。
- 搜索结果变化：优先即时更新，不做复杂过渡。

禁止：

- 弹性过强的 spring。
- 长时间模糊动画。
- 大面积渐变动效。
- 卡片飞入飞出式的入场动画（卡片选中抬起不在此列）。

## 9. 颜色与材质

不要定义一套重品牌色。Bufferly 应跟随系统。

建议：

- Background：system window background / material。
- Text primary：system primary label。
- Text secondary：secondary label。
- Separator：system separator。
- Selected：accentColor 描边（卡片墙）。
- Warning / Secret：system red or orange，仅用于状态点和 icon。

类型色（卡片头部，见 §16-(a)）：

- 仅用于卡片彩色头部，正文与列表其余部分仍跟随系统语义色，不扩散成全局品牌色。
- Text：blue / URL：green / JSON：purple / Command：石墨灰 / Code：indigo / Email：pink / Secret：orange。
- 头部一律白色文字，所选颜色需保证对比度。

Dark Mode：

- 不手写独立暗色 palette。
- 使用系统语义色。
- 验证 selected row、Secret row、footer 在深色下的对比。

## 10. 图标

优先使用 SF Symbols。

建议映射：

- Search：`magnifyingglass`
- Pin：`pin`
- URL：`link`
- JSON：`curlybraces`
- Command：`terminal`
- Code：`chevron.left.forwardslash.chevron.right`
- Email：`envelope`
- Secret：`lock`
- Delete：`trash`
- Settings：`gearshape`
- Clean URL：`wand.and.stars` 或 `sparkles`

图标规则：

- 不自绘 SVG。
- 不使用彩色插画图标。
- 工具按钮必须有 accessibility label。

## 11. 空状态与错误状态

### 11.1 首次打开

空状态要克制：

```text
No clips yet
Copied text will appear here.
```

不要放大插画，不放营销文案。

### 11.2 无搜索结果

```text
No matching clips
```

### 11.3 权限缺失

如果自动粘贴需要 Accessibility 权限：

- 用系统风格提示。
- 清楚说明只需要权限来把选中内容粘贴回前台 App。
- 提供打开 System Settings 的按钮。
- 没权限时仍允许“复制到剪贴板”。

## 12. Accessibility

必须支持：

- VoiceOver 可读行内容、类型、pin 状态、敏感状态。
- 所有按钮有 label。
- 主要流程可纯键盘完成。
- 选中状态不仅靠颜色表达。
- 遵守 Reduce Motion。
- 遵守 Increase Contrast。

## 13. Implementation Notes

建议 SwiftUI 组件边界：

```text
BufferlyApp
AppDelegate
QuickPanelWindowController
ClipboardMonitor
ClipStore
ClipClassifier
SensitiveContentFilter
GlobalShortcutManager
QuickPanelView
SearchFieldView
ClipRowView
PinnedSectionView
RecentSectionView
SettingsView
```

优先实现静态 UI，再接真实数据：

1. QuickPanelView with mock clips。
2. ClipRow states。
3. Search filtering。
4. Pin / delete mock actions。
5. ClipboardMonitor。
6. Persistence。
7. Global shortcut。

## 14. Design Acceptance Checklist

MVP UI 验收：

- 看起来像 macOS 原生工具，而不是网页套壳。
- 呼出面板后搜索框立即聚焦。
- 500 条历史仍能快速搜索和滚动。
- 只用键盘能完成找回并粘贴。
- Light / Dark 都可读。
- 长文本不会撑乱布局。
- Secret 内容不会泄露明文。
- 设置页符合 macOS 设置习惯。
- 没有大面积渐变、营销式 hero、装饰性插画。

## 15. References

- Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines
- Apple HIG - Windows: https://developer.apple.com/design/Human-Interface-Guidelines/windows
- Apple HIG - Keyboards: https://developer.apple.com/design/human-interface-guidelines/keyboards
- Paste: https://pasteapp.io — 视觉与交互的主要参照（卡片墙、Pinboard、富预览）。

## 16. 修订日志

### (a) v0.2：Quick Panel 从 Raycast 式竖向列表转向 Paste 式横向卡片墙

日期：2026-06-05  
决策人：项目所有者（明确选择「真正向 Paste 看齐」）。

**改了什么**

- 面板从「屏幕居中浮层 + 竖向紧凑行列表」改为「屏幕底部横向卡片墙」。
- 信息单元从 Clip Row（紧凑行）改为 Clip Card（彩色头部 + 白色正文的卡片）。
- 键盘导航主方向从上下改为左右。
- 顶部新增 Pinboard 分段标签（剪贴板 / 已固定）。
- 新增按类型的卡片头部色（§9 类型色）。

**为什么改**

- 原 v0.1 只取了 Paste 的「可视化历史」概念，刻意用 Raycast 式竖向列表实现，并主动驳回了 Paste 的卡片形态。
- 实际使用后，项目所有者希望直接对齐 Paste 的具体样式（富预览、可横向扫读、来源与类型一眼可辨），认为卡片墙比紧凑行更符合产品期望。这是基于真实使用偏好的方向调整，优先级高于 v0.1 当初的取舍。

**因此被否决/取代的原 v0.1 条款**

- §4.1「屏幕水平居中」「略高于中心，类似 Spotlight / Raycast」「内部不要再嵌套大卡片」——改为底部卡片墙。
- §4.3「不使用大卡片堆叠」——改为正式采用卡片。
- §3 避免清单「过度圆角卡片」——卡片为主角，14 pt 圆角属正常范围；仍避免「过度」与 Web 卡片味。
- §8「卡片飞入飞出」——仅保留禁止「入场动画式」的飞入飞出；卡片选中抬起是允许的。
- §6.2 上下导航——主方向改为左右。

**仍然保留的原则（未被本次推翻）**

- 原生优先、键盘优先、低打扰、本地可信、高信息密度。
- 跟随系统语义色：类型色只用于卡片头部，不扩散成全局品牌色；正文仍用系统色。
- 不自定义品牌字体、支持 Light / Dark、尊重 Reduce Motion / Increase Contrast。
- 不做营销 hero、不做 Web dashboard 味、玻璃拟态不过重影响可读性。

### (b) v0.3：全面对齐 macOS 26（Tahoe）Liquid Glass 范式

日期：2026-06-05
决策人：项目所有者（「完全按照 Apple 范式来」「全部都 Apple」）。

**改了什么**

- 部署目标提到 `macOS 26`，作为完整的 macOS 26 app（`Package.swift` + 打包 `LSMinimumSystemVersion`）。
- 顶部控件接入官方 Liquid Glass：搜索框用 `.glassEffect(in: Capsule())`，分段控件用系统 `.pickerStyle(.segmented)`（系统自动套玻璃）。
- 面板底层保持 `.thinMaterial` 实底（不是玻璃），玻璃只留给浮在内容之上的控件层——遵守官方「玻璃用于控件层、内容层不用玻璃、不堆叠玻璃」。
- 顶部控件改用 SF Symbols + 原生组件，去掉自绘 PNG 图标封装（删除 RemixIcon / NativeSearchField 等）。
- 搜索框定为常驻玻璃药丸（曾尝试「默认收起、点击展开」，因收起态不好看回退；见对话）。
- 去掉右上角关闭按钮：呼出式浮层靠 Esc / 点外部 / 再按快捷键关闭，不放关闭按钮（Spotlight / Raycast 范式）。
- 去掉顶栏下的硬 `Divider`：Tahoe 浮动工具栏让内容从下方透出，不用硬分割线。
- 顶部控件内边距与卡片墙对齐为 20pt，符合同心圆 `外圆34 = 内圆 + 边距`，分段控件不再顶到 34pt 外圆弧；搜索药丸与分段控件用 `.controlSize(.large)` 配齐高度读成一排。
- 卡片选中描边 3pt → 2pt，更贴近 Apple 选中惯例（仍以「描边 + 抬起 + 阴影」非颜色方式表达选中，满足 §12）。

**为什么改**

- 项目所有者要求「完全按照 Apple 范式」，且开发机已是 macOS 26（SDK / 部署目标可用真正的 Liquid Glass）。
- 对照官方 Liquid Glass 文档审查：架构层（玻璃只给控件层、内容卡片实底、不堆叠玻璃）本就合规，本次主要修掉「不够 Tahoe」的细节（硬分割线、控件尺寸/对齐、字号过大、冗余关闭按钮）。

**仍然保留的原则（未被本次推翻）**

- (a) 的 Paste 式彩色卡片墙不变：彩色头部仅用于内容卡片，不是玻璃，不与「玻璃只给控件层」冲突。
- 原生优先、键盘优先、低打扰、尊重 Reduce Motion / Increase Contrast；系统组件自动适配「降低透明度」。

参考：Apple「Liquid Glass」技术总览 https://developer.apple.com/documentation/TechnologyOverviews/liquid-glass
