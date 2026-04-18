import Foundation

final class AnthropicProvider: LLMProvider {
    let info: ProviderInfo
    private let apiKey: String
    private let model: String
    private static let apiVersion = "2023-06-01"
    private static let baseURL = "https://api.anthropic.com/v1"

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
        let messages = convertHistory(history)

        var body: [String: Any] = [
            "model":      model,
            "max_tokens": 8096,
            "stream":     true,
            "system":     systemPrompt,
            "messages":   messages,
        ]
        if !tools.isEmpty {
            body["tools"] = tools.map(encodeTool)
        }

        var request = URLRequest(url: URL(string: "\(Self.baseURL)/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json",   forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey,               forHTTPHeaderField: "x-api-key")
        request.setValue(Self.apiVersion,      forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, _) = try await URLSession.shared.bytes(for: request)

        var accumulatedText = ""
        var toolUseBlocks: [String: (name: String, inputJSON: String)] = [:]
        var currentToolId: String? = nil

        for try await line in bytes.lines {
            if signal.isCancelled { break }
            guard line.hasPrefix("data: ") else { continue }
            let data = String(line.dropFirst(6))
            guard
                let jsonData = data.data(using: .utf8),
                let obj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
            else { continue }

            let eventType = obj["type"] as? String ?? ""
            switch eventType {
            case "content_block_start":
                if let block = obj["content_block"] as? [String: Any],
                   block["type"] as? String == "tool_use",
                   let id = block["id"] as? String,
                   let nm = block["name"] as? String {
                    toolUseBlocks[id] = (name: nm, inputJSON: "")
                    currentToolId = id
                }
            case "content_block_delta":
                if let delta = obj["delta"] as? [String: Any] {
                    if delta["type"] as? String == "text_delta",
                       let text = delta["text"] as? String {
                        accumulatedText += text
                        onTextChunk(text)
                    } else if delta["type"] as? String == "input_json_delta",
                              let partial = delta["partial_json"] as? String,
                              let id = currentToolId {
                        toolUseBlocks[id]?.inputJSON += partial
                    }
                }
            case "content_block_stop":
                currentToolId = nil
            default:
                break
            }
        }

        let parsedCalls: [FunctionCall] = toolUseBlocks.map { (id, tc) in
            let args = parseArgs(tc.inputJSON)
            return FunctionCall(name: tc.name, args: args, id: id)
        }

        return StreamResult(text: accumulatedText, functionCalls: parsedCalls)
    }

    func validateKey() async -> Bool {
        // Minimal request to validate key
        var req = URLRequest(url: URL(string: "\(Self.baseURL)/models")!)
        req.setValue(apiKey,           forHTTPHeaderField: "x-api-key")
        req.setValue(Self.apiVersion,  forHTTPHeaderField: "anthropic-version")
        guard let (_, response) = try? await URLSession.shared.data(for: req),
              let http = response as? HTTPURLResponse
        else { return false }
        return (200...299).contains(http.statusCode)
    }

    // MARK: - Helpers

    /// Converts canonical Gemini-style history to Anthropic's messages format.
    private func convertHistory(_ history: [HistoryMessage]) -> [[String: Any]] {
        var messages: [[String: Any]] = []
        for msg in history {
            let roleStr = msg.role == "model" ? "assistant" : msg.role
            var contentBlocks: [[String: Any]] = []

            for part in msg.parts {
                switch part {
                case .text(let t) where !t.isEmpty:
                    contentBlocks.append(["type": "text", "text": t])

                case .functionCall(let name, let args, let id):
                    contentBlocks.append([
                        "type": "tool_use",
                        "id":   id ?? "call_\(name)",
                        "name": name,
                        "input": args.mapValues { $0.anyValue } as [String: Any],
                    ])

                case .functionResponse(let name, let response, let callId):
                    // Anthropic tool results go in a separate user turn
                    let resultBlock: [String: Any] = [
                        "type":        "tool_result",
                        "tool_use_id": callId ?? name,
                        "content":     jsonString(response),
                    ]
                    // Flush previous content first
                    if !contentBlocks.isEmpty {
                        messages.append(["role": roleStr, "content": contentBlocks])
                        contentBlocks = []
                    }
                    messages.append(["role": "user", "content": [resultBlock]])

                default: break
                }
            }

            if !contentBlocks.isEmpty {
                messages.append(["role": roleStr, "content": contentBlocks])
            }
        }
        return messages
    }

    private func encodeTool(_ tool: ToolDeclaration) -> [String: Any] {
        [
            "name":         tool.name,
            "description":  tool.description,
            "input_schema": tool.parameters.mapValues { $0.anyValue } as [String: Any],
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
