
import Foundation
import GRDB
import NaturalLanguage

enum WordExtractionError: LocalizedError {
    case scriptNotFound
    case deviceNotSupported
    case extractionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .scriptNotFound:
            return "스크립트를 찾을 수 없습니다."
        case .deviceNotSupported:
            return "Apple Intelligence가 활성화된 지원 기기에서만 실행 가능합니다."
        case .extractionFailed(let message):
            return "단어 추출 실패: \(message)"
        }
    }
}
