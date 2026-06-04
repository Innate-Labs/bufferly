import Foundation

/// 敏感内容检测：token / API key / 私钥 / 密码 / `.env` 值 / 验证码等。
/// 命中后由上层决定是否脱敏不入库。规则偏保守，宁可漏判也尽量不误判普通文本。
enum SensitiveContentFilter {
    static func isSensitive(_ rawText: String) -> Bool {
        let content = rawText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !content.isEmpty, content.count <= 8_192 else {
            return false
        }

        if hasKnownSecretPrefix(content) {
            return true
        }

        if isPrivateKeyBlock(content) {
            return true
        }

        if isJWT(content) {
            return true
        }

        if isSensitiveEnvAssignment(content) {
            return true
        }

        if isLikelyHighEntropyToken(content) {
            return true
        }

        return false
    }

    /// 常见服务的密钥前缀（单 token，无空白）。
    private static func hasKnownSecretPrefix(_ content: String) -> Bool {
        guard !content.contains(where: \.isWhitespace) else {
            return false
        }

        let prefixes = [
            "sk-", "sk_live_", "sk_test_", "pk_live_", "rk_live_",
            "ghp_", "gho_", "ghu_", "ghs_", "ghr_", "github_pat_",
            "xoxb-", "xoxp-", "xoxa-", "xoxr-", "xapp-",
            "AKIA", "ASIA", "AIza", "ya29.",
            "glpat-", "npm_", "dop_v1_", "shpat_", "sq0atp-",
            "hf_", "r8_", "pat-"
        ]

        return prefixes.contains { content.hasPrefix($0) } && content.count >= 12
    }

    private static func isPrivateKeyBlock(_ content: String) -> Bool {
        content.contains("-----BEGIN") && content.contains("PRIVATE KEY")
    }

    /// JWT：三段 base64url，以 `eyJ` 开头。
    private static func isJWT(_ content: String) -> Bool {
        guard content.hasPrefix("eyJ"), !content.contains(where: \.isWhitespace) else {
            return false
        }

        let segments = content.split(separator: ".")
        return segments.count == 3 && segments.allSatisfy { $0.count >= 8 }
    }

    /// `.env` 风格赋值，且键名带敏感语义。
    private static func isSensitiveEnvAssignment(_ content: String) -> Bool {
        let lines = content.split(whereSeparator: \.isNewline)

        return lines.contains { line in
            guard let equalIndex = line.firstIndex(of: "=") else {
                return false
            }

            let key = line[line.startIndex..<equalIndex]
                .trimmingCharacters(in: .whitespaces)
                .uppercased()
            let value = line[line.index(after: equalIndex)...]
                .trimmingCharacters(in: .whitespaces)

            guard value.count >= 6 else {
                return false
            }

            let sensitiveKeyTokens = [
                "SECRET", "PASSWORD", "PASSWD", "TOKEN", "API_KEY", "APIKEY",
                "ACCESS_KEY", "PRIVATE_KEY", "CLIENT_SECRET", "AUTH", "CREDENTIAL"
            ]

            return sensitiveKeyTokens.contains { key.contains($0) }
        }
    }

    /// 单段无空白、长且高熵的字符串，疑似密钥（保守阈值）。
    private static func isLikelyHighEntropyToken(_ content: String) -> Bool {
        guard
            !content.contains(where: \.isWhitespace),
            content.count >= 24,
            content.count <= 256
        else {
            return false
        }

        let allowed = CharacterSet(charactersIn:
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_+/=.")
        guard content.unicodeScalars.allSatisfy(allowed.contains) else {
            return false
        }

        let hasUpper = content.contains(where: { $0.isUppercase })
        let hasLower = content.contains(where: { $0.isLowercase })
        let hasDigit = content.contains(where: { $0.isNumber })

        // 同时含大小写和数字，且不像普通单词/URL/路径，才判为高熵密钥。
        guard hasUpper, hasLower, hasDigit else {
            return false
        }

        if content.hasPrefix("http://") || content.hasPrefix("https://") {
            return false
        }

        return true
    }
}
