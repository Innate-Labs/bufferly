import AppKit
import SwiftUI

final class QuickPanelWindowController: NSWindowController, NSWindowDelegate {
    var onVisibilityChange: ((Bool) -> Void)?

    /// 退场动画进行中标记：若淡出途中又被呼出（showPanel 置 false），完成回调不再 orderOut，避免误关。
    private var pendingHide = false

    var isPanelVisible: Bool {
        window?.isVisible == true
    }

    init() {
        let contentView = QuickPanelView()
        let hostingView = NSHostingView(rootView: contentView)
        // 用可成为 key 的子类：无边框窗口默认 canBecomeKey=false，
        // 否则窗口收不到键盘、也永远不会触发 resignKey（失焦自动隐藏因此失效）。
        let window = KeyablePanelWindow(
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

        // 取消任何进行中的退场动画（淡出途中重新呼出）。
        pendingHide = false

        positionAtBottom()
        let finalFrame = window.frame

        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            window.alphaValue = 1
            showWindow(nil)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            onVisibilityChange?(true)
            NotificationCenter.default.post(name: .quickPanelDidShow, object: nil)
            return
        }

        // 从略低处升起 + 淡入，类似 Spotlight 的克制入场。
        window.alphaValue = 0
        window.setFrame(finalFrame.offsetBy(dx: 0, dy: -10), display: false)
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
            window.animator().setFrame(finalFrame, display: true)
        }

        onVisibilityChange?(true)
        NotificationCenter.default.post(name: .quickPanelDidShow, object: nil)
    }

    func hidePanel() {
        guard let window, window.isVisible else {
            onVisibilityChange?(false)
            return
        }

        onVisibilityChange?(false)

        // Reduce Motion：直接隐藏，不做退场动画。
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            window.orderOut(nil)
            return
        }

        // 入场的镜像：下沉 10px + 淡出。
        pendingHide = true
        let sunkFrame = window.frame.offsetBy(dx: 0, dy: -10)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.13
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
            window.animator().setFrame(sunkFrame, display: true)
        }, completionHandler: { [weak self] in
            // 淡出途中若又被呼出，showPanel 已把 pendingHide 置 false，这里不再 orderOut。
            guard let self, self.pendingHide else {
                return
            }
            self.window?.orderOut(nil)
            self.pendingHide = false
        })
    }

    func windowDidResignKey(_ notification: Notification) {
        hidePanel()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}

/// 无边框面板窗口。覆写 canBecomeKey/Main，使其能接收键盘输入，
/// 并在点击其它界面失焦时正常触发 windowDidResignKey 以自动隐藏。
private final class KeyablePanelWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
