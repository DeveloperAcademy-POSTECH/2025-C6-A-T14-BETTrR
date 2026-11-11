import Foundation
import UIKit
import XCTest
@testable import Bettr

@MainActor
final class HomeImportModelTests: XCTestCase {
    private let pdfURL = URL(fileURLWithPath: "/tmp/발표 대본.pdf")

    // MARK: - 성공

    func test_importPhoto_whenRecognitionSucceeds_thenCompletesOnceWithLibraryTitle() async {
        let (model, ocr, _) = makeModel()

        model.importPhoto { UIImage() }
        XCTAssertTrue(model.isProcessing)
        XCTAssertNil(model.completion)
        await ocr.waitForCall(1)
        ocr.complete(1, with: "Hello")
        await settle(model)

        XCTAssertFalse(model.isProcessing)
        XCTAssertEqual(model.completion?.title, HomeImportModel.photoLibraryTitle)
        XCTAssertEqual(model.completion?.text, "Hello")
        XCTAssertNotNil(model.consumeCompletion())
        XCTAssertNil(model.consumeCompletion())
        XCTAssertNil(model.completion)
    }

    func test_importCameraImage_whenRecognitionSucceeds_thenCompletesWithCameraTitle() async {
        let (model, ocr, _) = makeModel()

        model.importCameraImage(UIImage())
        await ocr.waitForCall(1)
        ocr.complete(1, with: "Camera text")
        await settle(model)

        XCTAssertEqual(model.completion?.title, HomeImportModel.cameraTitle)
        XCTAssertEqual(model.completion?.text, "Camera text")
    }

    func test_importPDF_whenExtractionSucceeds_thenCompletesWithFileNameTitle() async {
        let (model, _, pdf) = makeModel()

        model.importPDF(.success(pdfURL))
        await pdf.waitForCall(1)
        pdf.complete(1, with: "PDF text")
        await settle(model)

        XCTAssertEqual(model.completion?.title, "발표 대본")
        XCTAssertEqual(model.completion?.text, "PDF text")
        XCTAssertNil(model.errorMessage)
    }

    // MARK: - 빈 결과

    func test_importPhoto_whenNoTextFound_thenStillCompletesWithEmptyText() async {
        let (model, ocr, _) = makeModel()

        model.importPhoto { UIImage() }
        await ocr.waitForCall(1)
        ocr.complete(1, with: "")
        await settle(model)

        XCTAssertEqual(model.completion?.text, "")
        XCTAssertNil(model.errorMessage)
    }

    func test_importPDF_whenNoTextFound_thenStillCompletesWithEmptyText() async {
        let (model, _, pdf) = makeModel()

        model.importPDF(.success(pdfURL))
        await pdf.waitForCall(1)
        pdf.complete(1, with: "")
        await settle(model)

        XCTAssertEqual(model.completion?.text, "")
        XCTAssertNil(model.errorMessage)
    }

    // MARK: - 실패

    func test_importPhoto_whenRecognitionFails_thenShowsErrorWithoutCompletion() async {
        let (model, ocr, _) = makeModel()

        model.importPhoto { UIImage() }
        await ocr.waitForCall(1)
        ocr.fail(1, with: DocumentImportError.recognitionFailed)
        await settle(model)

        XCTAssertNotNil(model.errorMessage)
        XCTAssertNil(model.completion)
        XCTAssertFalse(model.isProcessing)
    }

    func test_importPhoto_whenImageCannotBeLoaded_thenShowsErrorAndSkipsRecognition() async {
        let (model, ocr, _) = makeModel()

        model.importPhoto { nil }
        await settle(model)
        XCTAssertNotNil(model.errorMessage)

        model.dismissError()
        model.importPhoto { throw CocoaError(.fileReadUnknown) }
        await settle(model)

        XCTAssertNotNil(model.errorMessage)
        XCTAssertNil(model.completion)
        XCTAssertEqual(ocr.callCount, 0)
    }

