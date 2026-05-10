import Foundation
import Security

/// A thin wrapper around the iOS Keychain for storing and retrieving string secrets.
enum KeychainHelper {

    // MARK: - Save / Update

    /// Saves (or updates) a UTF-8 string value for the given key.
    /// - Returns: `true` on success, `false` otherwise.
    @discardableResult
    static func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Try to update an existing item first.
        let updateQuery: [CFString: Any] = [
            kSecClass:           kSecClassGenericPassword,
            kSecAttrService:     Bundle.main.bundleIdentifier ?? "com.simplewinemanager",
            kSecAttrAccount:     key
        ]
        let attributes: [CFString: Any] = [kSecValueData: data]
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecSuccess {
            return true
        }

        // Item doesn't exist yet — add it.
        let addQuery: [CFString: Any] = [
            kSecClass:           kSecClassGenericPassword,
            kSecAttrService:     Bundle.main.bundleIdentifier ?? "com.simplewinemanager",
            kSecAttrAccount:     key,
            kSecValueData:       data,
            kSecAttrAccessible:  kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }

    // MARK: - Read

    /// Reads the UTF-8 string stored for the given key, or `nil` if absent.
    static func read(forKey key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:           kSecClassGenericPassword,
            kSecAttrService:     Bundle.main.bundleIdentifier ?? "com.simplewinemanager",
            kSecAttrAccount:     key,
            kSecReturnData:      true,
            kSecMatchLimit:      kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    // MARK: - Delete

    /// Removes the item stored for the given key.
    /// - Returns: `true` on success or if the item was already absent, `false` on error.
    @discardableResult
    static func delete(forKey key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: Bundle.main.bundleIdentifier ?? "com.simplewinemanager",
            kSecAttrAccount: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
