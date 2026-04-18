import Foundation

struct ProviderModel: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    /// Per-model RPM override. Falls back to provider-level rateLimit.
    var rpm: Int?
}

struct ProviderInfo: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var models: [ProviderModel]
    var defaultModel: String
    var rateLimit: RateLimit
    /// If false, the provider works without an API key (e.g. Ollama local).
    var requiresKey: Bool
    var keyPlaceholder: String
    var keyHelpURL: String
    var keyHelpLabel: String

    struct RateLimit: Codable, Hashable {
        var rpm: Int
        var windowMs: Int
    }
}

// MARK: - Tool types

struct ToolDeclaration: Codable {
    let name: String
    let description: String
    /// JSON Schema object for the parameters.
    let parameters: [String: JSONValue]
}

struct FunctionCall: Codable {
    let name: String
    let args: [String: JSONValue]
    let id: String?
}

struct StreamResult {
    let text: String
    let functionCalls: [FunctionCall]
}

struct BalanceInfo {
    let balance: Double
    let currency: String
}
