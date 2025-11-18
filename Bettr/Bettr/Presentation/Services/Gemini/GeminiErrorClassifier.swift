//
//  GeminiErrorClassifier.swift
//  Bettr
//
//  Created by 서세린 on 11/5/25.
//

import SwiftUI


// MARK: - 에러 분류기 (FirebaseAI / Vertex 기준)
enum GeminiErrorCategory {
    case clientInput    // 400~422 → 입력 오류
    case transient      // 408, 500, 502, 503, timeout → 서버 불안정
    case auth           // 인증오류
    case rateLimited    // 무료 버전 분당 호출 제한.
    case jsonParsing    // ✅ [추가] JSON 파싱 실패
    case unknown
}

func classifyGeminiCallError(_ error: Error) -> GeminiErrorCategory {
    let nsError = error as NSError
    let code = nsError.code
    let domain = nsError.domain
    
    // ✅ [개선] 에러 메시지를 소문자로 변환하여 검사
    let msg = error.localizedDescription.lowercased()
    
    // ✅ [추가] URLError 타입별 분류 (JSON 파싱, 빈 응답 등)
    if let urlError = error as? URLError {
        switch urlError.code {
        case .cannotParseResponse:
            return .jsonParsing
        case .timedOut, .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet:
            return .transient
        default:
            break
        }
    }
    
    // ✅ [개선] Firebase/Vertex 표준 gRPC 상태 코드 검사 (대소문자 무관)
    if msg.contains("invalid_argument") || msg.contains("invalid argument") {
        return .clientInput
    }
    if msg.contains("failed_precondition") || msg.contains("failed precondition") {
        return .clientInput
    }
    if msg.contains("permission_denied") || msg.contains("permission denied") {
        return .auth
    }
    if msg.contains("unauthenticated") {
        return .auth
    }
    if msg.contains("not_found") || msg.contains("not found") {
        return .clientInput
    }
    if msg.contains("resource_exhausted") || msg.contains("resource exhausted") || msg.contains("quota") {
        return .rateLimited
    }
    if msg.contains("unavailable") || msg.contains("deadline_exceeded") || msg.contains("deadline exceeded") {
        return .transient
    }
    if msg.contains("cancelled") {
        return .transient
    }
    
    // ✅ [개선] HTTP 상태 코드 기반 분류 (더 세밀하게)
    if (400...403).contains(code) { return .clientInput }
    if code == 404 { return .clientInput }
    if code == 413 || code == 414 { return .clientInput } // Payload Too Large
    if code == 429 { return .rateLimited }
    if code == 408 { return .transient } // Request Timeout
    if (500...504).contains(code) { return .transient }
    
    // ✅ [개선] Firebase SDK 특정 도메인 검사
    if domain.contains("FIRGenerativeAI") || domain.contains("Firebase") {
        // ✅ [추가] Firebase 에러 코드 범위별 분류
        if (1...99).contains(code) { return .clientInput }
        if (100...199).contains(code) { return .auth }
        if code == 429 { return .rateLimited }
        if (500...599).contains(code) { return .transient }
    }
    
    // ✅ [개선] 메시지 내용 기반 추가 분류
    if msg.contains("timeout") || msg.contains("timed out") {
        return .transient
    }
    if msg.contains("network") || msg.contains("connection") {
        return .transient
    }
    if msg.contains("too large") || msg.contains("too long") {
        return .clientInput
    }
    if msg.contains("rate") || msg.contains("limit") {
        return .rateLimited
    }
    if msg.contains("invalid") || msg.contains("malformed") {
        return .clientInput
    }
    
    // ✅ [개선] 마지막 resort로 unknown 반환 (이제 재시도 로직 포함)
    return .unknown
}

