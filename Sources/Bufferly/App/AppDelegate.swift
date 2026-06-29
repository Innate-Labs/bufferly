import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var quickPanelWindowController: QuickPanelWindowController?
    private var settingsWindowController: SettingsWindowController?
    private var hotKeyManager: HotKeyManager?
    private var statusBarController: StatusBarController?
    private var pasteTargetApplication: NSRunningApplication?

    func applicationWillFinishLaunching(_ notification: Notification) {
        // 单实例守卫：若已存在相同 bundle id 的另一个进程，直接退出自己。
        // 防止「登录项里登记了多份 .app 路径」时开机出现多个 UI 实例。
        let myPID = ProcessInfo.processInfo.processIdentifier
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        let hasOtherInstance = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleID)
            .contains { $0.processIdentifier != myPID }
        if hasOtherInstance {
            NSApp.terminate(nil)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureApplicationIcon()
        configureMenu()
        configureNotifications()

        let controller = QuickPanelWindowController()
        controller.onVisibilityChange = { [weak self] _ in
            self?.updateStatusBarPanelState()
        }
        quickPanelWindowController = controller

        hotKeyManager = HotKeyManager { [weak self] in
            self?.toggleQuickPanel()
        }
        hotKeyManager?.register(AppSettings.shared.hotKeyPreset)

        let statusBarController = StatusBarController()
        statusBarController.onTogglePanel = { [weak self] in
            self?.toggleQuickPanel()
        }
        statusBarController.onShowSettings = { [weak self] in
            self?.showSettings(nil)
        }
        self.statusBarController = statusBarController

        controller.showPanel()
        updateStatusBarPanelState()
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

        updateStatusBarPanelState()
    }

    private func handlePasteRequest() {
        if AppSettings.shared.hideAfterPaste {
            quickPanelWindowController?.hidePanel()
            updateStatusBarPanelState()
        }

        if AppSettings.shared.autoPasteAfterSelection {
            PasteController.pasteIntoApplication(pasteTargetApplication)
        }
    }

    private func updatePasteTargetApplication() {
        let frontmostApplication = NSWorkspace.shared.frontmostApplication

        guard frontmostApplication?.bundleIdentifier != Bundle.main.bundleIdentifier else {
            return
        }

        pasteTargetApplication = frontmostApplication
    }

    private func updateStatusBarPanelState() {
        statusBarController?.setPanelVisible(quickPanelWindowController?.isPanelVisible == true)
    }

    private func configureApplicationIcon() {
        guard
            let url = AppResources.url(forResource: "AppIcon-1024", withExtension: "png"),
            let image = NSImage(contentsOf: url)
        else {
            return
        }

        NSApp.applicationIconImage = image
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

        NotificationCenter.default.addObserver(
            forName: .quickPanelDidRequestClose,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.quickPanelWindowController?.hidePanel()
                self?.updateStatusBarPanelState()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .hotKeyPresetDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.hotKeyManager?.register(AppSettings.shared.hotKeyPreset)
            }
        }
    }

    private func configureMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()

        appMenu.addItem(
            NSMenuItem(
                title: "设置...",
                action: #selector(showSettings(_:)),
                keyEquivalent: ","
            )
        )
        appMenu.addItem(.separator())
        appMenu.addItem(
            NSMenuItem(
                title: "退出 Bufferly",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }

    @objc
    private func showSettings(_ sender: Any?) {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }

        settingsWindowController?.showSettings()
    }
}
