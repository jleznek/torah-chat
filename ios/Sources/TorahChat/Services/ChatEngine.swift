import Foundation

/// Orchestrates the LLM tool-calling loop, mirroring the desktop `ChatEngine`.
/// Up to 10 rounds: stream → execute tool calls → feed results back → repeat.
actor ChatEngine {
    private var provider: LLMProvider
    private var modelId: String
    private let sefariaService: SefariaService
    private let rateLimiter: RateLimiter
    private var conversationHistory: [HistoryMessage] = []

    // MARK: - Init

    init(provider: LLMProvider, sefariaService: SefariaService) {
        self.provider = provider
        self.modelId = provider.info.defaultModel
        self.sefariaService = sefariaService
        self.rateLimiter = RateLimiter()
    }

    // MARK: - Public API

    func updateProvider(_ provider: LLMProvider, modelId: String? = nil) {
        self.provider = provider
        self.modelId = modelId ?? provider.info.defaultModel
    }

    func clearHistory() {
        conversationHistory = []
    }

    func setHistory(_ history: [HistoryMessage]) {
        conversationHistory = history
    }

    func getHistory() -> [HistoryMessage] {
        conversationHistory
    }

    /// Effective RPM: per-model override or provider default.
    private func effectiveRpm() -> Int {
        let model = provider.info.models.first { $0.id == modelId }
        return model?.rpm ?? provider.info.rateLimit.rpm
    }

    // MARK: - sendMessage

    /// Send a user message and stream the response.
    /// - Parameters:
    ///   - message: The user's message text.
    ///   - responseLength: "concise" | "balanced" | "detailed"
    ///   - onTextChunk: Called on the main actor for each streamed token.
    ///   - onToolStatus: Called when a Sefaria tool is invoked.
    ///   - signal: Cancellation token.
    func sendMessage(
        _ message: String,
        responseLength: String,
        onTextChunk: @escaping @Sendable (String) -> Void,
        onToolStatus: @escaping @Sendable (String, String) -> Void,
        signal: AbortSignal
    ) async throws {
        let systemPrompt = buildSystemPrompt(responseLength: responseLength)

        // Append user turn
        conversationHistory.append(HistoryMessage(
            role: "user",
            parts: [.text(message)]
        ))

        let maxRounds = 10
        for _ in 0..<maxRounds {
            if signal.isCancelled { break }

            // Rate limiting
            await rateLimiter.waitForCapacity(
                rpm: effectiveRpm(),
                windowMs: provider.info.rateLimit.windowMs
            )
            await rateLimiter.record()

            let result = try await provider.streamChat(
                history: conversationHistory,
                systemPrompt: systemPrompt,
                tools: SEFARIA_TOOLS,
                onTextChunk: onTextChunk,
                signal: signal
            )

            // Append assistant turn
            var assistantParts: [MessagePart] = []
            if !result.text.isEmpty {
                assistantParts.append(.text(result.text))
            }
            for fc in result.functionCalls {
                assistantParts.append(.functionCall(name: fc.name, args: fc.args, id: fc.id))
            }
            if !assistantParts.isEmpty {
                conversationHistory.append(HistoryMessage(role: "model", parts: assistantParts))
            }

            // If no tool calls, we're done
            if result.functionCalls.isEmpty { break }

            // Execute tool calls and append tool responses as a user turn
            var toolResponseParts: [MessagePart] = []
            for fc in result.functionCalls {
                if signal.isCancelled { break }
                onToolStatus(fc.name, "calling")
                let response: JSONValue
                do {
                    response = try await sefariaService.callTool(name: fc.name, args: fc.args)
                } catch {
                    response = .object(["error": .string(error.localizedDescription)])
                }
                onToolStatus(fc.name, "done")
                toolResponseParts.append(.functionResponse(
                    name: fc.name,
                    response: response,
                    callId: fc.id
                ))
            }
            if !toolResponseParts.isEmpty {
                conversationHistory.append(HistoryMessage(role: "user", parts: toolResponseParts))
            }
        }
    }

    // MARK: - System prompt

    private func buildSystemPrompt(responseLength: String) -> String {
        var prompt = SEFARIA_SYSTEM_PROMPT
        switch responseLength {
        case "concise":
            prompt += "\n\nIMPORTANT: The user has requested a CONCISE response. Keep prose brief — short paragraphs, minimal commentary. Still present actual content from sources (texts, translations), just keep your surrounding commentary concise."
        case "detailed":
            prompt += "\n\nIMPORTANT: The user has requested a DETAILED response. Provide comprehensive, thorough answers with extensive commentary, multiple perspectives, cross-references, historical context, and full Hebrew/Aramaic text with translations."
        default:
            prompt += "\n\nProvide a balanced response — moderately detailed with key sources and context, but not exhaustively long."
        }
        return prompt
    }
}
