import Foundation
import Observation

@Observable
final class ChatViewModel {
    // MARK: - Published state

    var chats: [Chat] = []
    var activeChat: Chat? = nil
    var isStreaming = false
    var toolStatus: String? = nil
    var errorMessage: String? = nil
    var settings = AppSettings()

    // Provider state
    var availableProviders: [ProviderInfo] = AVAILABLE_PROVIDERS
    var selectedProviderId: String = "gemini"
    var selectedModelId: String = "gemini-2.0-flash"

    // MARK: - Private

    private let sefariaService = SefariaService()
    private let persistence    = ChatPersistence()
    private var engine: ChatEngine?
    private var activeSignal: AbortSignal?

    // MARK: - Init

    init() {
        Task { await loadInitialState() }
    }

    // MARK: - Setup

    @MainActor
    private func loadInitialState() async {
        settings = await persistence.loadSettings()
        selectedProviderId = settings.providerId
        selectedModelId    = settings.modelId

        // Reload all chats
        if let loaded = try? await persistence.listAll() {
            chats = loaded
        }

        rebuildEngine()
    }

    private func rebuildEngine() {
        let providerId = selectedProviderId
        let modelId    = selectedModelId
        let apiKey     = KeychainService.load(forProvider: providerId) ?? ""
        guard let provider = createProvider(providerId: providerId, apiKey: apiKey, model: modelId) else { return }
        if let engine {
            Task { await engine.updateProvider(provider, modelId: modelId) }
        } else {
            engine = ChatEngine(provider: provider, sefariaService: sefariaService)
        }
    }

    // MARK: - Chat management

    @MainActor
    func newChat() {
        let chat = Chat()
        chats.insert(chat, at: 0)
        activeChat = chat
        Task { await engine?.clearHistory() }
    }

    @MainActor
    func selectChat(_ chat: Chat) {
        activeChat = chat
        Task { await engine?.setHistory(chat.history) }
    }

    @MainActor
    func deleteChat(_ chat: Chat) {
        chats.removeAll { $0.id == chat.id }
        if activeChat?.id == chat.id { activeChat = nil }
        Task { try? await persistence.delete(id: chat.id) }
    }

    // MARK: - Send message

    @MainActor
    func send(text: String) async {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard let engine else {
            errorMessage = "No provider configured. Please add an API key in Settings."
            return
        }

        if activeChat == nil { newChat() }
        guard var chat = activeChat else { return }

        // Append user bubble
        let userMsg = Message(role: .user, content: text)
        chat.messages.append(userMsg)

        // Append streaming assistant placeholder
        let assistantId = UUID()
        let assistantMsg = Message(id: assistantId, role: .assistant, content: "", isStreaming: true)
        chat.messages.append(assistantMsg)
        activeChat = chat
        isStreaming = true
        toolStatus  = nil
        errorMessage = nil

        // Create title from first user message
        if chat.messages.filter({ $0.role == .user }).count == 1 {
            chat.title = String(text.prefix(50))
            activeChat = chat
            if let idx = chats.firstIndex(where: { $0.id == chat.id }) {
                chats[idx] = chat
            }
        }

        let signal = AbortSignal()
        activeSignal = signal

        var accumulatedText = ""

        do {
            try await engine.sendMessage(
                text,
                responseLength: settings.responseLength,
                onTextChunk: { [weak self] chunk in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        accumulatedText += chunk
                        self.updateStreamingMessage(id: assistantId, text: accumulatedText)
                    }
                },
                onToolStatus: { [weak self] toolName, status in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        let display = toolName
                            .replacingOccurrences(of: "_", with: " ")
                            .capitalized
                        self.toolStatus = status == "calling" ? "Looking up \(display)…" : nil
                    }
                },
                signal: signal
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        // Finalize
        await MainActor.run {
            finalizeStreamingMessage(id: assistantId, text: accumulatedText)
            isStreaming = false
            toolStatus  = nil
        }

        // Persist
        if var updated = activeChat {
            updated.history = await engine.getHistory()
            updated.updatedAt = Date()
            activeChat = updated
            if let idx = chats.firstIndex(where: { $0.id == updated.id }) {
                chats[idx] = updated
            }
            try? await persistence.save(updated)
        }
    }

    @MainActor
    func cancelStreaming() {
        activeSignal?.cancel()
        isStreaming = false
        toolStatus  = nil
        // Mark any streaming message as done
        guard var chat = activeChat else { return }
        for i in chat.messages.indices where chat.messages[i].isStreaming {
            chat.messages[i].isStreaming = false
        }
        activeChat = chat
    }

    // MARK: - Settings

    @MainActor
    func saveProviderConfig(providerId: String, modelId: String, apiKey: String?) {
        if let key = apiKey, !key.isEmpty {
            KeychainService.save(key: key, forProvider: providerId)
        }
        selectedProviderId = providerId
        selectedModelId    = modelId
        settings.providerId = providerId
        settings.modelId    = modelId
        Task { try? await persistence.saveSettings(settings) }
        rebuildEngine()
    }

    @MainActor
    func removeProviderKey(providerId: String) {
        KeychainService.delete(forProvider: providerId)
        if selectedProviderId == providerId {
            selectedProviderId = "gemini"
            selectedModelId    = GEMINI_INFO.defaultModel
            settings.providerId = selectedProviderId
            settings.modelId    = selectedModelId
            Task { try? await persistence.saveSettings(settings) }
            rebuildEngine()
        }
    }

    func hasKey(forProvider providerId: String) -> Bool {
        KeychainService.hasKey(forProvider: providerId)
    }

    func apiKey(forProvider providerId: String) -> String {
        KeychainService.load(forProvider: providerId) ?? ""
    }

    // MARK: - Private helpers

    @MainActor
    private func updateStreamingMessage(id: UUID, text: String) {
        guard var chat = activeChat else { return }
        if let idx = chat.messages.firstIndex(where: { $0.id == id }) {
            chat.messages[idx].content = text
            activeChat = chat
        }
    }

    @MainActor
    private func finalizeStreamingMessage(id: UUID, text: String) {
        guard var chat = activeChat else { return }
        if let idx = chat.messages.firstIndex(where: { $0.id == id }) {
            chat.messages[idx].content    = text
            chat.messages[idx].isStreaming = false
            activeChat = chat
        }
    }
}
