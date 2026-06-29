import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    init(settings: AppSettings = .shared) {
        let contentView = SettingsView(settings: settings)
        let hostingView = NSHostingView(rootView: contentView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 580, height: 540),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Bufferly 设置"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)

        window.delegate = self
    }

    func showSettings() {
        // 打开设置时切到 .regular：Dock 出现图标、顶部 App 菜单出现。
        NSApp.setActivationPolicy(.regular)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        // 关闭设置后切回 .accessory：移除 Dock 图标，但 App 继续在菜单栏后台运行。
        // 延后到关闭流程结束再切，避免切策略与窗口关闭抢焦点。
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}
