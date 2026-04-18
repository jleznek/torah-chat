import Foundation
import Security

/// Stores and retrieves LLM API keys securely in the iOS Keychain.
enum KeychainService {
    private static let service = "org.torahchat.apikeys"

    static func save(key: String, forProvider providerId: String) {
        let data = Data(key.utf8)
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: providerId,
        ]
        // Delete any existing item first
        SecItemDelete(query as CFDictionary)
        // Add new item
        var attributes = query
        attributes[kSecValueData as String] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func load(forProvider providerId: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrService as String:      service,
            kSecAttrAccount as String:      providerId,
            kSecReturnData as String:       true,
            kSecMatchLimit as String:       kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(forProvider providerId: String) {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: providerId,
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func hasKey(forProvider providerId: String) -> Bool {
        load(forProvider: providerId) != nil
    }
}
