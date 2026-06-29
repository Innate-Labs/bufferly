import Foundation

extension Notification.Name {
    static let quickPanelDidRequestPaste = Notification.Name("quickPanelDidRequestPaste")
    static let quickPanelDidRequestClose = Notification.Name("quickPanelDidRequestClose")
    static let quickPanelDidRequestStatus = Notification.Name("quickPanelDidRequestStatus")
    /// 面板每次显示后广播，驱动 SwiftUI 重新聚焦搜索框。
    static let quickPanelDidShow = Notification.Name("quickPanelDidShow")
    static let hotKeyPresetDidChange = Notification.Name("hotKeyPresetDidChange")
    static let clearHistoryRequested = Notification.Name("clearHistoryRequested")
}

enum QuickPanelStatusKind: String {
    case info
    case success
    case warning
}

enum QuickPanelStatusPayload {
    static let messageKey = "message"
    static let kindKey = "kind"
}
