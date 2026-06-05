import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()

app.delegate = delegate
// 默认 .accessory：纯菜单栏后台 App，Dock 不显示图标。
// 打开设置窗口时由 SettingsWindowController 临时切到 .regular 显示 Dock 图标，关闭后切回。
app.setActivationPolicy(.accessory)
app.run()
