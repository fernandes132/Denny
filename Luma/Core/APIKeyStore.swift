import Foundation
import Security

enum APIKeyStore {
    private static var service: String { (Bundle.main.bundleIdentifier ?? "nl.luma.pilot") + ".youtube" }

    static func read() -> String {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service, kSecAttrAccount as String: "api-key",
            kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var value: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &value) == errSecSuccess,
              let data = value as? Data else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    static func write(_ input: String) throws {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service, kSecAttrAccount as String: "api-key"]
        guard !value.isEmpty else {
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else { throw KeyError.delete }
            return
        }
        let attributes: [String: Any] = [kSecValueData as String: Data(value.utf8)]
        let result = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if result == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = Data(value.utf8)
            item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw KeyError.save }
        } else if result != errSecSuccess { throw KeyError.save }
    }

    enum KeyError: LocalizedError {
        case save, delete
        var errorDescription: String? {
            switch self {
            case .save: return "De sleutel kon niet veilig worden opgeslagen."
            case .delete: return "De sleutel kon niet worden verwijderd. Ontgrendel je iPhone en probeer opnieuw."
            }
        }
    }
}
