import Foundation

/// The protocol every LLM provider must implement.
protocol LLMProvider {
    var info: ProviderInfo { get }

    /// Stream a chat response. Calls `onTextChunk` for each token.
    /// Returns the complete accumulated text and any tool/function calls.
    func streamChat(
        history: [HistoryMessage],
        systemPrompt: String,
        tools: [ToolDeclaration],
        onTextChunk: @escaping @Sendable (String) -> Void,
        signal: AbortSignal
    ) async throws -> StreamResult

    /// Validate the API key by making a lightweight request.
    func validateKey() async -> Bool

    /// Return balance info if the provider supports it, otherwise nil.
    func getBalance() async -> BalanceInfo?
}

// Default implementations
extension LLMProvider {
    func validateKey() async -> Bool { true }
    func getBalance() async -> BalanceInfo? { nil }
}

// MARK: - AbortSignal

/// Simple cancellation token so the UI can cancel mid-stream.
final class AbortSignal: @unchecked Sendable {
    private(set) var isCancelled = false
    func cancel() { isCancelled = true }
}
