import Foundation

struct ClipItem: Identifiable, Hashable {
    let id: UUID
    let kind: ClipKind
    let title: String
    let preview: String
    let source: String
    let content: String
    let createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var isSensitive: Bool

    init(
        id: UUID = UUID(),
        kind: ClipKind,
        title: String,
        preview: String,
        source: String,
        content: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPinned: Bool = false,
        isSensitive: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.preview = preview
        self.source = source
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.isSensitive = isSensitive
    }

    var relativeTime: String {
        let elapsed = max(0, Int(Date().timeIntervalSince(updatedAt)))

        if elapsed < 60 {
            return "刚刚"
        }

        let minutes = elapsed / 60
        if minutes < 60 {
            return "\(minutes) 分钟"
        }

        let hours = minutes / 60
        if hours < 24 {
            return "\(hours) 小时"
        }

        let days = hours / 24
        if days == 1 {
            return "昨天"
        }

        return "\(days) 天"
    }
}
