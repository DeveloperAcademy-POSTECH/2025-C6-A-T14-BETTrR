import XCTest
@testable import Bettr

@MainActor
final class RecordingViewModelTests: XCTestCase {
    // MARK: - 정상 흐름

    func test_successfulRecordingEvaluatesSavesAndCompletesOnce() async throws {
        let f = Fixture()
        f.model.toggleRecording()

        XCTAssertEqual(f.model.phase, .recording)
        XCTAssertTrue(f.model.isRecording)
        XCTAssertEqual(f.capture.beginCount, 1)
        XCTAssertEqual(f.permissions.requestCount, 0)

        await flush()
        await f.clock.advance(by: .milliseconds(1500))
        XCTAssertEqual(f.model.elapsedTime, 1.5, accuracy: 1e-9)
        f.capture.emit(.partial("hello"))
        XCTAssertEqual(f.model.transcript, "hello")

        f.model.toggleRecording()
        XCTAssertEqual(f.model.phase, .finishing)
        XCTAssertEqual(f.capture.endAudioCount, 1)
        XCTAssertFalse(f.model.isRecording)
        await f.clock.advance(by: .seconds(5))
        XCTAssertEqual(f.model.elapsedTime, 1.5, accuracy: 1e-9, "종료 뒤에는 시간이 흐르지 않습니다")

        f.capture.emit(.ended("Hello world. Nice day."))
        XCTAssertEqual(f.model.phase, .resultReady)
        XCTAssertEqual(f.model.transcript, "Hello world. Nice day.")
        XCTAssertEqual(f.capture.releaseCount, 1)
        XCTAssertTrue(f.model.canSave)
        XCTAssertTrue(f.model.hasRecorded)

        f.model.saveFeedback()
        XCTAssertEqual(f.model.phase, .saving)
        XCTAssertTrue(f.model.isLoading)
        await flush()
        let save = try XCTUnwrap(f.storage.saves.first)
        XCTAssertEqual(save.scriptId, 9)
        XCTAssertEqual(save.accuracy, 1.0, accuracy: 1e-9)
        XCTAssertEqual(save.practiceDuration, 1.5, accuracy: 1e-9)
        XCTAssertEqual(save.detailCount, 4)

        f.model.saveFeedback()
        f.model.cancelRecording()
        XCTAssertEqual(f.model.phase, .saving, "저장 중 중복 저장·취소는 무시합니다")

        f.storage.succeed(0, id: 77)
        await flush()
        XCTAssertEqual(f.model.phase, .completed)
        XCTAssertEqual(f.model.completion, RecordingCompletion(summaryID: 77))
        XCTAssertEqual(f.model.consumeCompletion(), RecordingCompletion(summaryID: 77))
        XCTAssertNil(f.model.consumeCompletion())

        f.model.saveFeedback()
        await flush()
        XCTAssertEqual(f.storage.saves.count, 1)
    }

    func test_creatingViewModelHasNoDeviceOrPermissionSideEffects() async {
        let f = Fixture(permission: .notDetermined)
        await flush()

        XCTAssertEqual(f.model.phase, .idle)
        XCTAssertEqual(f.permissions.requestCount, 0)
        XCTAssertEqual(f.capture.beginCount, 0)
        XCTAssertEqual(f.capture.releaseCount, 0)
        XCTAssertEqual(f.clock.pendingSleepCount, 0)
    }

    func test_timerUsesTheInjectedClock() async {
        let f = Fixture()
        f.model.toggleRecording()
        await flush()

        XCTAssertEqual(f.clock.deadlines.first, f.clock.origin.advanced(by: .milliseconds(10)))
        await f.clock.advance(by: .milliseconds(10))
        XCTAssertEqual(f.model.elapsedTime, 0.01, accuracy: 1e-9)
    }

    // MARK: - 권한

