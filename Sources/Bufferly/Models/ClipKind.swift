import SwiftUI

enum ClipKind: String, CaseIterable, Identifiable {
    case text = "文本"
    case url = "URL"
    case json = "JSON"
    case command = "命令"
    case code = "代码"
    case email = "邮件"
    case image = "图片"
    case file = "文件"
    case richText = "富文本"
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
        case .image:
            "photo"
        case .file:
            "doc"
        case .richText:
            "doc.richtext"
        case .secret:
            "lock"
        }
    }

    var tablerIconName: String {
        switch self {
        case .text:
            "align-left"
        case .url:
            "link"
        case .json:
            "braces"
        case .command:
            "terminal-2"
        case .code:
            "code"
        case .email:
            "mail"
        case .image:
            "photo"
        case .file:
            "file"
        case .richText:
            "file-text"
        case .secret:
            "lock"
        }
    }

    /// 二进制 / 附件型：内容不是纯文本，正文存到 blob，卡片按各自方式渲染。
    var isAttachment: Bool {
        self == .image || self == .file || self == .richText
    }

    var tint: Color {
        switch self {
        case .secret:
            .orange
        default:
            .secondary
        }
    }

    /// 卡片彩色头部使用的颜色，按内容类型区分。
    /// 颜色只帮助扫读类型，不承担选中态。
    var accent: Color {
        switch self {
        case .text:
            Color(red: 0.0, green: 0.533, blue: 1.0)
        case .url:
            Color(red: 0.204, green: 0.780, blue: 0.345)
        case .json:
            Color(red: 0.796, green: 0.188, blue: 0.878)
        case .command:
            Color(red: 0.34, green: 0.38, blue: 0.46)
        case .code:
            Color(red: 0.796, green: 0.188, blue: 0.878)
        case .email:
            .pink
        case .image:
            Color(red: 1.0, green: 0.220, blue: 0.235)
        case .file:
            Color(red: 0.55, green: 0.45, blue: 0.32)
        case .richText:
            Color(red: 0.0, green: 0.48, blue: 0.6)
        case .secret:
            .orange
        }
    }
}
