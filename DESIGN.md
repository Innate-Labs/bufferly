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

建议尺寸：

- 默认宽度：720 pt
- 最小宽度：600 pt
- 最大宽度：840 pt
- 默认高度：520 pt
- 最大高度：屏幕高度的 70%

位置：

- 屏幕水平居中。
- 垂直位置略高于中心，类似 Spotlight / Raycast。
- 多显示器场景下显示在当前鼠标或前台 App 所在屏幕。

窗口行为：

- 非文档窗口。
- 不显示标准标题栏。
- 失焦后可自动隐藏，设置里允许关闭。
- `Esc` 关闭。
- 回车完成粘贴后自动关闭。

视觉：

- 背景使用 macOS material 或 window background。
- 圆角建议 16 pt 左右，贴近系统浮层。
- 外阴影轻，强调层级但不要漂浮感过强。
- 内部不要再嵌套大卡片。

结构：

```text
+------------------------------------------------------+
| Search field                                         |
+------------------------------------------------------+
| Pinned                                               |
| [type] preview text                         shortcut |
| [type] preview text                         shortcut |
+------------------------------------------------------+
| Recent                                               |
| [type] preview text                 source/time/actions |
| [type] preview text                 source/time/actions |
| [type] preview text                 source/time/actions |
+------------------------------------------------------+
| Footer: count / selected action / privacy state      |
+------------------------------------------------------+
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

### 4.3 Clip Row

Clip Row 是主面板的信息单元，不使用大卡片堆叠。

行高：

- 普通文本：52 pt
- 多行预览：最高 76 pt
- Pinned 区域行高保持一致，避免视觉跳动。

内容：

- 左侧 type badge / icon。
- 中间 preview，最多 2 行。
- 右侧显示时间、来源 App、操作按钮。

状态：

- Default：透明或轻微背景。
- Hover：系统 fill 色轻微提高。
- Selected：使用 accentColor 的低透明背景，文字仍保持高对比。
- Pinned：显示 pin 状态，不改变主色调。
- Sensitive blocked：使用 lock 图标和脱敏文案，不显示明文。

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
- `Arrow Up / Down`：移动选中项。
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
- 列表选择：无弹跳，仅背景色过渡。
- 删除：轻微 fade/height collapse，避免夸张动画。
- 搜索结果变化：优先即时更新，不做复杂过渡。

禁止：

- 弹性过强的 spring。
- 长时间模糊动画。
- 大面积渐变动效。
- 卡片飞入飞出。

## 9. 颜色与材质

不要定义一套重品牌色。Bufferly 应跟随系统。

建议：

- Background：system window background / material。
- Text primary：system primary label。
- Text secondary：secondary label。
- Separator：system separator。
- Selected：accentColor with low opacity。
- Warning / Secret：system red or orange，仅用于状态点和 icon。

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
- Paste: reference for visual clipboard history, search, and pinned reusable content.
