# Bufferly

为开发者和 AI 工作流打造的本地优先剪贴板工作台。

## 项目状态

- M2 进行中：Swift Package macOS app 骨架已初始化，Quick Panel 已接入真实文本剪贴板监听、GRDB/SQLite 本地持久化、去重、搜索、pin、回车写回剪贴板、固定 `Option + Space` 全局快捷键呼出 / 隐藏、菜单栏状态入口、菜单栏 / 程序坞图标，以及回车后隐藏面板并尝试粘贴回原前台 App。
- 已接入最小设置页，可配置粘贴后隐藏、自动粘贴、最大历史数量，显示本地数据库路径，并检测 / 请求自动粘贴所需的事件投递权限。
- 尚未接入快捷键配置。自动粘贴依赖 macOS 事件投递 / 辅助功能权限；权限不可用时至少保证内容已写回剪贴板。敏感内容暂不默认过滤，API key / token 等内容会保留在本地历史中。

## 技术栈

- Swift + SwiftUI + AppKit。
- GRDB + SQLite 用于本地历史、pin 和设置持久化。
- Keychain 用于保存加密密钥或敏感配置。

## 产品方向

- 面向开发者和 AI heavy user，而不是通用剪贴板平替。
- 本地优先保存剪贴板历史，默认保护隐私。
- 重点支持代码、命令、URL、JSON、prompt、临时文本的搜索、复用和转换。

## MVP 范围

- 监听剪贴板文本变化。
- 保存最近剪贴板历史，支持去重。
- 快捷键呼出搜索面板。
- 回车粘贴选中条目。
- Pin 常用片段。
- 自动识别 URL / Code / JSON / Email / Command。
- 敏感内容过滤，例如 token、密码、验证码、`.env` value。
- 粘贴为纯文本。

## 暂不做

- 云同步。
- 团队共享。
- 移动端。
- 复杂订阅系统。
- 全格式支持。

## 常用命令

- 开发：`swift run Bufferly`
- 构建：`swift build`
- 打包本地 app：`bash scripts/build-app.sh`，产物在 `.build/Bufferly.app`
- 类型检查 / 测试：`swift build`

## 代码风格 / 架构

- 设计规范见 `DESIGN.md`。
- 剪贴板监听、存储、安全过滤、类型识别、快捷键、UI 面板应保持边界清晰。
- 默认本地存储，涉及敏感内容时优先选择不入库。
- UI 尽可能接近 Apple 原生体验，优先使用 SwiftUI / AppKit 系统控件、语义色、SF Symbols 和平台交互习惯。

## 不要动的文件

- `.build/` — SwiftPM 构建产物。

## 工作流

- 改完代码必须跑验证命令。
- commit 前确保 lint / typecheck 通过。
- 不要 force-push，push 前先 pull。