    func test_importPDF_whenExtractionFails_thenShowsErrorWithoutCompletion() async {
        let (model, _, pdf) = makeModel()

        model.importPDF(.success(pdfURL))
        await pdf.waitForCall(1)
        pdf.fail(1, with: DocumentImportError.resourceUnavailable)
        await settle(model)

        XCTAssertNotNil(model.errorMessage)
        XCTAssertNil(model.completion)
        XCTAssertFalse(model.isProcessing)
    }

    func test_importPDF_whenSelectionFails_thenShowsErrorWithoutExtracting() {
        let (model, _, pdf) = makeModel()

        model.importPDF(.failure(CocoaError(.fileReadNoPermission)))

        XCTAssertNotNil(model.errorMessage)
        XCTAssertNil(model.completion)
        XCTAssertEqual(pdf.callCount, 0)
    }

    func test_importPhoto_whenPreviousErrorExists_thenNewSelectionClearsIt() async {
        let (model, ocr, _) = makeModel()
        model.importPDF(.failure(CocoaError(.fileReadNoPermission)))
        XCTAssertNotNil(model.errorMessage)

        model.importPhoto { UIImage() }
        XCTAssertNil(model.errorMessage)
        await ocr.waitForCall(1)
        ocr.complete(1, with: "ok")
        await settle(model)

        XCTAssertNotNil(model.completion)
    }

    // MARK: - 선택 취소

    func test_importPDF_whenUserCancelsPicker_thenChangesNothing() {
        let (model, _, pdf) = makeModel()

        model.importPDF(.failure(CocoaError(.userCancelled)))

        XCTAssertNil(model.errorMessage)
        XCTAssertNil(model.completion)
        XCTAssertFalse(model.isProcessing)
        XCTAssertEqual(pdf.callCount, 0)
    }

    func test_importPDF_whenUserCancelsPickerDuringImport_thenImportStillCompletes() async {
        let (model, ocr, _) = makeModel()
        model.importPhoto { UIImage() }
        await ocr.waitForCall(1)

        model.importPDF(.failure(CocoaError(.userCancelled)))
        XCTAssertTrue(model.isProcessing)
        ocr.complete(1, with: "still here")
        await settle(model)

        XCTAssertEqual(model.completion?.text, "still here")
    }

    // MARK: - 중복 선택과 늦은 완료

    func test_import_whenOlderCompletesAfterNewerSelection_thenNewerResultIsKept() async {
        let (model, ocr, pdf) = makeModel()
        model.importPDF(.success(pdfURL))
        await pdf.waitForCall(1)
        model.importPhoto { UIImage() }
        await ocr.waitForCall(1)

        ocr.complete(1, with: "newer")
        await settle(model)
        pdf.complete(1, with: "older")
        await settleLateWork()

        XCTAssertEqual(model.completion?.text, "newer")
        XCTAssertEqual(model.completion?.title, HomeImportModel.photoLibraryTitle)
        XCTAssertNotNil(model.consumeCompletion())
        XCTAssertNil(model.consumeCompletion(), "늦은 완료가 두 번째 navigation을 만들면 안 됩니다")
        XCTAssertEqual(pdf.cancelledOnResume(1), true)
    }

    func test_import_whenReplacedImportFailsLate_thenNewerStateIsUnaffected() async {
        let (model, ocr, pdf) = makeModel()
        model.importPDF(.success(pdfURL))
        await pdf.waitForCall(1)
        model.importPhoto { UIImage() }
        await ocr.waitForCall(1)

        pdf.fail(1, with: DocumentImportError.unreadableInput)
        await settleLateWork()
        XCTAssertNil(model.errorMessage, "대체된 작업의 실패가 새 작업 상태를 바꾸면 안 됩니다")
        XCTAssertTrue(model.isProcessing)

        ocr.complete(1, with: "newer")
        await settle(model)
        XCTAssertEqual(model.completion?.text, "newer")
    }

