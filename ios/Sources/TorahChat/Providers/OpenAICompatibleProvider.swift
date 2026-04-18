import Foundation

/// Handles all OpenAI-API-compatible providers: OpenAI, Groq, Grok (xAI),
/// DeepSeek, Mistral, and OpenRouter — they all share the same JSON API format.
final class OpenAICompatibleProvider: LLMProvider {
    let info: ProviderInfo
    private let apiKey: String
    private let model: String
    private let baseURL: String

    init(info: ProviderInfo, apiKey: String, model: String?, baseURL: String) {
        self.info = info
        self.apiKey = apiKey
        self.model = model ?? info.defaultModel
        self.baseURL = baseURL
    }

    // MARK: - streamChat

    func streamChat(
        history: [HistoryMessage],
        systemPrompt: String,
        tools: [ToolDeclaration],
        onTextChunk: @escaping @Sendable (String) -> Void,
        signal: AbortSignal
    ) async throws -> StreamResult {
        let messages = convertHistory(history, systemPrompt: systemPrompt)

        var body: [String: Any] = [
            "model":  model,
            "stream": true,
            "messages": messages,
        ]
        if !tools.isEmpty {
            body["tools"] = tools.map(encodeTool)
            body["tool_choice"] = "auto"
        }

        let request = try buildRequest(path: "/chat/completions", body: body)
        let (bytes, _) = try await URLSession.shared.bytes(for: request)

        var accumulatedText = ""
        var toolCalls: [(id: String, name: String, argsJSON: String)] = []

        for try await line in bytes.lines {
            if signal.isCancelled { break }
            guard line.hasPrefix("data: ") else { continue }
            let data = String(line.dropFirst(6))
            if data == "[DONE]" { break }
            guard
                let jsonData = data.data(using: .utf8),
                let obj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                let choices = obj["choices"] as? [[String: Any]],
                let delta = choices.first?["delta"] as? [String: Any]
            else { continue }

            if let text = delta["content"] as? String, !text.isEmpty {
                accumulatedText += text
                onTextChunk(text)
            }
            // Tool call delta accumulation
            if let tcDeltas = delta["tool_calls"] as? [[String: Any]] {
                for tcDelta in tcDeltas {
                    let index = tcDelta["index"] as? Int ?? 0
                    while toolCalls.count <= index {
                        toolCalls.append((id: "", name: "", argsJSON: ""))
                    }
                    if let id = (tcDelta["id"] as? String) { toolCalls[index].id = id }
                    if let fn = tcDelta["function"] as? [String: Any] {
                        if let nm = fn["name"] as? String { toolCalls[index].name += nm }
                        if let ag = fn["arguments"] as? String { toolCalls[index].argsJSON += ag }
                    }
                }
            }
        }

        let parsedCalls: [FunctionCall] = toolCalls.compactMap { tc in
            guard !tc.name.isEmpty else { return nil }
            let args = parseArgs(tc.argsJSON)
            return FunctionCall(name: tc.name, args: args, id: tc.id.isEmpty ? nil : tc.id)
        }

        return StreamResult(text: accumulatedText, functionCalls: parsedCalls)
    }

    // MARK: - validateKey

    func validateKey() async -> Bool {
        // Send a minimal non-streaming request to validate
        guard let url = URL(string: "\(baseURL)/models") else { return false }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        guard let (_, response) = try? await URLSession.shared.data(for: req),
              let http = response as? HTTPURLResponse
        else { return false }
        return (200...299).contains(http.statusCode)
    }

    // MARK: - Helpers

    private func buildRequest(path: String, body: [String: Any]) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func convertHistory(_ history: [HistoryMessage], systemPrompt: String) -> [[String: Any]] {
        var messages: [[String: Any]] = [["role": "system", "content": systemPrompt]]
        for msg in history {
            let roleStr = msg.role == "model" ? "assistant" : msg.role
            let hasToolResponses = msg.parts.contains {
                if case .functionResponse = $0 { return true }
                return false
            }
            if hasToolResponses {
                for part in msg.parts {
                    switch part {
                    case .functionResponse(let name, let response, let callId):
                        messages.append([
                            "role":         "tool",
                            "tool_call_id": callId ?? name,
                            "content":      jsonString(response),
                        ])
                    case .text(let t) where !t.isEmpty:
                        messages.append(["role": "user", "content": t])
                    default: break
                    }
                }
            } else {
                let texts = msg.parts.compactMap { part -> String? in
                    if case .text(let t) = part, !t.isEmpty { return t }
                    return nil
                }
                // Collect tool calls from assistant turns
                let tcs = msg.parts.compactMap { part -> [String: Any]? in
                    if case .functionCall(let name, let args, let id) = part {
                        var tc: [String: Any] = [
                            "type": "function",
                            "function": ["name": name, "arguments": jsonString(.object(args))],
                        ]
                        if let id { tc["id"] = id }
                        return tc
                    }
                    return nil
                }
                if !tcs.isEmpty {
                    var m: [String: Any] = ["role": roleStr]
                    if !texts.isEmpty { m["content"] = texts.joined(separator: "\n") }
                    m["tool_calls"] = tcs
                    messages.append(m)
                } else if !texts.isEmpty {
                    messages.append(["role": roleStr, "content": texts.joined(separator: "\n")])
                }
            }
        }
        return messages
    }

    private func encodeTool(_ tool: ToolDeclaration) -> [String: Any] {
        [
            "type": "function",
            "function": [
                "name":        tool.name,
                "description": tool.description,
                "parameters":  tool.parameters.mapValues { $0.anyValue } as [String: Any],
            ] as [String: Any],
        ]
    }

    private func parseArgs(_ json: String) -> [String: JSONValue] {
        guard !json.isEmpty,
              let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [:] }
        return obj.mapValues(JSONValue.from)
    }

    private func jsonString(_ value: JSONValue) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: value.anyValue),
              let str = String(data: data, encoding: .utf8)
        else { return "{}" }
        return str
    }
}