    func test_firstStartRequestsPermissionExplicitlyThenRecords() async {
        let f = Fixture(permission: .notDetermined)
        f.model.toggleRecording()
        XCTAssertEqual(f.model.phase, .requestingPermission)
        await flush()
        XCTAssertEqual(f.permissions.requestCount, 1)

        f.model.toggleRecording()
        f.model.toggleRecording()
        await flush()
        XCTAssertEqual(f.permissions.requestCount, 1, "요청 중 중복 시작은 무시합니다")

        f.permissions.resolve(.authorized)
        await flush()
        XCTAssertEqual(f.model.phase, .recording)
        XCTAssertEqual(f.capture.beginCount, 1)
    }

    func test_deniedPermissionShowsAlertWithoutTouchingDevices() async {
        let f = Fixture(permission: .denied)
        f.model.toggleRecording()

        XCTAssertEqual(f.model.phase, .failed(.permissionDenied))
        XCTAssertEqual(f.model.failure, .permissionDenied)
        XCTAssertEqual(f.capture.beginCount, 0)
        XCTAssertTrue(f.model.isReadyToRecord)

        f.model.dismissFailure()
        XCTAssertEqual(f.model.phase, .idle)
    }

    func test_permissionDeniedByPromptFailsAndCanBeRetried() async {
        let f = Fixture(permission: .notDetermined)
        f.model.toggleRecording()
        await flush()
        f.permissions.resolve(.denied)
        await flush()

        XCTAssertEqual(f.model.failure, .permissionDenied)
        XCTAssertEqual(f.capture.beginCount, 0)
        f.model.dismissFailure()
        f.model.toggleRecording()
        XCTAssertEqual(f.model.failure, .permissionDenied, "거부 상태에서는 다시 요청 없이 안내합니다")
        XCTAssertEqual(f.permissions.requestCount, 1)
    }

    func test_leavingWhileRequestingPermissionNeverStartsRecording() async {
        let f = Fixture(permission: .notDetermined)
        f.model.toggleRecording()
        await flush()
        f.model.leave()
        f.permissions.resolve(.authorized)
        await flush()

        XCTAssertEqual(f.model.phase, .idle)
        XCTAssertEqual(f.capture.beginCount, 0)
    }

    func test_captureStartFailureReleasesDevicesAndAllowsRetry() async {
        let f = Fixture()
        f.capture.beginError = RecordingCaptureError()
        f.model.toggleRecording()

        XCTAssertEqual(f.model.phase, .failed(.captureUnavailable))
        XCTAssertNotNil(f.model.errorMessage)
        XCTAssertEqual(f.capture.releaseCount, 1)
        XCTAssertEqual(f.clock.pendingSleepCount, 0)

        f.model.dismissFailure()
        f.capture.beginError = nil
        f.model.toggleRecording()
        XCTAssertEqual(f.model.phase, .recording)
    }

    // MARK: - 인식 결과

    func test_emptyRecognitionFailsEvaluationWithoutSaving() async {
        let f = Fixture()
        f.model.toggleRecording()
        f.model.toggleRecording()
        f.capture.emit(.ended(nil))
        f.model.saveFeedback()
        await flush()

        XCTAssertEqual(f.model.phase, .failed(.emptyTranscript))
        XCTAssertTrue(f.storage.saves.isEmpty)
        XCTAssertFalse(f.model.isLoading)

        f.model.dismissFailure()
        XCTAssertEqual(f.model.phase, .idle)
        XCTAssertEqual(f.model.transcript, "")
        XCTAssertEqual(f.model.elapsedTime, 0)
    }

    func test_recognitionErrorKeepsTextRecognizedSoFar() async {
        let f = Fixture()
        f.model.toggleRecording()
        f.capture.emit(.partial("Hello world"))
        f.model.toggleRecording()
        f.capture.emit(.ended(nil))

        XCTAssertEqual(f.model.phase, .resultReady)
        XCTAssertEqual(f.model.transcript, "Hello world")
        f.model.saveFeedback()
        await flush()
        XCTAssertEqual(f.storage.saves.count, 1)
    }

    func test_recognizerEndingWithoutStopFinishesAndFreezesTime() async {
        let f = Fixture()
        f.model.toggleRecording()
        await flush()
        await f.clock.advance(by: .seconds(2))
        f.capture.emit(.ended("Hello world"))
        await flush()

        XCTAssertEqual(f.model.phase, .resultReady)
        XCTAssertEqual(f.model.elapsedTime, 2, accuracy: 1e-9)
        XCTAssertEqual(f.clock.pendingSleepCount, 0)
        await f.clock.advance(by: .seconds(3))
        XCTAssertEqual(f.model.elapsedTime, 2, accuracy: 1e-9)
    }