    func test_import_whenNewSelectionStartsBeforeCompletionIsConsumed_thenDiscardsStaleCompletion() async {
        let (model, ocr, pdf) = makeModel()
        model.importPDF(.success(pdfURL))
        await pdf.waitForCall(1)
        pdf.complete(1, with: "first")
        await settle(model)
        XCTAssertEqual(model.completion?.text, "first")

        model.importPhoto { UIImage() }
        XCTAssertNil(model.completion)
        await ocr.waitForCall(1)
        ocr.complete(1, with: "second")
        await settle(model)

        XCTAssertEqual(model.consumeCompletion()?.text, "second")
        XCTAssertNil(model.consumeCompletion())
    }

    func test_import_whenSameContentIsImportedTwice_thenCompletionsAreDistinct() async {
        let (model, ocr, _) = makeModel()
        model.importPhoto { UIImage() }
        await ocr.waitForCall(1)
        ocr.complete(1, with: "same")
        await settle(model)
        let first = model.consumeCompletion()

        model.importPhoto { UIImage() }
        await ocr.waitForCall(2)
        ocr.complete(2, with: "same")
        await settle(model)
        let second = model.consumeCompletion()

        XCTAssertNotNil(first)
        XCTAssertNotNil(second)
        XCTAssertNotEqual(first, second, "onChange가 같은 내용의 두 번째 결과도 감지해야 합니다")
    }

    // MARK: - 화면 이탈

    func test_cancel_whenImportIsInFlight_thenCancelsWorkAndIgnoresLateSuccess() async {
        let (model, _, pdf) = makeModel()
        model.importPDF(.success(pdfURL))
        await pdf.waitForCall(1)

        model.cancel()
        XCTAssertFalse(model.isProcessing)
        pdf.complete(1, with: "late")
        await settleLateWork()

        XCTAssertNil(model.completion)
        XCTAssertNil(model.errorMessage)
        XCTAssertFalse(model.isProcessing)
        XCTAssertEqual(pdf.cancelledOnResume(1), true, "화면 이탈은 추출 작업에 취소를 전파해야 합니다")
    }

    func test_cancel_whenImportIsInFlight_thenIgnoresLateFailure() async {
        let (model, ocr, _) = makeModel()
        model.importCameraImage(UIImage())
        await ocr.waitForCall(1)

        model.cancel()
        ocr.fail(1, with: DocumentImportError.recognitionFailed)
        await settleLateWork()

        XCTAssertNil(model.errorMessage)
        XCTAssertNil(model.completion)
    }

    func test_cancel_whenCompletionIsPending_thenDiscardsIt() async {
        let (model, ocr, _) = makeModel()
        model.importCameraImage(UIImage())
        await ocr.waitForCall(1)
        ocr.complete(1, with: "text")
        await settle(model)
        XCTAssertNotNil(model.completion)

        model.cancel()

        XCTAssertNil(model.completion)
        XCTAssertNil(model.consumeCompletion())
    }

    func test_cancel_whenPhotoIsStillLoading_thenCancelsLoaderAndSkipsRecognition() async {
        let (model, ocr, _) = makeModel()
        let loader = ControlledImageLoader()
        model.importPhoto { try await loader.load() }
        await loader.waitForLoad()

        model.cancel()
        loader.finish()
        await settleLateWork()

        XCTAssertEqual(ocr.callCount, 0)
        XCTAssertNil(model.completion)
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(loader.cancelledOnResume, true)
    }

    // MARK: - Helpers

    private func makeModel() -> (HomeImportModel, ControlledTextRecognizer, ControlledPDFExtractor) {
        let ocr = ControlledTextRecognizer()
        let pdf = ControlledPDFExtractor()
        return (HomeImportModel(textRecognizer: ocr, pdfExtractor: pdf), ocr, pdf)
    }

    /// 모델의 현재 작업이 끝날 때까지 양보합니다.
    private func settle(_ model: HomeImportModel) async {
        for _ in 0..<200 where model.isProcessing {
            await Task.yield()
        }
    }

    /// 대체·취소된 작업의 재개가 상태를 바꾸지 못하는지 확인하도록 충분히 양보합니다.
    private func settleLateWork() async {
        for _ in 0..<50 { await Task.yield() }
    }
}

// MARK: - PDF 추출기 취소

