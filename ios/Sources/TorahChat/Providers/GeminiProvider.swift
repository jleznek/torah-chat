import Foundation

final class GeminiProvider: LLMProvider {
    let info: ProviderInfo
    private let apiKey: String
    private let model: String
    private static let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"

    init(info: ProviderInfo, apiKey: String, model: String?) {
        self.info = info
        self.apiKey = apiKey
        self.model = model ?? info.defaultModel
    }

    // MARK: - streamChat

    func streamChat(
        history: [HistoryMessage],
        systemPrompt: String,
        tools: [ToolDeclaration],
        onTextChunk: @escaping @Sendable (String) -> Void,
        signal: AbortSignal
    ) async throws -> StreamResult {
        let contents = convertHistory(history)

        var body: [String: Any] = [
            "contents": contents,
            "systemInstruction": ["parts": [["text": systemPrompt]]],
            "generationConfig": [
                "maxOutputTokens": 8192,
            ] as [String: Any],
        ]
        if !tools.isEmpty {
            body["tools"] = [["function_declarations": tools.map(encodeTool)]]
        }

        let urlStr = "\(Self.baseURL)/\(model):streamGenerateContent?alt=sse&key=\(apiKey)"
        var request = URLRequest(url: URL(string: urlStr)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, _) = try await URLSession.shared.bytes(for: request)

        var accumulatedText = ""
        var functionCalls: [FunctionCall] = []

        for try await line in bytes.lines {
            if signal.isCancelled { break }
            guard line.hasPrefix("data: ") else { continue }
            let data = String(line.dropFirst(6))
            guard
                let jsonData = data.data(using: .utf8),
                let obj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                let candidates = obj["candidates"] as? [[String: Any]],
                let content = candidates.first?["content"] as? [String: Any],
                let parts = content["parts"] as? [[String: Any]]
            else { continue }

            for part in parts {
                if let text = part["text"] as? String, !text.isEmpty {
                    accumulatedText += text
                    onTextChunk(text)
                }
                if let fc = part["functionCall"] as? [String: Any],
                   let name = fc["name"] as? String,
                   let argsAny = fc["args"] as? [String: Any] {
                    let args = argsAny.mapValues(JSONValue.from)
                    functionCalls.append(FunctionCall(name: name, args: args, id: nil))
                }
            }
        }

        return StreamResult(text: accumulatedText, functionCalls: functionCalls)
    }

    func validateKey() async -> Bool {
        let urlStr = "\(Self.baseURL)?key=\(apiKey)"
        guard let url = URL(string: urlStr),
              let (_, response) = try? await URLSession.shared.data(from: url),
              let http = response as? HTTPURLResponse
        else { return false }
        return (200...299).contains(http.statusCode)
    }

    // MARK: - Helpers

    /// Converts canonical history to Gemini's `contents` format (role + parts).
    private func convertHistory(_ history: [HistoryMessage]) -> [[String: Any]] {
        history.compactMap { msg -> [String: Any]? in
            let parts: [[String: Any]] = msg.parts.compactMap { part in
                switch part {
                case .text(let t) where !t.isEmpty:
                    return ["text": t]
                case .functionCall(let name, let args, _):
                    return ["functionCall": ["name": name, "args": args.mapValues { $0.anyValue }] as [String: Any]]
                case .functionResponse(let name, let response, _):
                    return ["functionResponse": [
                        "name":     name,
                        "response": response.anyValue,
                    ] as [String: Any]]
                default:
                    return nil
                }
            }
            guard !parts.isEmpty else { return nil }
            return ["role": msg.role, "parts": parts]
        }
    }

    private func encodeTool(_ tool: ToolDeclaration) -> [String: Any] {
        [
            "name":        tool.name,
            "description": tool.description,
            "parameters":  tool.parameters.mapValues { $0.anyValue } as [String: Any],
        ]
    }
}
