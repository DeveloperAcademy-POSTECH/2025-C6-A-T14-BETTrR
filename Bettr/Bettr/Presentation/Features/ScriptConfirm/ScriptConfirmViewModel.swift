import Foundation
import Observation
import Synchronization

/// 취소 handler는 어느 executor에서든 실행될 수 있으므로 즉시 기록합니다.
nonisolated private final class ScriptConfirmCancellation: Sendable {
    private let cancelled = Mutex(false)

    var isCancelled: Bool { cancelled.withLock { $0 } }
    func cancel() { cancelled.withLock { $0 = true } }
}

struct ScriptConfirmCompletion: Equatable {
    let savedID: Int64
    let title: String
}

/// 화면 종류와 무관한 분석·저장 흐름입니다. 포커스와 편집 입력은 View가 소유합니다.
@MainActor
@Observable
final class ScriptConfirmViewModel {
    private enum Phase {
        case editing, analyzing, saving, completed, cancelled
        case failed(String)
    }

    private var phase = Phase.editing
    private var activeRequestID: UUID?
    private var activeCancellation: ScriptConfirmCancellation?
    private var pendingSaveID: UUID?
    private var draft: ScriptData?
    private var savedResult: ScriptConfirmCompletion?
    private var isSaveOutcomeUnknown = false
    private var pendingCompletion: ScriptConfirmCompletion?
    private var completedRequestID: UUID?
    private var completedCancellation: ScriptConfirmCancellation?

    var completion: ScriptConfirmCompletion? {
        guard completedCancellation?.isCancelled != true else { return nil }
        return pendingCompletion
    }

    @ObservationIgnored private var analysisTask: Task<Void, Never>?
    @ObservationIgnored private var timeoutTask: Task<Void, Never>?
    private let analyzer: ScriptGeminiCall
    private let scriptService: any ScriptManagementServiceProtocol
    private let rateLimiter: any AnalysisRateLimiting
    private let clock: any ScriptConfirmClock

    // 다른 MainActor 모델과 같은 iOS 26.2 deinit 런타임 우회입니다.
    nonisolated deinit {}

    var isAnalyzing: Bool {
        if case .analyzing = phase { return true }
        return false
    }

    /// UI 취소 후에도 실제 트랜잭션 결과가 돌아올 때까지 true입니다.
    var isSaving: Bool { pendingSaveID != nil }

    var isLoading: Bool {
        switch phase {
        case .analyzing, .saving: true
        default: false
        }
    }

    var canStartAnalysis: Bool {
        !isLoading && !isSaving && draft == nil && savedResult == nil && !isSaveOutcomeUnknown
    }

    var canRetrySaving: Bool {
        !isLoading && !isSaving && draft != nil && savedResult == nil && !isSaveOutcomeUnknown
    }

    var canEdit: Bool { canStartAnalysis }

    var errorMessage: String? {
        if case .failed(let message) = phase { return message }
        return nil
    }

    init(
        analyzer: any ScriptAnalyzing,
        scriptService: any ScriptManagementServiceProtocol,
        rateLimiter: any AnalysisRateLimiting,
        clock: any ScriptConfirmClock = ContinuousScriptConfirmClock()
    ) {
        self.analyzer = ScriptGeminiCall(analyzer: analyzer)
        self.scriptService = scriptService
        self.rateLimiter = rateLimiter
        self.clock = clock
    }

    func start(content: String, title: String) async {
        guard canStartAnalysis, !Task.isCancelled,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard rateLimiter.canCall(at: clock.date) else {
            phase = .failed("시스템 처리량이 초과되어 요청을 잠시 제한합니다.\n1분 후 다시 시도해 주세요.")
            return
        }

        let requestID = UUID()
        let cancellation = ScriptConfirmCancellation()
        let deadline = clock.now.advanced(by: .seconds(30))
        activeRequestID = requestID
        activeCancellation = cancellation
        phase = .analyzing
        timeoutTask = Task { [clock] in
            do {
                try await clock.sleep(until: deadline)
                analysisTimedOut(requestID: requestID)
            } catch {
                // 종료되거나 교체된 요청의 타이머는 상태를 바꾸지 않습니다.
            }
        }
        let task = Task {
            await analyze(
                content: content, title: title, requestID: requestID,
                cancellation: cancellation, deadline: deadline
            )
        }
        analysisTask = task
        await waitForTask(task, requestID: requestID, cancellation: cancellation)
    }

    func retrySaving() async {
        guard canRetrySaving, !Task.isCancelled, let draft else { return }
        let requestID = UUID()
        let cancellation = ScriptConfirmCancellation()
        activeRequestID = requestID
        activeCancellation = cancellation
        await save(draft, requestID: requestID, cancellation: cancellation)
    }

    /// 확인된 저장 실패를 버리고 사용자가 명시적으로 새 입력을 편집할 때만 호출합니다.
    func resumeEditing() {
        guard canRetrySaving else { return }
        draft = nil
        phase = .editing
    }

    func cancel() {
        activeCancellation?.cancel()
        completedCancellation?.cancel()
        activeRequestID = nil
        activeCancellation = nil
        stopAnalysisTasks()
        pendingCompletion = nil
        completedRequestID = nil
        completedCancellation = nil
        phase = .cancelled
        // 시작된 저장은 취소하지 않습니다. 결과를 관찰해 중복 저장을 막습니다.
    }

