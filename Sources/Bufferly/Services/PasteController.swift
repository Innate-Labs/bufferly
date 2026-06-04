import AppKit
import Carbon
import CoreGraphics

enum PasteController {
    static func pasteIntoApplication(_ application: NSRunningApplication?) {
        application?.activate(options: [])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            sendCommandV()
        }
    }

    private static func sendCommandV() {
        guard
            let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        else {
            return
        }

        keyDown.flags = CGEventFlags.maskCommand
        keyUp.flags = CGEventFlags.maskCommand

        keyDown.post(tap: CGEventTapLocation.cghidEventTap)
        keyUp.post(tap: CGEventTapLocation.cghidEventTap)
    }
}
