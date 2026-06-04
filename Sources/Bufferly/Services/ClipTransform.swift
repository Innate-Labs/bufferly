import Foundation

/// 面向开发者的内容转换：JSON 格式化 / 压缩、URL 去 tracking 参数。
/// 返回 nil 表示该内容不适用此转换（如非合法 JSON）。
enum ClipTransform {
    static func formatJSON(_ content: String) -> String? {
        reserializeJSON(content, pretty: true)
    }

    static func minifyJSON(_ content: String) -> String? {
        reserializeJSON(content, pretty: false)
    }

    private static func reserializeJSON(_ content: String, pretty: Bool) -> String? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let data = trimmed.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(
                with: data,
                options: [.fragmentsAllowed]
            )
        else {
            return nil
        }

        var options: JSONSerialization.WritingOptions = [.sortedKeys, .withoutEscapingSlashes]
        if pretty {
            options.insert(.prettyPrinted)
        }

        guard
            let outputData = try? JSONSerialization.data(withJSONObject: object, options: options),
            let output = String(data: outputData, encoding: .utf8)
        else {
            return nil
        }

        return output == trimmed ? nil : output
    }

    /// 常见跟踪参数前缀 / 名称。
    private static let trackingParameters: Set<String> = [
        "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
        "utm_id", "utm_name", "utm_cid", "utm_reader", "utm_referrer",
        "fbclid", "gclid", "dclid", "gclsrc", "msclkid", "twclid",
        "igshid", "igsh", "mc_cid", "mc_eid", "yclid", "_hsenc", "_hsmi",
        "vero_id", "vero_conv", "wickedid", "oly_anon_id", "oly_enc_id",
        "ref", "ref_src", "ref_url", "spm", "scm"
    ]

    static func cleanURL(_ content: String) -> String? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            var components = URLComponents(string: trimmed),
            components.scheme != nil,
            let queryItems = components.queryItems,
            !queryItems.isEmpty
        else {
            return nil
        }

        let kept = queryItems.filter { item in
            !trackingParameters.contains(item.name.lowercased())
        }

        guard kept.count != queryItems.count else {
            return nil
        }

        components.queryItems = kept.isEmpty ? nil : kept

        guard let cleaned = components.string, cleaned != trimmed else {
            return nil
        }

        return cleaned
    }
}
