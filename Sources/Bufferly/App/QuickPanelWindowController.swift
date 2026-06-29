import AppKit
import QuartzCore
import SwiftUI

final class QuickPanelWindowController: NSWindowController, NSWindowDelegate {
    var onVisibilityChange: ((Bool) -> Void)?

    private var visibilityAnimationID = UUID()
    private var isHiding = false

    var isPanelVisible: Bool {
        window?.isVisible == true && !isHiding
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
        window.hasShadow = false
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

        let animationID = UUID()
        visibilityAnimationID = animationID
        isHiding = false

        positionAtBottom()
        let finalFrame = window.frame
        let shouldAnimate = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

        if shouldAnimate {
            var startFrame = finalFrame
            startFrame.origin.y -= 6
            window.setFrame(startFrame, display: false)
            window.alphaValue = 0
        } else {
            window.alphaValue = 1
        }

        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        if shouldAnimate {
            window.alphaValue = 0
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.23, 1, 0.32, 1)
                window.animator().alphaValue = 1
                window.animator().setFrame(finalFrame, display: true)
            } completionHandler: { [weak self, weak window] in
                Task { @MainActor in
                    guard let self, self.visibilityAnimationID == animationID else {
                        return
                    }
                    window?.alphaValue = 1
                    window?.setFrame(finalFrame, display: false)
                }
            }
        }

        onVisibilityChange?(true)
        NotificationCenter.default.post(name: .quickPanelDidShow, object: nil)
    }

    func hidePanel() {
        guard let window, window.isVisible else {
            isHiding = false
            onVisibilityChange?(false)
            return
        }

        let animationID = UUID()
        visibilityAnimationID = animationID
        isHiding = true
        onVisibilityChange?(false)

        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
            window.orderOut(nil)
            window.alphaValue = 1
            isHiding = false
            return
        }

        var finalFrame = window.frame
        finalFrame.origin.y -= 6

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.09
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.23, 1, 0.32, 1)
            window.animator().alphaValue = 0
            window.animator().setFrame(finalFrame, display: true)
        } completionHandler: { [weak self, weak window] in
            Task { @MainActor in
                guard let self, self.visibilityAnimationID == animationID else {
                    return
                }
                window?.orderOut(nil)
                window?.alphaValue = 1
                self.isHiding = false
            }
        }
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
