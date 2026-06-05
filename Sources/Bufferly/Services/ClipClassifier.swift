import CryptoKit
import Foundation

enum ClipClassifier {
    static func makeClip(from rawText: String, source: String = "剪贴板", sourceBundleID: String? = nil) -> ClipItem? {
        let content = rawText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !content.isEmpty else {
            return nil
        }

        let kind = detectKind(for: content)

        return ClipItem(
            kind: kind,
            title: makeTitle(for: content, kind: kind),
            preview: makePreview(for: content),
            source: source,
            sourceBundleID: sourceBundleID,
            content: content
        )
    }

    /// 图片：content 用图片字节的哈希作去重键，PNG 字节存到 blob（文件名由调用方写入）。
    static func makeImageClip(png: Data, pixelSize: CGSize?, source: String = "剪贴板", sourceBundleID: String? = nil) -> ClipItem {
        let id = UUID()
        let hash = SHA256.hash(data: png).map { String(format: "%02x", $0) }.joined()

        let sizeText: String
        if let pixelSize, pixelSize.width > 0, pixelSize.height > 0 {
            sizeText = "图片 · \(Int(pixelSize.width))×\(Int(pixelSize.height))"
        } else {
            sizeText = "图片"
        }

        return ClipItem(
            id: id,
            kind: .image,
            title: sizeText,
            preview: sizeText,
            source: source,
            sourceBundleID: sourceBundleID,
            content: "image:\(hash)",
            attachmentFilename: "\(id.uuidString).png",
            attachmentUTI: "public.png"
        )
    }

    /// 文件：content 用文件路径（天然去重），不写 blob，回写时按 file-url 还原。
    static func makeFileClip(urls: [URL], source: String = "剪贴板", sourceBundleID: String? = nil) -> ClipItem? {
        guard !urls.isEmpty else {
            return nil
        }

        let paths = urls.map(\.path).joined(separator: "\n")
        let firstName = urls[0].lastPathComponent
        let title = urls.count > 1 ? "\(firstName) 等 \(urls.count) 个" : firstName

        return ClipItem(
            kind: .file,
            title: title,
            preview: paths,
            source: source,
            sourceBundleID: sourceBundleID,
            content: paths,
            attachmentUTI: "public.file-url"
        )
    }

    /// 富文本：content 用纯文本兜底（去重 + 纯文本粘贴），RTF 数据存到 blob。
    static func makeRichTextClip(rtf: Data, plain: String, source: String = "剪贴板", sourceBundleID: String? = nil) -> ClipItem? {
        let trimmed = plain.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let id = UUID()
        return ClipItem(
            id: id,
            kind: .richText,
            title: makeTitle(for: trimmed, kind: .richText),
            preview: makePreview(for: trimmed),
            source: source,
            sourceBundleID: sourceBundleID,
            content: trimmed,
            attachmentFilename: "\(id.uuidString).rtf",
            attachmentUTI: "public.rtf"
        )
    }

    /// 命中敏感规则时的脱敏占位：不保存明文（content 为空），仅留一个 lock 卡片。
    static func makeMaskedSecret(source: String = "剪贴板", sourceBundleID: String? = nil) -> ClipItem {
        ClipItem(
            kind: .secret,
            title: "敏感内容已隐藏",
            preview: "敏感内容已隐藏",
            source: source,
            sourceBundleID: sourceBundleID,
            content: "",
            isSensitive: true
        )
    }

    private static func detectKind(for content: String) -> ClipKind {
        if isEmail(content) {
            return .email
        }

        if isURL(content) {
            return .url
        }

        if isJSON(content) {
            return .json
        }

        if isShellCommand(content) {
            return .command
        }

        if isCodeLike(content) {
            return .code
        }

        return .text
    }

    private static func makeTitle(for content: String, kind: ClipKind) -> String {
        let firstLine = content
            .split(whereSeparator: \.isNewline)
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let firstLine, !firstLine.isEmpty else {
            return kind.rawValue
        }

        if firstLine.count <= 48 {
            return firstLine
        }

        return String(firstLine.prefix(45)) + "..."
    }

    private static func makePreview(for content: String) -> String {
        let compact = content
            .split(whereSeparator: \.isNewline)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard compact.count > 180 else {
            return compact
        }

        return String(compact.prefix(177)) + "..."
    }

    private static func isURL(_ content: String) -> Bool {
        guard content.count < 2_048 else {
            return false
        }

        if let url = URL(string: content), url.scheme != nil, url.host != nil {
            return true
        }

        return content.hasPrefix("www.")
            || content.hasPrefix("github.com/")
            || content.hasPrefix("developer.apple.com/")
    }

    private static func isEmail(_ content: String) -> Bool {
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return content.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    private static func isJSON(_ content: String) -> Bool {
        guard let first = content.first, first == "{" || first == "[" else {
            return false
        }

        guard let object = try? JSONSerialization.jsonObject(with: Data(content.utf8)) else {
            return false
        }

        return JSONSerialization.isValidJSONObject(object)
    }

    private static func isShellCommand(_ content: String) -> Bool {
        let commandPrefixes = [
            "git ", "npm ", "pnpm ", "yarn ", "swift ", "cargo ", "python ",
            "python3 ", "node ", "curl ", "cd ", "ls ", "mkdir ", "rm ", "grep ",
            "rg ", "docker ", "brew "
        ]

        return !content.contains("\n") && commandPrefixes.contains { content.hasPrefix($0) }
    }

    private static func isCodeLike(_ content: String) -> Bool {
        let markers = ["func ", "struct ", "class ", "enum ", "import ", "let ", "const ", "=>", "{", "};"]
        let markerCount = markers.filter { content.contains($0) }.count

        return content.contains("\n") && markerCount >= 2
    }
}
