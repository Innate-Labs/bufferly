import Foundation

enum ClipClassifier {
    static func makeClip(from rawText: String, source: String = "剪贴板") -> ClipItem? {
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
            content: content
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
