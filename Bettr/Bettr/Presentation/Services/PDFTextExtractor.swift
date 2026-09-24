
import Foundation
import PDFKit

struct PDFTextExtractor {
    func extractText(from url: URL) -> String? {
        // URL에 대한 접근 권한을 얻기 위해 security-scoped access를 시작합니다.
        guard url.startAccessingSecurityScopedResource() else {
            AppLog.document.error("PDF 리소스 접근 실패")
            return nil
        }
        
        defer {
            // 작업이 끝나면 접근 권한을 해제합니다.
            url.stopAccessingSecurityScopedResource()
        }
        
        guard let pdfDocument = PDFDocument(url: url) else {
            AppLog.document.error("PDF 문서 불러오기 실패")
            return nil
        }
        
        var fullText = ""
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i),
               let pageContent = page.string {
                fullText.append(pageContent)
                fullText.append("\n\n") // 페이지 사이에 공백 추가
            }
        }
        
        return fullText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
