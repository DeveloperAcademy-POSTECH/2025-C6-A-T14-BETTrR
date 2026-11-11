import Vision
import UIKit

struct TextRecognitionService: TextRecognizing {
    func recognizeText(from image: UIImage) async throws -> String {
        try Task.checkCancellation()
        guard let cgImage = image.cgImage else {
            AppLog.document.error("이미지 변환 실패")
            throw DocumentImportError.unreadableInput
        }

        // detached 작업은 취소를 상속하지 않으므로 핸들러로 직접 전달합니다.
        let work = Task.detached(priority: .userInitiated) {
            try Self.recognize(cgImage)
        }
        do {
            return try await withTaskCancellationHandler {
                try await work.value
            } onCancel: {
                work.cancel()
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            AppLog.document.error("텍스트 인식 실패")
            throw DocumentImportError.recognitionFailed
        }
    }

    /// 메인 스레드를 막지 않도록 백그라운드에서 동기 Vision 요청을 수행합니다.
    /// Vision 요청은 호출 한 번이라 시작 전에만 취소를 확인합니다.
    private nonisolated static func recognize(_ cgImage: CGImage) throws -> String {
        try Task.checkCancellation()
        let request = VNRecognizeTextRequest()
        try VNImageRequestHandler(cgImage: cgImage).perform([request])
        let observations = request.results ?? []
        return observations
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }
}
