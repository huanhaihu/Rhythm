import Foundation

enum ClaudeClientError: Error, LocalizedError {
    case missingKey
    case network(Error)
    case apiError(String)
    case decodeFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingKey: return "未配置 Claude API Key，请在设置页填入。"
        case .network(let e): return "网络错误：\(e.localizedDescription)"
        case .apiError(let msg): return "API 错误：\(msg)"
        case .decodeFailed(let msg): return "解析失败：\(msg)"
        }
    }
}

final class ClaudeClient {
    let apiKey: String
    let model: String
    let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    init(apiKey: String, model: String = "claude-sonnet-4-6") {
        self.apiKey = apiKey
        self.model = model
    }

    func generateMonthlyReflection(
        monthKey: String,
        entries: [(date: String, text: String)]
    ) async throws -> MonthlyReflection {
        guard !apiKey.isEmpty else { throw ClaudeClientError.missingKey }

        let listing = entries.map { "\($0.date)：\($0.text)" }.joined(separator: "\n")

        let systemPrompt = """
        你是一位温和细致的感受与生活总结助手。用户会给你一段时间内的每日随想笔记。请阅读后生成一份中文月度感受总结。

        要求：
        1. summary 字段：不超过 300 字，用温暖、简洁、有洞察的语气回顾这个月的整体情绪起伏、关注点、变化趋势。不要逐条复述，而是提炼整体脉络。
        2. themes 字段：3-5 个主题关键词（每个 2-6 字，如"运动坚持"、"工作焦虑"、"新尝试"）。
        3. highlights 字段：3 条最值得记住的时刻或感受，每条 15-40 字，尽量保留用户原文中的具象细节。
        4. 严格输出 JSON，不要任何额外说明、代码块标记或前后缀文字。

        JSON schema：
        {
          "summary": "string",
          "themes": ["string"],
          "highlights": ["string"]
        }
        """

        let userPrompt = """
        月份：\(monthKey)
        笔记条数：\(entries.count)

        \(listing)
        """

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1200,
            "temperature": 0.6,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userPrompt]
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 60

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ClaudeClientError.network(error)
        }

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "未知错误"
            throw ClaudeClientError.apiError(msg)
        }

        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = obj["content"] as? [[String: Any]],
              let first = content.first,
              let text = first["text"] as? String else {
            throw ClaudeClientError.decodeFailed("响应结构异常")
        }

        let cleaned = stripCodeFence(text).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let jsonData = cleaned.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let summary = parsed["summary"] as? String,
              let themes = parsed["themes"] as? [String],
              let highlights = parsed["highlights"] as? [String] else {
            throw ClaudeClientError.decodeFailed("模型未返回合法 JSON")
        }

        return MonthlyReflection(
            monthKey: monthKey,
            summary: summary,
            themes: themes,
            highlights: highlights,
            entryCount: entries.count,
            generatedAt: Date()
        )
    }

    private func stripCodeFence(_ s: String) -> String {
        var text = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            if let firstNewline = text.firstIndex(of: "\n") {
                text = String(text[text.index(after: firstNewline)...])
            }
            if text.hasSuffix("```") {
                text = String(text.dropLast(3))
            }
        }
        return text
    }
}