    // MARK: - 저장

    func test_confirmedSaveFailureKeepsResultAndRetrySavesAgain() async {
        let f = Fixture()
        f.recordFinishedResult()
        f.model.saveFeedback()
        await flush()
        f.storage.fail(0)
        await flush()

        XCTAssertEqual(f.model.phase, .failed(.saveFailed))
        XCTAssertNotNil(f.model.errorMessage)
        XCTAssertNil(f.model.completion)

        f.model.dismissFailure()
        XCTAssertEqual(f.model.phase, .resultReady)
        XCTAssertEqual(f.model.transcript, "Hello world. Nice day.")
        f.model.saveFeedback()
        await flush()
        XCTAssertEqual(f.storage.saves.count, 2)
        f.storage.succeed(1, id: 5)
        await flush()
        XCTAssertEqual(f.model.consumeCompletion()?.summaryID, 5)
    }

    func test_saveWithoutCommittedIDIsNotRetriedToAvoidDuplicates() async {
        let f = Fixture()
        f.recordFinishedResult()
        f.model.saveFeedback()
        await flush()
        f.storage.succeed(0, id: nil)
        await flush()

        XCTAssertEqual(f.model.phase, .failed(.saveOutcomeUnknown))
        XCTAssertNil(f.model.completion)
        f.model.dismissFailure()
        XCTAssertEqual(f.model.phase, .idle)
        XCTAssertFalse(f.model.canSave)
        f.model.saveFeedback()
        XCTAssertEqual(f.storage.saves.count, 1)
    }

    // MARK: - 세션과 늦은 콜백

    func test_lateCallbacksFromAnEarlierSessionAreIgnored() async {
        let f = Fixture()
        f.model.toggleRecording()
        f.capture.emit(.partial("old"), session: 0)
        f.model.cancelRecording()
        XCTAssertEqual(f.model.phase, .idle)

        f.model.toggleRecording()
        XCTAssertEqual(f.capture.beginCount, 2)
        f.capture.emit(.partial("late old"), session: 0)
        f.capture.emit(.ended("late old final"), session: 0)

        XCTAssertEqual(f.model.phase, .recording)
        XCTAssertEqual(f.model.transcript, "")
        f.capture.emit(.partial("new"), session: 1)
        XCTAssertEqual(f.model.transcript, "new")
    }

    func test_lateCallbackAfterRecognitionEndedDoesNotChangeResult() async {
        let f = Fixture()
        f.recordFinishedResult()
        f.capture.emit(.partial("stray"))
        f.capture.emit(.ended("stray final"))

        XCTAssertEqual(f.model.phase, .resultReady)
        XCTAssertEqual(f.model.transcript, "Hello world. Nice day.")
    }

    func test_lateRecognitionCallbackCannotChangeSavingOrCompletion() async {
        let f = Fixture()
        f.recordFinishedResult()
        f.model.saveFeedback()
        await flush()
        f.capture.emit(.ended("stray final"))
        f.storage.succeed(0, id: 3)
        await flush()
        f.capture.emit(.ended("stray final"))

        XCTAssertEqual(f.model.phase, .completed)
        XCTAssertEqual(f.model.consumeCompletion()?.summaryID, 3)
        XCTAssertEqual(f.storage.saves.count, 1)
    }

    func test_duplicateStopAndCancelAreIdempotent() async {
        let f = Fixture()
        f.model.toggleRecording()
        f.model.toggleRecording()
        f.model.toggleRecording()
        XCTAssertEqual(f.capture.endAudioCount, 1)
        XCTAssertEqual(f.capture.beginCount, 1)

        f.capture.emit(.ended("Hello"))
        f.model.cancelRecording()
        f.model.cancelRecording()
        XCTAssertEqual(f.model.phase, .idle)
        f.model.toggleRecording()
        XCTAssertEqual(f.capture.beginCount, 2)
    }

