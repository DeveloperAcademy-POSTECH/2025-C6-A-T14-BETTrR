//
//  DeviceUUIDProvider.swift
//  Bettr
//
//  Created by 서세린 on 11/11/25.
//

import Foundation
import Security

/// 기기별 고유 UUID를 안전하게 관리 (Keychain 기반)
final class DeviceUUIDProvider {
    static let shared = DeviceUUIDProvider()
    private let keychainKey = "com.bettr.deviceUUID"
    
    private(set) var uuid: String
    
    private init() {
        // 이미 저장된 UUID가 있으면 가져오고, 없으면 새로 생성
        if let existing = Self.loadFromKeychain(forKey: keychainKey) {
            uuid = existing
        } else {
            uuid = UUID().uuidString
            Self.saveToKeychain(uuid, forKey: keychainKey)
        }
    }
    
    private static func loadFromKeychain(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &item) == noErr,
           let data = item as? Data,
           let result = String(data: data, encoding: .utf8) {
            return result
        }
        return nil
    }
    
    private static func saveToKeychain(_ value: String, forKey key: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
}
