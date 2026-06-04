import AppKit
import SwiftUI

/// 系统原生 `NSSearchField` 封装：带标准外观、放大镜、清除按钮、焦点环（macOS 26 自动套 Liquid Glass）。
/// 同时把方向键 / 回车 / Esc 转发出去，让搜索时也能用 ←→ 切卡片、回车粘贴、Esc 关闭。
struct NativeSearchField: NSViewRepresentable {
    @Binding var text: String
    var onSubmit: () -> Void = {}
    var onCancel: () -> Void = {}
    var onMovePrevious: () -> Void = {}
    var onMoveNext: () -> Void = {}

    func makeNSView(context: Context) -> NSSearchField {
        let field = NSSearchField()
        field.delegate = context.coordinator
        field.placeholderString = "搜索剪贴板"
        field.sendsWholeSearchString = false
        field.sendsSearchStringImmediately = true

        // 呼出后自动聚焦，并设为窗口初始响应者（再次呼出也能聚焦）。
        DispatchQueue.main.async { [weak field] in
            guard let field else { return }
            field.window?.initialFirstResponder = field
            field.window?.makeFirstResponder(field)
        }
        return field
    }

    func updateNSView(_ nsView: NSSearchField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, NSSearchFieldDelegate {
        private let parent: NativeSearchField

        init(_ parent: NativeSearchField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSSearchField else { return }
            parent.text = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.insertNewline(_:)):
                parent.onSubmit()
                return true
            case #selector(NSResponder.cancelOperation(_:)):
                parent.onCancel()
                return true
            case #selector(NSResponder.moveLeft(_:)), #selector(NSResponder.moveUp(_:)):
                parent.onMovePrevious()
                return true
            case #selector(NSResponder.moveRight(_:)), #selector(NSResponder.moveDown(_:)):
                parent.onMoveNext()
                return true
            default:
                return false
            }
        }
    }
}
