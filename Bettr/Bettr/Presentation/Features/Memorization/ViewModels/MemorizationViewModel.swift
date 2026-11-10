
import BettrAI
import Foundation
import AVFoundation

@Observable
final class MemorizationViewModel: TitleEditableViewModelProtocol {
    
    // MARK: - Properties
    
    // MARK: Dependencies (의존성)
    let scriptId: Int64
    let scriptService: ScriptManagementServiceProtocol
    let audioService: AudioPlaybackServiceProtocol
    
    // MARK: Core Data State (핵심 데이터 상태)
    var scriptData: ScriptData?
    var isLoadingScript: Bool = true
    var currentError: AppError? = nil
    
    // MARK: Grouped States (그룹화된 상태)
    var uiState = MemorizationUIState()
    var interactionState = MemorizationInteractionState()
    
    // MARK: Playback (서비스 상태에서 파생, 복사본을 두지 않는다)
    var isFullPlaybackActive: Bool {
        return audioService.currentPlaybackMode == .multi
    }
    
    var isSinglePlaybackActive: Bool {
        return audioService.currentPlaybackMode == .single
    }
    
    var isPlaybackPaused: Bool {
        return audioService.isPaused
    }
    
    // MARK: Toaster Task
    private var toasterTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init(
        scriptId: Int64,
        scriptTitle: String,
        scriptService: ScriptManagementServiceProtocol,
        audioService: AudioPlaybackServiceProtocol,
    ) {
        self.scriptId = scriptId
        self.currentTitle = scriptTitle
        self.scriptService = scriptService
        self.audioService = audioService
    }
    
    // MARK: - View Lifecycle
    
    @MainActor
    func onAppear() {
        Task {
            await loadScriptById()
        }
    }
    
    func onDisappear() {
        audioService.stop()
    }
    
    // MARK: - Protocol Conformance
    
    var currentTitle: String {
        didSet {
            handleTitleChange(oldValue: oldValue, newValue: currentTitle)
        }
    }
    
    func updateLocalModelTitle(_ newTitle: String) {
        self.scriptData?.title = newTitle
    }
    
    // MARK: - User Intents & UI Handlers
    
    func endTitleEditing() {
        uiState.isTitleEditing = false
    }
    
    func toggleChunkMode() {
        guard !isSinglePlaybackActive else {
            showToaster(message: "부분 재생 중에는 모드를 변경할 수 없습니다")
            return
        }
        
        uiState.isChunkMode.toggle()
        
        interactionState.clearAllHiddenStates()
        
        let message = uiState.isChunkMode ? "청크 모드" : "문장 모드"
        showToaster(message: message)
    }
    
    func setFunctionMode(_ newMode: FunctionMode) {
        guard newMode != .read || !isFullPlaybackActive else {
            showToaster(message: "전체 재생 중에는 부분 재생을 사용할 수 없습니다")
            return
        }
        
        uiState.funcMode = newMode
        
        if uiState.funcMode == .read {
            interactionState.clearAllHiddenStates()
        }
        
        switch newMode {
        case .hide:
            showToaster(message: "탭하여 가리기")
        case .read:
            showToaster(message: "탭하여 재생하기")
        }
    }
    
    func toggleKoreanVisibility() {
        uiState.isKoreanVisible.toggle()
        
        let message = uiState.isKoreanVisible ? "번역 보기" : "번역 숨기기"
        showToaster(message: message)
    }
    
    // MARK: Playback Controls
    
    func stopPlayback() {
        audioService.stop()
    }
    
    /// 전체 재생을 시작하거나 정지합니다. 부분 재생 중에는 시작하지 않습니다.
    func togglePlayStop() {
        if isFullPlaybackActive {
            audioService.stop()
            return
        }
        
        guard !isSinglePlaybackActive else {
            showToaster(message: "부분 재생 중에는 전체 재생을 사용할 수 없습니다")
            return
        }
        guard let scriptData else { return }
        
        uiState.funcMode = .hide
        audioService.playAll(sentences: scriptData.sentences)
    }
    
