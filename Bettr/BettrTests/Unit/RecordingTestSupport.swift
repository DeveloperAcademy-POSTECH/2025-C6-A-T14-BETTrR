import BettrAI
import Foundation
@testable import Bettr

@MainActor
final class FakeRecordingPermissions: RecordingPermissionProviding {
    var status: RecordingPermissionStatus
    private(set) var requestCount = 0
    private var pending: [CheckedContinuation<RecordingPermissionStatus, Never>] = []

    init(status: RecordingPermissionStatus = .authorized) {
        self.status = status
    }

    func requestAuthorization() async -> RecordingPermissionStatus {
        requestCount += 1
        return await withCheckedContinuation { pending.append($0) }
    }

    func resolve(_ result: RecordingPermissionStatus) {
        status = result
        guard !pending.isEmpty else { return }
        pending.removeFirst().resume(returning: result)
    }
}

/// 실제 장치와 달리 `release` 이후에도 이전 핸들러를 호출할 수 있어,
/// 늦은 콜백을 ViewModel이 스스로 걸러내는지 검증합니다.
@MainActor
final class FakeRecordingCapture: RecordingCapturing {
    var beginError: Error?
    private(set) var beginCount = 0
    private(set) var endAudioCount = 0
    private(set) var releaseCount = 0
    private var handlers: [@MainActor (RecordingCaptureEvent) -> Void] = []

    func begin(onEvent: @escaping @MainActor (RecordingCaptureEvent) -> Void) throws {
        if let beginError { throw beginError }
        beginCount += 1
        handlers.append(onEvent)
    }

    func endAudio() { endAudioCount += 1 }
    func release() { releaseCount += 1 }

    /// `session`은 0부터 시작하는 `begin` 호출 순서입니다. 기본값은 가장 최근 세션입니다.
    func emit(_ event: RecordingCaptureEvent, session: Int? = nil) {
        handlers[session ?? handlers.count - 1](event)
    }
}

@MainActor
final class FakeRecordingClock: RecordingClock {
    let origin = ContinuousClock.now
    private(set) var now: ContinuousClock.Instant
    private(set) var deadlines: [ContinuousClock.Instant] = []
    private var nextID = 0
    private var pending: [Int: (deadline: ContinuousClock.Instant, continuation: CheckedContinuation<Void, Error>)] = [:]

    init() { now = origin }

    var pendingSleepCount: Int { pending.count }

    func sleep(until deadline: ContinuousClock.Instant) async throws {
        try Task.checkCancellation()
        let id = nextID
        nextID += 1
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pending[id] = (deadline, continuation)
                deadlines.append(deadline)
            }
        } onCancel: {
            Task { @MainActor in self.cancelSleep(id) }
        }
    }

    /// 시간을 진행하고 만료된 sleep을 깨운 뒤, 깨어난 Task가 실행되도록 양보합니다.
    func advance(by duration: Duration) async {
        now = now.advanced(by: duration)
        for (id, entry) in pending where entry.deadline <= now {
            pending.removeValue(forKey: id)
            entry.continuation.resume()
        }
        await flush()
    }

    private func cancelSleep(_ id: Int) {
        pending.removeValue(forKey: id)?.continuation.resume(throwing: CancellationError())
    }
}

enum RecordingStorageFailure: Error {
    case rollback
}

struct RecordedFeedbackSave {
    let scriptId: Int64
    let accuracy: Double
    let missingWordCount: Int
    let addedWordCount: Int
    let replacedWordCount: Int
    let practiceDuration: Double
    let detailCount: Int
}

@MainActor
final class FakeFeedbackStorage: ScriptManagementServiceProtocol {
    private(set) var saves: [RecordedFeedbackSave] = []
    private var pending: [Int: CheckedContinuation<FeedbackSummary, Error>] = [:]

    func createFeedbackSummary(
        scriptId: Int64,
        accuracy: Double,
        missingWordCount: Int,
        addedWordCount: Int,
        replacedWordCount: Int,
        practiceDuration: Double,
        feedbackDetailsData: [(wordDiff: WordDiff, originalText: String?, sentenceIndex: Int, wordIndex: Int)]
    ) async throws -> FeedbackSummary {
        let index = saves.count
        return try await withCheckedThrowingContinuation { continuation in
            pending[index] = continuation
            saves.append(RecordedFeedbackSave(
                scriptId: scriptId, accuracy: accuracy, missingWordCount: missingWordCount,
                addedWordCount: addedWordCount, replacedWordCount: replacedWordCount,
                practiceDuration: practiceDuration, detailCount: feedbackDetailsData.count
            ))
        }
    }

    func succeed(_ index: Int, id: Int64? = 42) {
        let save = saves[index]
        let summary = FeedbackSummary(
            id: id, scriptId: save.scriptId, accuracy: save.accuracy,
            missingWordCount: save.missingWordCount, addedWordCount: save.addedWordCount,
            replacedWordCount: save.replacedWordCount, practiceDuration: save.practiceDuration,
            createdAt: Date(timeIntervalSince1970: 0)
        )
        pending.removeValue(forKey: index)?.resume(returning: summary)
    }

    func fail(_ index: Int, error: Error = RecordingStorageFailure.rollback) {
        pending.removeValue(forKey: index)?.resume(throwing: error)
    }

    func createScript(scriptData: ScriptData) async throws -> Script { fatalError("Unexpected write") }
    func fetchAllScripts() async throws -> [Script] { fatalError("Unexpected read") }
    func deleteScript(id: Int64) async throws { fatalError("Unexpected delete") }
    func fetchScript(id: Int64) async throws -> Script? { fatalError("Unexpected read") }
    func fetchScriptWithSentences(id: Int64) async throws -> (script: Script, sentences: [Sentence]) {
        fatalError("Unexpected read")
    }
    func fetchScriptWithSentencesAndChunks(id: Int64) async throws -> (script: Script, sentences: [(sentence: Sentence, chunks: [Chunk])]) {
        fatalError("Unexpected read")
    }
    func updateLastViewedAt(forScriptId scriptId: Int64) async throws { fatalError("Unexpected update") }
    func updateScriptTitle(scriptId: Int64, newTitle: String) async throws { fatalError("Unexpected update") }
    func fetchAllFeedbackSummaries() async throws -> [FeedbackSummary] { fatalError("Unexpected read") }
    func fetchFeedbackSummaries(forScriptId scriptId: Int64) async throws -> [FeedbackSummary] {
        fatalError("Unexpected read")
    }
    func fetchFeedbackDetails(forFeedbackSummaryId feedbackSummaryId: Int64) async throws -> [FeedbackDetail] {
        fatalError("Unexpected read")
    }
}

/// 실제 대기 없이 MainActor의 대기 중인 Task가 진행되도록 양보합니다.
@MainActor
func flush() async {
    for _ in 0..<50 { await Task.yield() }
}