@MainActor
final class PDFTextExtractorCancellationTests: XCTestCase {
    func test_extractText_whenCancelledBeforeStart_thenThrowsCancellationWithoutAccessingFile() async {
        let extractor = PDFTextExtractor()
        let missing = URL(fileURLWithPath: "/tmp/bettr-missing-\(UUID().uuidString).pdf")

        let task = Task { try await extractor.extractText(from: missing) }
        task.cancel()
        let result = await task.result

        guard case .failure(let error) = result else { return XCTFail("취소된 추출은 실패해야 합니다") }
        XCTAssertTrue(error is CancellationError, "접근 권한 요청 전에 취소되어야 합니다: \(error)")
    }
}

@MainActor
final class TextRecognitionServiceCancellationTests: XCTestCase {
    func test_recognizeText_whenCancelledBeforeStart_thenThrowsCancellationNotRecognitionFailure() async {
        let service = TextRecognitionService()
        let image = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { _ in }

        let task = Task { try await service.recognizeText(from: image) }
        task.cancel()
        let result = await task.result

        guard case .failure(let error) = result else { return XCTFail("취소된 인식은 실패해야 합니다") }
        XCTAssertTrue(error is CancellationError, "취소가 인식 실패로 바뀌면 안 됩니다: \(error)")
    }
}

// MARK: - Fakes

/// 호출마다 완료 시점을 테스트가 정하는 보류형 호출 목록입니다.
@MainActor
private final class ControlledCalls {
    private(set) var callCount = 0
    private var continuations: [Int: CheckedContinuation<String, Error>] = [:]
    private var waiters: [Int: CheckedContinuation<Void, Never>] = [:]
    private var resumedWhileCancelled: [Int: Bool] = [:]

    func begin() async throws -> String {
        callCount += 1
        let number = callCount
        defer { resumedWhileCancelled[number] = Task.isCancelled }
        return try await withCheckedThrowingContinuation { continuation in
            continuations[number] = continuation
            waiters.removeValue(forKey: number)?.resume()
        }
    }

    func waitForCall(_ number: Int) async {
        if continuations[number] != nil { return }
        await withCheckedContinuation { waiters[number] = $0 }
    }

    func complete(_ number: Int, with text: String) {
        continuations.removeValue(forKey: number)?.resume(returning: text)
    }

    func fail(_ number: Int, with error: Error) {
        continuations.removeValue(forKey: number)?.resume(throwing: error)
    }

    func cancelledOnResume(_ number: Int) -> Bool? { resumedWhileCancelled[number] }
}

@MainActor
private final class ControlledTextRecognizer: TextRecognizing {
    private let calls = ControlledCalls()
    var callCount: Int { calls.callCount }

    func recognizeText(from image: UIImage) async throws -> String { try await calls.begin() }
    func waitForCall(_ number: Int) async { await calls.waitForCall(number) }
    func complete(_ number: Int, with text: String) { calls.complete(number, with: text) }
    func fail(_ number: Int, with error: Error) { calls.fail(number, with: error) }
}

@MainActor
private final class ControlledPDFExtractor: PDFTextExtracting {
    private let calls = ControlledCalls()
    var callCount: Int { calls.callCount }

    func extractText(from url: URL) async throws -> String { try await calls.begin() }
    func waitForCall(_ number: Int) async { await calls.waitForCall(number) }
    func complete(_ number: Int, with text: String) { calls.complete(number, with: text) }
    func fail(_ number: Int, with error: Error) { calls.fail(number, with: error) }
    func cancelledOnResume(_ number: Int) -> Bool? { calls.cancelledOnResume(number) }
}

@MainActor
private final class ControlledImageLoader {
    private var continuation: CheckedContinuation<UIImage?, Error>?
    private var waiter: CheckedContinuation<Void, Never>?
    private(set) var cancelledOnResume: Bool?

    func load() async throws -> UIImage? {
        defer { cancelledOnResume = Task.isCancelled }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            waiter?.resume()
            waiter = nil
        }
    }

    func waitForLoad() async {
        if continuation != nil { return }
        await withCheckedContinuation { waiter = $0 }
    }

    func finish() {
        continuation?.resume(returning: UIImage())
        continuation = nil
    }
}
