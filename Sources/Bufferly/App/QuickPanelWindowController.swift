import AppKit
import SwiftUI

final class QuickPanelWindowController: NSWindowController, NSWindowDelegate {
    var onVisibilityChange: ((Bool) -> Void)?

    var isPanelVisible: Bool {
        window?.isVisible == true
    }

    init() {
        let contentView = QuickPanelView()
        let hostingView = NSHostingView(rootView: contentView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 980, height: QuickPanelView.panelHeight),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        hostingView.autoresizingMask = [.width, .height]
        window.contentView = hostingView
        window.isMovableByWindowBackground = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.moveToActiveSpace, .transient]
        window.isReleasedWhenClosed = false

        super.init(window: window)

        window.delegate = self
    }

    /// 把面板贴到当前屏幕底部居中，按屏幕宽度铺开（留边），类似 Paste 的底部卡片条。
    private func positionAtBottom() {
        guard let window else {
            return
        }

        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
            ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else {
            window.center()
            return
        }

        let horizontalMargin: CGFloat = 24
        let bottomGap: CGFloat = 24
        let width = min(visibleFrame.width - horizontalMargin * 2, 1_280)
        let height = QuickPanelView.panelHeight
        let originX = visibleFrame.midX - width / 2
        let originY = visibleFrame.minY + bottomGap

        window.setFrame(
            NSRect(x: originX, y: originY, width: width, height: height),
            display: true
        )
    }

    func showPanel() {
        guard let window else {
            return
        }

        positionAtBottom()
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        onVisibilityChange?(true)
    }

    func hidePanel() {
        window?.orderOut(nil)
        onVisibilityChange?(false)
    }

    func windowDidResignKey(_ notification: Notification) {
        hidePanel()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}