    func consumeCompletion() -> ScriptConfirmCompletion? {
        defer {
            pendingCompletion = nil
            completedRequestID = nil
            completedCancellation = nil
        }
        return completion
    }

    private func analyze(
        content: String,
        title: String,
        requestID: UUID,
        cancellation: ScriptConfirmCancellation,
        deadline: ContinuousClock.Instant
    ) async {
        guard activeRequestID == requestID, isAnalyzing, !Task.isCancelled else { return }
        guard !cancellation.isCancelled else {
            cancel()
            return
        }
        do {
            let result = try await analyzer.analyzeScript(content)
            guard activeRequestID == requestID, isAnalyzing, !Task.isCancelled else { return }
            guard !cancellation.isCancelled else {
                cancel()
                return
            }
            // 타이머 실행이 밀려도 deadline 이후의 분석 결과를 저장하지 않습니다.
            guard clock.now < deadline else {
                analysisTimedOut(requestID: requestID)
                return
            }
            timeoutTask?.cancel()
            timeoutTask = nil
            analysisTask = nil
            let confirmed = ScriptData(title: title.isEmpty ? result.title : title, sentences: result.sentences)
            draft = confirmed
            await save(confirmed, requestID: requestID, cancellation: cancellation)
        } catch {
            guard activeRequestID == requestID, isAnalyzing else { return }
            stopAnalysisTasks()
            activeRequestID = nil
            activeCancellation = nil
            if cancellation.isCancelled || error is CancellationError || (error as? AIError) == .cancelled {
                phase = .cancelled
            } else {
                phase = .failed((error as? AIError ?? .unknown).localizedDescription)
            }
        }
    }

    private func analysisTimedOut(requestID: UUID) {
        guard activeRequestID == requestID, isAnalyzing else { return }
        activeRequestID = nil
        activeCancellation?.cancel()
        activeCancellation = nil
        stopAnalysisTasks()
        phase = .failed("네트워크 연결 상태를 확인해 주세요.\n연결에 문제가 없다면 잠시 후 다시 시도해 주세요.")
    }

    private func stopAnalysisTasks() {
        timeoutTask?.cancel()
        analysisTask?.cancel()
        timeoutTask = nil
        analysisTask = nil
    }

    private func save(
        _ draft: ScriptData,
        requestID: UUID,
        cancellation: ScriptConfirmCancellation
    ) async {
        guard activeRequestID == requestID, pendingSaveID == nil else { return }
        guard !cancellation.isCancelled else {
            cancel()
            return
        }
        pendingSaveID = requestID
        phase = .saving

        // 비구조적 Task는 호출부 취소를 전파하지 않습니다. self를 저장 완료까지 유지해
        // 화면 이탈 이후에도 실제 commit/rollback 결과를 한 번 반영합니다.
        let task = Task {
            guard !cancellation.isCancelled else {
                pendingSaveID = nil
                if activeRequestID == requestID { cancel() }
                return
            }
            do {
                let script = try await scriptService.createScript(scriptData: draft)
                pendingSaveID = nil
                guard let savedID = script.id else {
                    markSaveOutcomeUnknown(requestID: requestID, cancellation: cancellation)
                    return
                }
                let result = ScriptConfirmCompletion(savedID: savedID, title: script.title)
                savedResult = result
                self.draft = nil
                if activeRequestID == requestID {
                    if cancellation.isCancelled {
                        cancel()
                    } else {
                        activeRequestID = nil
                        activeCancellation = nil
                        phase = .completed
                        completedRequestID = requestID
                        completedCancellation = cancellation
                        pendingCompletion = result
                    }
                }
            } catch {
                pendingSaveID = nil
                if error is CancellationError {
                    markSaveOutcomeUnknown(requestID: requestID, cancellation: cancellation)
                } else if activeRequestID == requestID {
                    if cancellation.isCancelled {
                        cancel()
                    } else {
                        activeRequestID = nil
                        activeCancellation = nil
                        phase = .failed("스크립트를 저장하지 못했습니다. 분석 결과는 유지됩니다. 저장을 다시 시도해 주세요.")
                        AppLog.database.error("스크립트 저장 실패")
                    }
                }
            }
        }
        await waitForTask(task, requestID: requestID, cancellation: cancellation)
    }

    private func markSaveOutcomeUnknown(requestID: UUID, cancellation: ScriptConfirmCancellation) {
        isSaveOutcomeUnknown = true
        if activeRequestID == requestID {
            guard !cancellation.isCancelled else {
                cancel()
                return
            }
            activeRequestID = nil
            activeCancellation = nil
            phase = .failed("저장 결과를 확인하지 못했습니다. 중복 저장을 막기 위해 목록에서 저장 여부를 확인해 주세요.")
        }
    }

    private func waitForTask(
        _ task: Task<Void, Never>,
        requestID: UUID,
        cancellation: ScriptConfirmCancellation
    ) async {
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            cancellation.cancel()
            Task { @MainActor [weak self] in
                guard let self,
                      self.activeRequestID == requestID || self.completedRequestID == requestID else { return }
                self.cancel()
            }
        }
    }
}
