import Foundation
import Observation
import UIKit

/// 홈에서 가져온 입력이 ScriptConfirm으로 전달할 결과입니다. `text`는 비어 있을 수 있습니다.
struct HomeImportCompletion: Equatable {
    let id = UUID()
    let title: String
    let text: String
}

/// 홈의 사진·카메라·PDF 입력 작업을 소유합니다. picker 표시 같은 UI 상태는 View가 소유합니다.
///
/// - 한 번에 하나의 작업만 유효합니다. 새 선택은 이전 작업을 취소하고 대체하며, 대체되거나
///   화면 이탈로 취소된 작업의 늦은 성공·실패는 반영하지 않습니다.
/// - 결과는 `completion`으로 한 번만 전달합니다. View가 `consumeCompletion()`으로 가져가 navigation합니다.
/// - 글자를 찾지 못한 빈 결과는 실패가 아니며 빈 텍스트로 ScriptConfirm에 진입합니다.
/// - 파일 접근 권한은 `PDFTextExtracting` 호출 안에서 얻고 해제하므로 모델은 접근 수명을 보유하지 않습니다.
@MainActor
@Observable
final class HomeImportModel {
    static let photoLibraryTitle = "사진 보관함에서 가져온 스크립트"
    static let cameraTitle = "새로운 사진"

    private enum Failure: Error {
        case photoLoad
        case recognition
        case pdfExtraction

        var message: String {
            switch self {
            case .photoLoad: "사진을 불러오지 못했습니다. 다시 시도해 주세요."
            case .recognition: "사진에서 텍스트를 인식하지 못했습니다. 다시 시도해 주세요."
            case .pdfExtraction: "PDF 파일에서 텍스트를 추출할 수 없습니다."
            }
        }
    }

    private(set) var isProcessing = false
    private(set) var errorMessage: String?
    private var pendingCompletion: HomeImportCompletion?

    var completion: HomeImportCompletion? { pendingCompletion }

    @ObservationIgnored private var task: Task<Void, Never>?
    private var activeRequestID: UUID?
    private let textRecognizer: any TextRecognizing
    private let pdfExtractor: any PDFTextExtracting

    // 다른 MainActor 모델과 같은 iOS 26.2 deinit 런타임 우회입니다.
    nonisolated deinit {}

    init(textRecognizer: any TextRecognizing, pdfExtractor: any PDFTextExtracting) {
        self.textRecognizer = textRecognizer
        self.pdfExtractor = pdfExtractor
    }

    /// 사진 보관함 선택입니다. `load`는 선택 항목에서 이미지를 불러오며 이 모델의 작업 안에서 실행됩니다.
    func importPhoto(loading load: @escaping () async throws -> UIImage?) {
        let recognizer = textRecognizer
        start(title: Self.photoLibraryTitle) {
            let image: UIImage?
            do {
                image = try await load()
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                throw Failure.photoLoad
            }
            guard let image else { throw Failure.photoLoad }
            return try await Self.recognize(image, with: recognizer)
        }
    }

    func importCameraImage(_ image: UIImage) {
        let recognizer = textRecognizer
        start(title: Self.cameraTitle) {
            try await Self.recognize(image, with: recognizer)
        }
    }

    /// `fileImporter`의 결과를 받습니다. 사용자의 선택 취소는 아무 상태도 바꾸지 않습니다.
    func importPDF(_ selection: Result<URL, any Error>) {
        switch selection {
        case .success(let url):
            let extractor = pdfExtractor
            start(title: url.deletingPathExtension().lastPathComponent) {
                do {
                    return try await extractor.extractText(from: url)
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    throw Failure.pdfExtraction
                }
            }
        case .failure(let error):
            guard (error as? CocoaError)?.code != .userCancelled else { return }
            discardActiveWork()
            errorMessage = "파일을 불러오는 데 실패했습니다: \(error.localizedDescription)"
        }
    }

    /// 화면 이탈이나 라우팅 변경 시 진행 중 작업과 전달 전 결과를 버립니다.
    func cancel() {
        discardActiveWork()
        errorMessage = nil
    }

    func consumeCompletion() -> HomeImportCompletion? {
        defer { pendingCompletion = nil }
        return pendingCompletion
    }

    func dismissError() {
        errorMessage = nil
    }

    private static func recognize(_ image: UIImage, with recognizer: any TextRecognizing) async throws -> String {
        // 이미지 로딩 중 취소되었다면 OCR을 시작하지 않습니다.
        try Task.checkCancellation()
        do {
            return try await recognizer.recognizeText(from: image)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw Failure.recognition
        }
    }

    private func start(title: String, work: @escaping () async throws -> String) {
        discardActiveWork()
        let requestID = UUID()
        activeRequestID = requestID
        isProcessing = true
        errorMessage = nil
        task = Task { [weak self] in
            let outcome: Result<String, any Error>
            do {
                outcome = .success(try await work())
            } catch {
                outcome = .failure(error)
            }
            self?.finish(requestID: requestID, title: title, outcome: outcome)
        }
    }

    private func finish(requestID: UUID, title: String, outcome: Result<String, any Error>) {
        guard activeRequestID == requestID, !Task.isCancelled else { return }
        activeRequestID = nil
        task = nil
        isProcessing = false
        switch outcome {
        case .success(let text):
            pendingCompletion = HomeImportCompletion(title: title, text: text)
        case .failure(let error):
            guard !(error is CancellationError) else { return }
            errorMessage = (error as? Failure)?.message ?? Failure.recognition.message
        }
    }

    private func discardActiveWork() {
        task?.cancel()
        task = nil
        activeRequestID = nil
        isProcessing = false
        pendingCompletion = nil
    }
}
