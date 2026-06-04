import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    init(settings: AppSettings = .shared) {
        let contentView = SettingsView(settings: settings)
        let hostingView = NSHostingView(rootView: contentView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 460),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Bufferly Settings"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)
    }

    func showSettings() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}
