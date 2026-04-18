import Foundation

// MARK: - Message

/// A single chat message displayed in the UI.
struct Message: Identifiable, Codable, Equatable {
    let id: UUID
    var role: MessageRole
    /// Rendered text shown to the user. May be in Markdown.
    var content: String
    /// True while the assistant is still streaming tokens.
    var isStreaming: Bool

    enum MessageRole: String, Codable {
        case user
        case assistant
    }

    init(id: UUID = UUID(), role: MessageRole, content: String, isStreaming: Bool = false) {
        self.id = id
        self.role = role
        self.content = content
        self.isStreaming = isStreaming
    }
}

// MARK: - HistoryMessage (canonical Gemini-style format used internally)

/// Internal representation of conversation history passed to LLM providers.
/// Uses the same Gemini-style parts format as the desktop app so provider
/// conversion logic stays consistent.
struct HistoryMessage: Codable {
    var role: String // "user" | "model"
    var parts: [MessagePart]
}

enum MessagePart: Codable {
    case text(String)
    case functionCall(name: String, args: [String: JSONValue], id: String?)
    case functionResponse(name: String, response: JSONValue, callId: String?)

    // MARK: Codable
    private enum CodingKeys: String, CodingKey {
        case text, functionCall, functionResponse
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let text = try container.decodeIfPresent(String.self, forKey: .text) {
            self = .text(text)
        } else if let fc = try container.decodeIfPresent(FunctionCallPayload.self, forKey: .functionCall) {
            self = .functionCall(name: fc.name, args: fc.args, id: fc.id)
        } else if let fr = try container.decodeIfPresent(FunctionResponsePayload.self, forKey: .functionResponse) {
            self = .functionResponse(name: fr.name, response: fr.response, callId: fr.callId)
        } else {
            self = .text("")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let t):
            try container.encode(t, forKey: .text)
        case .functionCall(let name, let args, let id):
            try container.encode(FunctionCallPayload(name: name, args: args, id: id), forKey: .functionCall)
        case .functionResponse(let name, let response, let callId):
            try container.encode(FunctionResponsePayload(name: name, response: response, callId: callId), forKey: .functionResponse)
        }
    }

    private struct FunctionCallPayload: Codable {
        let name: String
        let args: [String: JSONValue]
        let id: String?
    }

    private struct FunctionResponsePayload: Codable {
        let name: String
        let response: JSONValue
        let callId: String?
    }
}

// MARK: - JSONValue

/// A type-safe JSON value that can be used where `Any` would normally appear.
indirect enum JSONValue: Codable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let n = try? container.decode(Double.self) {
            self = .number(n)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let a = try? container.decode([JSONValue].self) {
            self = .array(a)
        } else if let o = try? container.decode([String: JSONValue].self) {
            self = .object(o)
        } else {
            self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .number(let n): try container.encode(n)
        case .bool(let b):   try container.encode(b)
        case .array(let a):  try container.encode(a)
        case .object(let o): try container.encode(o)
        case .null:          try container.encodeNil()
        }
    }

    /// Convert to a plain `Any` for use with JSONSerialization.
    var anyValue: Any {
        switch self {
        case .string(let s): return s
        case .number(let n): return n
        case .bool(let b):   return b
        case .array(let a):  return a.map(\.anyValue)
        case .object(let o): return o.mapValues(\.anyValue)
        case .null:          return NSNull()
        }
    }

    /// Build a JSONValue from a plain `Any` (result of JSONSerialization).
    static func from(_ value: Any) -> JSONValue {
        switch value {
        case let s as String:          return .string(s)
        case let b as Bool:            return .bool(b)
        case let n as Double:          return .number(n)
        case let n as Int:             return .number(Double(n))
        case let a as [Any]:           return .array(a.map(JSONValue.from))
        case let o as [String: Any]:   return .object(o.mapValues(JSONValue.from))
        default:                       return .null
        }
    }
}
