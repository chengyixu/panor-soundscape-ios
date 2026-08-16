import Foundation
import Security

actor KeychainTokenStore: AuthTokenStore {
    static let defaultService = "tech.panor.soundscape"

    private let service: String
    private let account: String

    init(service: String = KeychainTokenStore.defaultService, account: String = "panorama_token") {
        self.service = service
        self.account = account
    }

    func token() async throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw AppError.secureStorageUnavailable(status: status)
        }
        return token
    }

    func setToken(_ token: String) async throws {
        guard let data = token.data(using: .utf8) else {
            throw AppError.invalidRequest(loc(.errorKeychainFailed))
        }
        let attributes = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var query = baseQuery
            query[kSecValueData as String] = data
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw AppError.secureStorageUnavailable(status: addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw AppError.secureStorageUnavailable(status: updateStatus)
        }
    }

    func clear() async throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AppError.secureStorageUnavailable(status: status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
    }
}
