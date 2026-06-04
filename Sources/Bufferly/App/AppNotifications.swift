import Foundation

extension Notification.Name {
    static let quickPanelDidRequestPaste = Notification.Name("quickPanelDidRequestPaste")
    static let quickPanelDidRequestClose = Notification.Name("quickPanelDidRequestClose")
    /// 面板每次显示后广播，驱动 SwiftUI 重新聚焦搜索框。
    static let quickPanelDidShow = Notification.Name("quickPanelDidShow")
    static let hotKeyPresetDidChange = Notification.Name("hotKeyPresetDidChange")
    static let clearHistoryRequested = Notification.Name("clearHistoryRequested")
}