    func togglePauseResume() {
        guard isFullPlaybackActive else { return }
        
        if audioService.isPaused {
            audioService.resume()
        } else {
            audioService.pause()
        }
    }
    
    // MARK: Modal
    
    /// 피드백 화면은 재생을 정지한 뒤 표시합니다. 단어장 오버레이는 재생에 영향을 주지 않습니다.
    func presentFeedbackModal() {
        audioService.stop()
        uiState.showFeedbackModal = true
    }
    
    // MARK: Script Interaction
    
    func handleChunkTap(chunk: ChunkData, identifier: ChunkIdentifier) {
        if uiState.funcMode == .hide {
            interactionState.toggleHiddenState(in: &interactionState.hiddenEngChunks, for: identifier)
        } else {
            if audioService.currentPlaybackID == .chunk(identifier) {
                audioService.stop()
            } else {
                audioService.play(text: chunk.englishText, id: .chunk(identifier))
            }
        }
    }
    
    func handleSentenceTap(sentence: SentenceData) {
        if uiState.funcMode == .hide {
            interactionState.toggleHiddenState(in: &interactionState.hiddenEngSentences, for: sentence.orderIndex)
        } else {
            if audioService.currentPlaybackID == .sentence(sentence.orderIndex) {
                audioService.stop()
            } else {
                audioService.play(text: sentence.englishText, id: .sentence(sentence.orderIndex))
            }
        }
    }
    
    // MARK: - View State Logic
    
    func isChunkHidden(_ identifier: ChunkIdentifier) -> Bool {
        return interactionState.hiddenEngChunks.contains(identifier)
    }
    
    func isSentenceHidden(_ index: Int) -> Bool {
        return interactionState.hiddenEngSentences.contains(index)
    }
    
    // MARK: - Toaster Logic
    
    /// 토스터 메시지를 2초간 표시
    func showToaster(message: String, duration: TimeInterval = 2.0) {
        toasterTask?.cancel()
        
        uiState.toasterMessage = message
        
        toasterTask = Task {
            do {
                try await Task.sleep(for: .seconds(duration))
                
                if uiState.toasterMessage == message {
                    uiState.toasterMessage = nil
                }
            } catch {
                // Task가 취소(새 토스터가 호출되면)되었을 때 이전 토스터의 숨김 타이머를 조용히 무시하고 종료
            }
        }
    }
    
    // MARK: - Data Fetching
    
    @MainActor
    func loadScriptById() async {
        
        isLoadingScript = true
        currentError = nil
        
        let maxRetries = 2
        
        defer { isLoadingScript = false }
        
        for attempt in 0...maxRetries {
            do {
                let fetchedData = try await scriptService.fetchScriptWithSentencesAndChunks(id: scriptId)
                
                let sentenceDataList: [SentenceData] = fetchedData.sentences.map { (sentence, chunks) in
                    let chunkDataList = chunks.map { ChunkData(chunk: $0) }
                    
                    return SentenceData(sentence: sentence, chunks: chunkDataList)
                }
                
                self.scriptData = ScriptData(
                    title: fetchedData.script.title,
                    sentences: sentenceDataList
                )
                
                self.currentTitle = fetchedData.script.title
                isLoadingScript = false
                currentError = nil
                return
                
            } catch let error as ScriptRepositoryError where error.isNotFoundError {
                let message = "스크립트를 불러오는데 실패했습니다: \(scriptId)번 스크립트를 찾을 수 없습니다."
                currentError = .dataNotFound(message)
                self.currentTitle = "스크립트 없음"
                isLoadingScript = false
                return
                
            } catch {
                let appError = error.toAppError()
                
                if !appError.isRetryable || attempt == maxRetries {
                    currentError = appError
                    self.currentTitle = "스크립트 오류"
                    isLoadingScript = false
                    return
                }
                
                let delaySeconds = UInt64(pow(2, Double(attempt)))
                try? await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
            }
        }
    }
}
