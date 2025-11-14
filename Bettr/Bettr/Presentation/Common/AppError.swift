//
//  AppError.swift
//  Bettr
//
//  Created by 길정수 on 11/13/25.
//

import Foundation

// 뷰모델이 View에 전달할 '구조화된 에러'
enum AppError: Error, Equatable {
    case networkError(String)     // 1. 네트워크 (재시도 가능)
    case dataNotFound(String)             // 2. 데이터 없음 (재시도 불가)
    case apiError(String)         // 3. API/서버 (재시도 가능)
    case permissionDenied(type: String) // 4. 권한 (설정으로 이동)
    case unknown(String)          // 5. 기타 (재시도 가능)
    
    // 이 에러가 "재시도" 버튼을 보여줘야 하는지 스스로 판단
    var isRetryable: Bool {
        switch self {
        case .networkError, .apiError, .unknown:
            return true
        case .dataNotFound, .permissionDenied:
            return false
        }
    }
    
    // 사용자에게 보여줄 메시지
    var userFriendlyMessage: String {
        switch self {
        case .networkError(let message):
            return "일시적인 오류가 발생했습니다.\n\(message)"
        case .dataNotFound(let message):
            return message
        case .apiError(let message):
            return "일시적인 오류가 발생했습니다.\n\(message)"
        case .permissionDenied(let type):
            return "\(type) 권한이 필요합니다.\n설정에서 허용해 주세요."
        case .unknown(let message):
            return "알 수 없는 오류가 발생했습니다.\n\(message)"
        }
    }
}
