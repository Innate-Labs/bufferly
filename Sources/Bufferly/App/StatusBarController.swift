import AppKit

@MainActor
final class StatusBarController: NSObject {
    var onTogglePanel: (() -> Void)?
    var onShowSettings: (() -> Void)?

    private let statusItem: NSStatusItem
    private let togglePanelItem = NSMenuItem(title: "显示快速面板", action: #selector(togglePanel(_:)), keyEquivalent: "")

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        super.init()

        configureStatusItem()
    }

    func setPanelVisible(_ isVisible: Bool) {
        togglePanelItem.title = isVisible ? "隐藏快速面板" : "显示快速面板"
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            button.image = Self.makeStatusBarImage()
            button.toolTip = "Bufferly"
        }

        let menu = NSMenu()

        togglePanelItem.target = self
        menu.addItem(togglePanelItem)

        menu.addItem(
            NSMenuItem(
                title: "设置...",
                action: #selector(showSettings(_:)),
                keyEquivalent: ","
            )
        )
        menu.items.last?.target = self

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "退出 Bufferly",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = NSApp
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    /// 菜单栏图标：优先用 Resources 里的模板图（系统按浅/深色菜单栏自动着色），失败时回退 SF Symbol。
    private static func makeStatusBarImage() -> NSImage? {
        if
            let url = Bundle.module.url(forResource: "StatusBarIcon", withExtension: "png"),
            let image = NSImage(contentsOf: url)
        {
            image.size = NSSize(width: 18, height: 18)
            image.isTemplate = true
            return image
        }

        return NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Bufferly")
    }

    @objc
    private func togglePanel(_ sender: Any?) {
        onTogglePanel?()
    }

    @objc
    private func showSettings(_ sender: Any?) {
        onShowSettings?()
    }
}
