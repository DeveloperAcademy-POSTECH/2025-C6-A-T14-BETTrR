//
//  LocalRateLimiter.swift
//  Bettr
//
//  Created by 서세린 on 11/11/25.
//

import Foundation

/// 로컬 호출 제한 유틸리티
/// - 1분(60초) 동안 3회 초과 호출 시 차단
/// - 기기 단위에서만 동작 (서버와 무관)
final class LocalRateLimiter {
    static let shared = LocalRateLimiter()
    
    private let uuid: String

    private var timestamps: [String: [Date]] = [:]
    private let limit = 3           // 1분에 3번까지 허용
    private let window: TimeInterval = 60 // 60초
    
    init(uuid: String = DeviceUUIDProvider.shared.uuid) {
        self.uuid = uuid
    }
    
    /// 호출 가능 여부를 반환
    func canCall(at now: Date = Date()) -> Bool {
        timestamps[uuid, default: []] = timestamps[uuid, default: []].filter {
            now.timeIntervalSince($0) < window
        }
        
        if timestamps[uuid]!.count >= limit {
            return false
        }
        
        timestamps[uuid]?.append(now)
        return true
    }
    
    /// 테스트나 강제 초기화용
    func reset() {
        timestamps.removeAll()
    }
}
