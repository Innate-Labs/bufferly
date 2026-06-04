import AppKit
import SwiftUI

final class QuickPanelWindowController: NSWindowController {
    var isPanelVisible: Bool {
        window?.isVisible == true
    }

    init() {
        let contentView = QuickPanelView()
        let hostingView = NSHostingView(rootView: contentView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 520),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.center()
        window.contentView = hostingView
        window.isMovableByWindowBackground = true
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.moveToActiveSpace, .transient]
        window.isReleasedWhenClosed = false

        super.init(window: window)
    }

    func showPanel() {
        guard let window else {
            return
        }

        window.center()
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hidePanel() {
        window?.orderOut(nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}