    func test_newSessionStartsFromCleanState() async {
        let f = Fixture()
        f.recordFinishedResult()
        f.model.cancelRecording()
        f.model.toggleRecording()

        XCTAssertEqual(f.model.transcript, "")
        XCTAssertEqual(f.model.elapsedTime, 0)
        XCTAssertEqual(f.model.phase, .recording)
    }

    // MARK: - 화면 이탈

    func test_leavingWhileRecordingReleasesDeviceAndStopsTimer() async {
        let f = Fixture()
        f.model.toggleRecording()
        await flush()
        await f.clock.advance(by: .seconds(1))
        XCTAssertEqual(f.model.elapsedTime, 1, accuracy: 1e-9)
        f.model.leave()
        await flush()

        XCTAssertEqual(f.model.phase, .idle)
        XCTAssertEqual(f.capture.releaseCount, 1)
        XCTAssertEqual(f.clock.pendingSleepCount, 0)
        let elapsed = f.model.elapsedTime
        await f.clock.advance(by: .seconds(5))
        XCTAssertEqual(f.model.elapsedTime, elapsed)
        f.capture.emit(.ended("late"))
        XCTAssertEqual(f.model.phase, .idle)
    }

    func test_leavingWhileFinishingReleasesAndIgnoresLateFinalResult() async {
        let f = Fixture()
        f.model.toggleRecording()
        f.model.toggleRecording()
        f.model.leave()
        f.capture.emit(.ended("late final"))

        XCTAssertEqual(f.model.phase, .idle)
        XCTAssertEqual(f.capture.releaseCount, 1)
        XCTAssertEqual(f.model.transcript, "")
    }

    func test_leavingWhileSavingLetsSaveFinishButSuppressesCompletion() async {
        let f = Fixture()
        f.recordFinishedResult()
        f.model.saveFeedback()
        await flush()
        f.model.leave()

        XCTAssertEqual(f.model.phase, .saving, "시작된 저장은 취소하지 않습니다")
        f.model.saveFeedback()
        f.storage.succeed(0, id: 11)
        await flush()

        XCTAssertEqual(f.model.phase, .completed)
        XCTAssertNil(f.model.completion)
        XCTAssertNil(f.model.consumeCompletion())
        XCTAssertEqual(f.storage.saves.count, 1)
    }

    func test_leavingWhileSavingThenFailingDoesNotRetryAutomatically() async {
        let f = Fixture()
        f.recordFinishedResult()
        f.model.saveFeedback()
        await flush()
        f.model.leave()
        f.storage.fail(0)
        await flush()

        XCTAssertEqual(f.model.phase, .failed(.saveFailed))
        XCTAssertEqual(f.storage.saves.count, 1)
        XCTAssertNil(f.model.completion)
    }

    func test_leavingAfterCompletionKeepsSingleDelivery() async {
        let f = Fixture()
        f.recordFinishedResult()
        f.model.saveFeedback()
        await flush()
        f.storage.succeed(0, id: 8)
        await flush()
        let completion = f.model.consumeCompletion()
        f.model.leave()

        XCTAssertEqual(completion?.summaryID, 8)
        XCTAssertNil(f.model.consumeCompletion())
        XCTAssertEqual(f.storage.saves.count, 1)
    }
}

@MainActor
private struct Fixture {
    let permissions: FakeRecordingPermissions
    let capture = FakeRecordingCapture()
    let clock = FakeRecordingClock()
    let storage = FakeFeedbackStorage()
    let model: RecordingViewModel

    init(permission: RecordingPermissionStatus = .authorized) {
        permissions = FakeRecordingPermissions(status: permission)
        model = RecordingViewModel(
            scriptId: 9,
            sentences: ["Hello world.", "Nice day."],
            scriptManagementService: storage,
            permissions: permissions,
            capture: capture,
            clock: clock
        )
    }

    /// 녹음을 시작하고 종료해 결과 준비 단계까지 진행합니다.
    func recordFinishedResult() {
        model.toggleRecording()
        model.toggleRecording()
        capture.emit(.ended("Hello world. Nice day."))
    }
}
