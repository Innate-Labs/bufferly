<div align="center">

<img src="docs/icon.png" width="120" alt="Bufferly" />

# Bufferly

**为开发者和 AI 工作流打造的本地优先剪贴板工作台**

<sub>A local-first clipboard workspace for developers & AI-heavy workflows</sub>

<br/>

![Platform](https://img.shields.io/badge/macOS-26%2B-000000?logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white)
![Liquid Glass](https://img.shields.io/badge/UI-Liquid%20Glass-7AA7FF)
[![License](https://img.shields.io/github/license/Innate-Labs/bufferly?color=blue)](LICENSE)
[![Stars](https://img.shields.io/github/stars/Innate-Labs/bufferly?style=social)](https://github.com/Innate-Labs/bufferly)

<br/>
<br/>

[![⬇ 下载 DMG](https://img.shields.io/badge/⬇%20下载-Bufferly.dmg-7AA7FF?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/Innate-Labs/bufferly/releases/latest)

<sub>最新版本见 <a href="https://github.com/Innate-Labs/bufferly/releases/latest">Releases</a></sub>

</div>

---

复制过的代码、命令、链接、JSON、prompt、临时文本，Bufferly 自动把它们整理成**可搜索、可复用、可安全粘贴**的本地工作台 —— 不是又一个通用剪贴板平替，而是为**开发者和 AI heavy user** 量身做的。一切只存在你自己的机器上，默认保护隐私。

<p align="center">
  <img src="docs/screenshot.png" width="100%" alt="Bufferly Quick Panel" />
</p>

## ✨ 特性

- 📋 **自动监听 + 去重** —— 复制即入库，呼出瞬间补抓，最新的永远在第一张
- 🔍 **模糊搜索 + 相关度排序** —— 敲 `dbcon` 也能搜出 `database connection`，打错字也行
- 🎴 **Paste 式卡片墙** —— 横向卡片按类型着色，来源 App 图标一眼可辨
- 🏷️ **自动类型识别** —— URL / 代码 / JSON / 命令 / 邮件 自动归类
- 🖼️ **不止文本** —— 图片、文件、富文本（RTF）都能存、能预览、能原样粘回
- 🔒 **敏感内容过滤** —— token、密码、`.env` value、API key 命中后脱敏或不入库
- 📌 **Pin 常用片段** —— 固定到独立分区，随取随用
- ⚡ **Return 执行** —— 可只复制到剪贴板，也可复制后粘贴到上一应用
- 🛡️ **排除 App** —— 默认不记录 Passwords、Keychain Access、1Password、Bitwarden 等敏感来源
- 🎨 **原生 macOS 26 体验** —— Apple Liquid Glass、语义色、SF Symbols + Tabler Icons，支持 Light / Dark、Reduce Motion

## ⌨️ 快捷键

| 操作 | 快捷键 |
|---|---|
| 呼出 / 隐藏面板 | `⌥ Space`（可在设置中更改） |
| 选择上一张 / 下一张 | `←` `→`（或 `↑` `↓`） |
| 粘贴选中 | `Return` |
| Quick Look 预览 | `Space`（搜索为空时） |
| 仅复制后关闭 | `⌥ Return` |
| 固定 / 取消固定 | `⌘P` |
| 删除选中 | `⌘⌫` |
| 清空搜索 / 关闭面板 | `Esc` |

## 📦 安装

### 直接用（DMG）

1. 到 **[Releases 页面](https://github.com/Innate-Labs/bufferly/releases/latest)** 下载最新的 `Bufferly-x.y.z.dmg`
2. 打开 DMG，把 Bufferly 拖到「应用程序」
3. **首次启动右键「打开」**（未公证，需绕过一次 Gatekeeper）

> 需要 **Apple Silicon + macOS 26 (Tahoe)**。

### 从源码构建

```bash
git clone https://github.com/Innate-Labs/bufferly.git
cd bufferly

swift run Bufferly            # 开发运行
bash scripts/build-app.sh     # 打包 .app → .build/Bufferly.app
bash scripts/install-app.sh   # 覆盖安装到 /Applications 并启动
bash scripts/build-dmg.sh     # 打包 .dmg → .build/Bufferly.dmg
```

> **复制后粘贴到上一应用**依赖辅助功能权限：系统设置 → 隐私与安全性 → 辅助功能 → 允许 Bufferly。未授权也能用，内容已写回剪贴板，自己按 `⌘V` 即可。

### 首次授权和排障

- 如果点击「请求授权」没有弹窗：打开 Bufferly 设置 → 粘贴行为 →「打开系统设置」，在「隐私与安全性 → 辅助功能」里允许 Bufferly。
- 如果已经授权但仍显示需要授权：先关闭再重新打开辅助功能里的 Bufferly 开关，然后回到 Bufferly 设置点「刷新」。
- 如果还是不生效：退出 Bufferly，重新从 `/Applications/Bufferly.app` 启动，确认授权的是这个应用路径，而不是 `.build/Bufferly.app`。
- 没有辅助功能权限时，Return 会退回为只复制到剪贴板，不会丢失内容。

## 🔒 隐私

- 剪贴板历史**只存本地** SQLite：`~/Library/Application Support/Bufferly/`
- **不做云同步、不上传任何内容**
- 设置页会明确显示保留时长、最大历史数量和当前排除的 App
- 默认排除 Passwords、Keychain Access、1Password、Bitwarden 等敏感 App
- 敏感内容默认过滤，可选脱敏占位或直接丢弃
- 链接预览默认**关闭**（开启才联网获取标题/图标）

## 🛠️ 技术栈

Swift · SwiftUI · AppKit · [GRDB](https://github.com/groue/GRDB.swift) / SQLite · Keychain

## 🗺️ 路线图

已完成核心剪贴板能力 + 图片/文件/富文本 + 模糊搜索。下一步重点是隐私控制、安装体验、可靠性和高频交互手感。详见 **[ROADMAP.md](ROADMAP.md)**。

## 🤝 贡献

欢迎 issue 与 PR。设计规范见 [`DESIGN.md`](DESIGN.md)，项目说明见 [`CLAUDE.md`](CLAUDE.md)。

## 📄 License

[MIT](LICENSE) © [Innate Labs](https://github.com/Innate-Labs)

<div align="center"><sub>Built for developers who copy 50+ things a day.</sub></div>
