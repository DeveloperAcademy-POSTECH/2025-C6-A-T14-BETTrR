import Vision
import UIKit

struct TextRecognitionService: TextRecognizing {
    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            AppLog.document.error("이미지 변환 실패")
            throw DocumentImportError.unreadableInput
        }

        do {
            return try await Task.detached(priority: .userInitiated) {
                try Self.recognize(cgImage)
            }.value
        } catch {
            AppLog.document.error("텍스트 인식 실패")
            throw DocumentImportError.recognitionFailed
        }
    }

    /// 메인 스레드를 막지 않도록 백그라운드에서 동기 Vision 요청을 수행합니다.
    private nonisolated static func recognize(_ cgImage: CGImage) throws -> String {
        let request = VNRecognizeTextRequest()
        try VNImageRequestHandler(cgImage: cgImage).perform([request])
        let observations = request.results ?? []
        return observations
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }
}
