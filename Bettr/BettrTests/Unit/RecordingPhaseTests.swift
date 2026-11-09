import XCTest
@testable import Bettr

final class RecordingPhaseTests: XCTestCase {
    func test_happyPathFollowsDocumentedOrder() {
        let events: [RecordingEvent] = [
            .startRequested, .captureStarted, .stopRequested, .recognitionEnded, .saveRequested, .saveSucceeded
        ]
        var phase = RecordingPhase.idle
        var visited = [phase]
        for event in events {
            phase = try! XCTUnwrap(phase.transitioned(on: event), "\(phase) must accept \(event)")
            visited.append(phase)
        }

        XCTAssertEqual(visited, [
            .idle, .requestingPermission, .recording, .finishing, .resultReady, .saving, .completed
        ])
    }

    func test_duplicateOrOutOfOrderEventsAreRejected() {
        XCTAssertNil(RecordingPhase.requestingPermission.transitioned(on: .startRequested))
        XCTAssertNil(RecordingPhase.recording.transitioned(on: .startRequested))
        XCTAssertNil(RecordingPhase.finishing.transitioned(on: .stopRequested))
        XCTAssertNil(RecordingPhase.idle.transitioned(on: .stopRequested))
        XCTAssertNil(RecordingPhase.resultReady.transitioned(on: .recognitionEnded))
        XCTAssertNil(RecordingPhase.idle.transitioned(on: .saveRequested))
        XCTAssertNil(RecordingPhase.recording.transitioned(on: .saveRequested))
        XCTAssertNil(RecordingPhase.saving.transitioned(on: .saveRequested))
        XCTAssertNil(RecordingPhase.completed.transitioned(on: .saveRequested))
        XCTAssertNil(RecordingPhase.completed.transitioned(on: .saveSucceeded))
        XCTAssertNil(RecordingPhase.resultReady.transitioned(on: .saveSucceeded))
    }

    func test_resetIsRejectedOnlyWhileSaving() {
        let resettable: [RecordingPhase] = [
            .idle, .requestingPermission, .recording, .finishing, .resultReady, .completed,
            .failed(.emptyTranscript)
        ]
        for phase in resettable {
            XCTAssertEqual(phase.transitioned(on: .reset), .idle, "\(phase)")
        }
        XCTAssertNil(RecordingPhase.saving.transitioned(on: .reset))
    }

    func test_recognizerMayEndWithoutUserStop() {
        XCTAssertEqual(RecordingPhase.recording.transitioned(on: .recognitionEnded), .resultReady)
    }

    func test_failuresRecoverToTheirOwnPhase() {
        XCTAssertEqual(RecordingPhase.requestingPermission.transitioned(on: .permissionDenied), .failed(.permissionDenied))
        XCTAssertEqual(RecordingPhase.requestingPermission.transitioned(on: .captureFailed), .failed(.captureUnavailable))
        XCTAssertEqual(RecordingPhase.saving.transitioned(on: .emptyResult), .failed(.emptyTranscript))
        XCTAssertEqual(RecordingPhase.saving.transitioned(on: .saveFailed), .failed(.saveFailed))
        XCTAssertEqual(RecordingPhase.saving.transitioned(on: .saveOutcomeUnknown), .failed(.saveOutcomeUnknown))

        XCTAssertEqual(RecordingPhase.failed(.saveFailed).transitioned(on: .failureDismissed), .resultReady)
        for failure in [RecordingFailure.permissionDenied, .captureUnavailable, .emptyTranscript, .saveOutcomeUnknown] {
            XCTAssertEqual(RecordingPhase.failed(failure).transitioned(on: .failureDismissed), .idle, "\(failure)")
        }
        XCTAssertNil(RecordingPhase.idle.transitioned(on: .failureDismissed))
    }

    func test_failedPhaseIsDisplayedAsItsRecoveryPhase() {
        XCTAssertEqual(RecordingPhase.failed(.saveFailed).displayed, .resultReady)
        XCTAssertEqual(RecordingPhase.failed(.emptyTranscript).displayed, .idle)
        XCTAssertEqual(RecordingPhase.recording.displayed, .recording)
    }
}
