import AppKit

@MainActor
final class StatusBarController: NSObject {
    var onTogglePanel: (() -> Void)?
    var onShowSettings: (() -> Void)?

    private let statusItem: NSStatusItem
    private let togglePanelItem = NSMenuItem(title: "Show Quick Panel", action: #selector(togglePanel(_:)), keyEquivalent: "")

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        super.init()

        configureStatusItem()
    }

    func setPanelVisible(_ isVisible: Bool) {
        togglePanelItem.title = isVisible ? "Hide Quick Panel" : "Show Quick Panel"
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            button.image = statusBarImage()
            button.image?.isTemplate = true
            button.toolTip = "Bufferly"
        }

        let menu = NSMenu()

        togglePanelItem.target = self
        menu.addItem(togglePanelItem)

        menu.addItem(
            NSMenuItem(
                title: "Settings...",
                action: #selector(showSettings(_:)),
                keyEquivalent: ","
            )
        )
        menu.items.last?.target = self

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Bufferly",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = NSApp
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc
    private func togglePanel(_ sender: Any?) {
        onTogglePanel?()
    }

    @objc
    private func showSettings(_ sender: Any?) {
        onShowSettings?()
    }

    private func statusBarImage() -> NSImage? {
        if
            let url = Bundle.module.url(forResource: "StatusBarIcon", withExtension: "png"),
            let image = NSImage(contentsOf: url)
        {
            image.size = NSSize(width: 18, height: 18)
            return image
        }

        return NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Bufferly")
    }
}
