# Bufferly

**为开发者和 AI 工作流打造的本地优先剪贴板工作台。**

Bufferly 是一款面向开发者和 AI heavy user 的 macOS 剪贴板管理器。它把你复制过的代码、命令、链接、JSON、prompt 和临时文本，自动整理成可搜索、可复用、可安全粘贴的本地工作台——而不是又一个通用剪贴板平替。

> 本地优先，默认保护隐私。所有历史只存在你自己的机器上。

## 特性

- 📋 **自动监听剪贴板**：复制即入库，自动去重。
- 🔍 **快捷键呼出搜索面板**：`Option + Space` 呼出，呼出即聚焦搜索，键盘全程可达。
- 🎴 **Paste 式卡片墙**：横向卡片按类型着色，一眼可辨来源与内容。
- 🏷️ **自动类型识别**：URL / 代码 / JSON / 命令 / 邮件 自动归类。
- 🔒 **敏感内容过滤**：token、密码、`.env` value、API key 等命中后脱敏或不入库。
- 📌 **Pin 常用片段**：固定常用内容到独立分区。
- ⚡ **回车粘贴**：选中条目回车写回剪贴板，并尝试粘贴回原前台 App。
- 🛠️ **开发者转换**：JSON 格式化 / 压缩、URL 清理（去 tracking 参数）。
- 🎨 **原生 macOS 26 体验**：采用 Apple Liquid Glass，跟随系统语义色、SF Symbols 与平台交互习惯，支持 Light / Dark、Reduce Motion、Increase Contrast。

## 快捷键

| 操作 | 快捷键 |
|---|---|
| 呼出 / 隐藏面板 | `Option + Space`（可在设置中更改） |
| 选择上一张 / 下一张 | `←` / `→`（或 `↑` / `↓`） |
| 粘贴选中 | `Return` |
| 仅复制后关闭 | `Option + Return` |
| 固定 / 取消固定 | `⌘P` |
| 删除选中 | `⌘⌫` |
| 关闭面板 | `Esc` |

## 技术栈

- Swift + SwiftUI + AppKit
- [GRDB](https://github.com/groue/GRDB.swift) + SQLite —— 本地历史、pin 与设置持久化
- Keychain —— 敏感配置

## 系统要求

- **macOS 26 (Tahoe) 或更高版本**（使用了官方 Liquid Glass）
- Swift 6.2 工具链（开发构建）

## 构建与运行

```bash
# 开发运行
swift run Bufferly

# 仅构建
swift build

# 打包本地 app（产物在 .build/Bufferly.app）
bash scripts/build-app.sh
```

## 权限说明

「选中后自动粘贴回上一应用」依赖 macOS 的辅助功能 / 事件投递权限：

- 首次使用请在 **系统设置 → 隐私与安全性 → 辅助功能** 中允许 Bufferly。
- 即使没有该权限，选中内容也始终会先写回剪贴板，你可以手动 `⌘V` 粘贴。

## 隐私

- 剪贴板历史**只保存在本地** SQLite 数据库：`~/Library/Application Support/Bufferly/bufferly.sqlite`。
- 不做云同步、不上传任何内容。
- 敏感内容（token / 密码 / `.env` value 等）默认过滤，可在设置中选择脱敏占位或直接丢弃。

## 项目状态

M2 开发中。已实现剪贴板监听、本地持久化、去重、搜索、pin、回车写回与自动粘贴、全局快捷键、菜单栏入口、敏感内容过滤、开发者转换与最小设置页。详见 [`CLAUDE.md`](CLAUDE.md) 与 [`DESIGN.md`](DESIGN.md)。

暂不做：云同步、团队共享、移动端、复杂订阅系统、全格式支持。

## License

[MIT](LICENSE) © 2026 Innate-Labs
