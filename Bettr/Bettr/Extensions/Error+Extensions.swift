//
//  Error+Extensions.swift
//  Bettr
//
//  Created by 길정수 on 11/14/25.
//

import Foundation

extension Error {
    
    /// 발생한 Error를 뷰모델/뷰에서 사용하기 적합한 AppError로 변환
    func toAppError() -> AppError {
        if let repoError = self as? ScriptRepositoryError {
            switch repoError {
            case .notFound(let message):
                // 404 에러 -> 재시도 불가능 (.dataNotFound)
                return .dataNotFound(message)
                
            case .databaseError(let message):
                // DB 오류 -> 일시적일 수 있음, 재시도 가능 (.apiError)
                return .apiError("데이터베이스 오류: \(message)")
                
            case .validationError(let message):
                // 유효성 검사 오류 -> 재시도 불가능 (.dataNotFound)
                return .dataNotFound("데이터 처리 오류: \(message)")
            }
        }
        return .networkError(self.localizedDescription)
    }
}
