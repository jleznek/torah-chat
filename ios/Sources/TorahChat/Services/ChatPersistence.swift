import Foundation

/// Persists chat sessions to the app's Documents directory.
actor ChatPersistence {
    private let directory: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        directory = docs.appendingPathComponent("chats", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    // MARK: - CRUD

    func save(_ chat: Chat) throws {
        let url = fileURL(for: chat.id)
        let data = try JSONEncoder().encode(chat)
        try data.write(to: url, options: .atomic)
    }

    func load(id: UUID) throws -> Chat? {
        let url = fileURL(for: id)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Chat.self, from: data)
    }

    func delete(id: UUID) throws {
        let url = fileURL(for: id)
        try? FileManager.default.removeItem(at: url)
    }

    func listAll() throws -> [Chat] {
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { url in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder().decode(Chat.self, from: data)
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    // MARK: - Settings persistence

    private var settingsURL: URL {
        directory.deletingLastPathComponent().appendingPathComponent("settings.json")
    }

    func saveSettings(_ settings: AppSettings) throws {
        let data = try JSONEncoder().encode(settings)
        try data.write(to: settingsURL, options: .atomic)
    }

    func loadSettings() -> AppSettings {
        guard let data = try? Data(contentsOf: settingsURL),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else { return AppSettings() }
        return settings
    }

    // MARK: - Private

    private func fileURL(for id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString).json")
    }
}

// MARK: - AppSettings

struct AppSettings: Codable {
    var providerId: String = "gemini"
    var modelId: String   = "gemini-2.0-flash"
    var responseLength: String = "balanced" // "concise" | "balanced" | "detailed"
}
