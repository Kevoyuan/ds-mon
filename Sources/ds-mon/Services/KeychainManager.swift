import Foundation
import Security

struct KeychainManager {
    private static let service = "com.ds-mon.api-keys"
    private static let account = "deepseek-keys"

    static func save(_ keys: [StoredAPIKey]) throws {
        let data = try JSONEncoder().encode(keys)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    static func load() throws -> [StoredAPIKey] {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            if status == errSecItemNotFound { return [] }
            throw KeychainError.loadFailed(status)
        }
        return try JSONDecoder().decode([StoredAPIKey].self, from: data)
    }

    static func deleteAll() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum KeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let s): return "Failed to save API keys (code: \(s))"
        case .loadFailed(let s): return "Failed to load API keys (code: \(s))"
        }
    }
}
