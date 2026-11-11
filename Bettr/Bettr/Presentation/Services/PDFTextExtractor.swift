import Foundation
import PDFKit

struct PDFTextExtractor: PDFTextExtracting {
    func extractText(from url: URL) async throws -> String {
        try Task.checkCancellation()
        do {
            return try await Task.detached(priority: .userInitiated) {
                try Self.extract(from: url)
            }.value
        } catch let error as DocumentImportError {
            switch error {
            case .resourceUnavailable: AppLog.document.error("PDF 리소스 접근 실패")
            default: AppLog.document.error("PDF 문서 불러오기 실패")
            }
            throw error
        }
    }

    /// 접근 권한은 이 동기 구간 안에서만 유지되며 취소나 오류와 무관하게 `defer`로 해제됩니다.
    private nonisolated static func extract(from url: URL) throws -> String {
        guard url.startAccessingSecurityScopedResource() else {
            throw DocumentImportError.resourceUnavailable
        }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let pdfDocument = PDFDocument(url: url) else {
            throw DocumentImportError.unreadableInput
        }

        var fullText = ""
        for i in 0..<pdfDocument.pageCount {
            if let pageContent = pdfDocument.page(at: i)?.string {
                fullText.append(pageContent)
                fullText.append("\n\n") // 페이지 사이에 공백 추가
            }
        }
        return fullText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
