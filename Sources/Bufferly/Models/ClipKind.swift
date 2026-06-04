import SwiftUI

enum ClipKind: String, CaseIterable, Identifiable {
    case text = "Text"
    case url = "URL"
    case json = "JSON"
    case command = "CMD"
    case code = "Code"
    case email = "Email"
    case secret = "Secret"

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
}
