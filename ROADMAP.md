# Bufferly 迭代路线图

> 本文件是产品迭代计划。设计规范见 [`DESIGN.md`](DESIGN.md)，产品范围见 [`CLAUDE.md`](CLAUDE.md)。
> 最近更新：2026-06-05。

## 战略判断

Bufferly 定位「为开发者和 AI 工作流打造的本地优先剪贴板工作台」。2026 年品类调研结论：

- **纯「历史 + 好看」已是红海**：Paste（订阅、iCloud 同步、精致 UI）、Maccy（免费开源、纯本地）、Raycast（启动器顺带剪贴板）、Pastebot（买断）已把这块占满。
- **存在直接概念竞品**：[ClipGate](https://clipgate.github.io/) —— 开发者向、13 种类型识别、secret-aware、本地优先、能把相关 clip 打包成 AI-ready context。它走 CLI + 浏览器扩展；Bufferly 的差异化在**原生 macOS 26 GUI + 开源 + 本地优先**。
- **风口已转向 MCP**：[Paste 于 2026-06-02 上线 MCP](https://9to5mac.com/2026/06/02/paste-launches-mcp-support-to-connect-your-clipboard-history-to-ai-tools/)，把剪贴板历史接进 Claude / Cursor / Codex。这正是 Bufferly 定位的核心战场。

**结论**：真正的差异化楔子是「原生 GUI + 深度接入 AI agent 工作流」。但先把基础功能补齐到「日常自用够顺手」，再上 AI 楔子。

## 阶段规划

### 阶段 0 · 功能补齐（进行中 ⏳）

把剪贴板能力补到与 Paste 同档，让 Bufferly 日常自用无短板。**当前优先做这一档。**

- [ ] **图片剪贴板**：监听 / 入库 / 卡片缩略图预览 / 回写粘贴。
- [ ] **文件剪贴板**：Finder 复制的文件 URL，显示文件图标 + 名称，回写粘贴。
- [ ] **富文本（RTF）**：保留富文本格式，卡片按富文本渲染，回写保留格式；纯文本作兜底。
- [ ] 二进制 / 大附件不进 SQLite 主库，存到 `Application Support/Bufferly/blobs/`，DB 只存引用。
- [ ] 去重适配：图片 / 文件按内容哈希去重。
- [ ] （后续）富链接预览（LinkPresentation）、卡片显示来源 App 图标。

### 阶段 1 · AI 差异化楔子

- [ ] **内置 MCP server**：暴露 `search_clips` / `get_clip` / `pack_context` 等工具给 Claude Code / Cursor / Codex；本地运行、用户控制授权、可随时撤销。
- [ ] **AI-ready 上下文打包**：多选相关 clip → 合成 Markdown / JSON 一键喂给 agent。
- [ ] **数据库静态加密**：SQLite + AES，密钥进 Keychain；敏感占位也加密。

### 阶段 2 · AI 原生能力

- [ ] **单条 clip 的 LLM 转换**：解释报错、JSON → Swift struct、润色 prompt 等。坚持本地优先：Apple Intelligence 端侧模型 / 用户自带 API key，默认不外发。
- [ ] **Prompt 库**：prompt 作为一等公民，支持变量模板 + ⌘1-9 快捷粘贴。

### 阶段 3 · 加深护城河

- [ ] 智能集合 / 自动标签（按 git 仓库 / 来源 App 归类）。
- [ ] 片段展开（输入触发词自动展开）。
- [ ] 按类型的快捷动作（打开 URL、在终端执行命令等）。

## 竞品参考

| 产品 | 定位 | 占住的点 |
|---|---|---|
| [Paste](https://pasteapp.io/) | 订阅、精致 UI + iCloud 同步 + MCP | 颜值、跨设备、分发 |
| [Maccy](https://github.com/p0deje/Maccy) | 免费开源、纯本地 | 隐私基线 |
| Raycast | 启动器顺带剪贴板 | 扩展生态 |
| [ClipGate](https://clipgate.github.io/) | 开发者终端向、类型识别、AI 打包 | 最像的概念竞品 |
| PromptClip / Promptzy | AI prompt 管理、快捷粘贴 | prompt 复用 |

## 暂不做（守住定位）

- 云同步、团队共享、移动端、复杂订阅系统、全格式支持。
- 默认把内容外发给任何云端模型（AI 能力一律本地优先 / 用户自带 key）。
