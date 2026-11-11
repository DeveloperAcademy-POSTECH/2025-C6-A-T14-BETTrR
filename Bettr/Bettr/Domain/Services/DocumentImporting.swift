import Foundation
import UIKit

/// 문서 입력 실패의 종류입니다. 빈 텍스트는 실패가 아니라 성공 결과(`""`)로 구분합니다.
enum DocumentImportError: Error, Equatable {
    /// 파일 접근 권한을 얻지 못했습니다.
    case resourceUnavailable
    /// 문서나 이미지를 열 수 없습니다.
    case unreadableInput
    /// OCR 처리에 실패했습니다.
    case recognitionFailed
}

@MainActor
protocol TextRecognizing {
    /// 인식된 텍스트를 반환합니다. 글자가 없으면 빈 문자열이며 실패는 `DocumentImportError`로 던집니다.
    func recognizeText(from image: UIImage) async throws -> String
}

@MainActor
protocol PDFTextExtracting {
    /// PDF 텍스트를 반환합니다. 텍스트가 없으면 빈 문자열이며 실패는 `DocumentImportError`로 던집니다.
    /// 파일 접근 권한은 호출 안에서 얻고 반환 전에 해제합니다.
    func extractText(from url: URL) async throws -> String
}
