import Foundation
import Security

enum KeychainError: Error {
    case saveError
    case loadError
    case deleteError
    case unexpectedData
}

final class KeychainManager {
    static let shared = KeychainManager()

    private init() {}

    private enum Key {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
    }

    func saveAccessToken(_ token: String) throws {
        try save(token, forKey: Key.accessToken)
    }

    func saveRefreshToken(_ token: String) throws {
        try save(token, forKey: Key.refreshToken)
    }

    func loadAccessToken() throws -> String {
        return try load(forKey: Key.accessToken)
    }

    func loadRefreshToken() throws -> String {
        return try load(forKey: Key.refreshToken)
    }

    func deleteAccessToken() throws {
        try delete(forKey: Key.accessToken)
    }

    func deleteRefreshToken() throws {
        try delete(forKey: Key.refreshToken)
    }

    func deleteAllTokens() throws {
        try? deleteAccessToken()
        try? deleteRefreshToken()
    }

    private func save(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.unexpectedData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveError
        }
    }

    private func load(forKey key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            throw KeychainError.loadError
        }

        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }

        return value
    }

    private func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteError
        }
    }
}
