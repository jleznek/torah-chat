import Foundation

struct Chat: Identifiable, Codable {
    let id: UUID
    var title: String
    /// Display messages (user-visible).
    var messages: [Message]
    /// Internal history in Gemini-style parts format used by the LLM engine.
    var history: [HistoryMessage]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "New Chat",
        messages: [Message] = [],
        history: [HistoryMessage] = []
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.history = history
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
