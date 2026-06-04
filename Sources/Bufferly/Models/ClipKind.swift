import SwiftUI

enum ClipKind: String, CaseIterable, Identifiable {
    case text = "文本"
    case url = "URL"
    case json = "JSON"
    case command = "命令"
    case code = "代码"
    case email = "邮件"
    case secret = "敏感"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .text:
            "text.alignleft"
        case .url:
            "link"
        case .json:
            "curlybraces"
        case .command:
            "terminal"
        case .code:
            "chevron.left.forwardslash.chevron.right"
        case .email:
            "envelope"
        case .secret:
            "lock"
        }
    }

    var tint: Color {
        switch self {
        case .secret:
            .orange
        default:
            .secondary
        }
    }

    /// 卡片彩色头部用的鲜明色，按类型区分（Paste 式卡片墙）。
    /// 都足够深，保证白色头部文字可读。
    var accent: Color {
        switch self {
        case .text:
            .blue
        case .url:
            .green
        case .json:
            .purple
        case .command:
            Color(red: 0.34, green: 0.38, blue: 0.46) // 石墨，终端气质
        case .code:
            .indigo
        case .email:
            .pink
        case .secret:
            .orange
        }
    }
}
