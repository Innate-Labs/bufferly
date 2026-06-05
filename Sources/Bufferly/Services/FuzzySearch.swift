import Foundation

/// 轻量模糊匹配 + 打分。子序列匹配（query 的字符按序出现在 text 中即算命中），
/// 对「连续命中」「词首命中」「起始命中」加分，越相关分越高；不命中返回 nil。
enum FuzzySearch {
    static func score(query: String, in text: String) -> Int? {
        let queryChars = Array(query.lowercased())
        guard !queryChars.isEmpty else { return 0 }

        let original = Array(text)
        guard queryChars.count <= original.count else { return nil }

        var score = 0
        var queryIndex = 0
        var previousMatchIndex = -2

        for (textIndex, character) in original.enumerated() {
            guard queryIndex < queryChars.count else { break }

            guard character.lowercased() == String(queryChars[queryIndex]) else {
                continue
            }

            var charScore = 1

            // 连续命中：紧接上一个命中
            if textIndex == previousMatchIndex + 1 {
                charScore += 5
            }

            if textIndex == 0 {
                // 整段起始命中
                charScore += 8
            } else {
                let previous = original[textIndex - 1]
                if previous == " " || previous == "_" || previous == "-" || previous == "/" || previous == "." {
                    // 词首命中（分隔符之后）
                    charScore += 6
                } else if previous.isLowercase && character.isUppercase {
                    // camelCase 边界
                    charScore += 4
                }
            }

            score += charScore
            previousMatchIndex = textIndex
            queryIndex += 1
        }

        // query 必须全部命中
        guard queryIndex == queryChars.count else {
            return nil
        }

        // 文本越短相对越相关（轻微加权）
        score += max(0, 10 - original.count / 20)
        return score
    }
}
