import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var quickPanelWindowController: QuickPanelWindowController?
    private var hotKeyManager: HotKeyManager?
    private var pasteTargetApplication: NSRunningApplication?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMenu()
        configureNotifications()

        let controller = QuickPanelWindowController()
        quickPanelWindowController = controller

        hotKeyManager = HotKeyManager { [weak self] in
            self?.toggleQuickPanel()
        }
        hotKeyManager?.registerOptionSpace()

        controller.showPanel()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func toggleQuickPanel() {
        guard let quickPanelWindowController else {
            return
        }

        if quickPanelWindowController.isPanelVisible {
            quickPanelWindowController.hidePanel()
        } else {
            updatePasteTargetApplication()
            quickPanelWindowController.showPanel()
        }
    }

    private func handlePasteRequest() {
        quickPanelWindowController?.hidePanel()
        PasteController.pasteIntoApplication(pasteTargetApplication)
    }

    private func updatePasteTargetApplication() {
        let frontmostApplication = NSWorkspace.shared.frontmostApplication

        guard frontmostApplication?.bundleIdentifier != Bundle.main.bundleIdentifier else {
            return
        }

        pasteTargetApplication = frontmostApplication
    }

    private func configureNotifications() {
        NotificationCenter.default.addObserver(
            forName: .quickPanelDidRequestPaste,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handlePasteRequest()
            }
        }
    }

    private func configureMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()

        appMenu.addItem(
            NSMenuItem(
                title: "Settings...",
                action: nil,
                keyEquivalent: ","
            )
        )
        appMenu.addItem(.separator())
        appMenu.addItem(
            NSMenuItem(
                title: "Quit Bufferly",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }
}
