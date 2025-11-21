
import SwiftUI
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
    
    // MARK: Computed Properties (계산 프로퍼티)
    var isRecordingDisabled: Bool { scriptData == nil }
    var referenceSentences: [String] { scriptData?.sentences.map { $0.englishText } ?? [] }
    
    // MARK: Mutex Playback Control
    var isReadModeDisabled: Bool {
        // 현재 전체 재생 모드인 경우, Read 모드 버튼을 숨깁니다.
        return audioService.currentPlaybackMode == .multi
    }

    var isFullPlayDisabled: Bool {
        // 현재 단일 재생 모드라면 전체 재생 버튼(툴바의 토글 버튼)을 막습니다.
        return audioService.currentPlaybackMode == .single
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
        uiState.isChunkMode.toggle()
        
        interactionState.clearAllHiddenStates()
        
        let message = uiState.isChunkMode ? "청크 모드" : "문장 모드"
        showToaster(message: message)
    }
    
    func setFunctionMode(_ newMode: FunctionMode) {
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
    
    func togglePlayStop() {
        uiState.isPlaying.toggle()
        
        if uiState.isPlaying {
            guard let scriptData = scriptData else {
                uiState.isPlaying = false
                return
            }
            
            uiState.funcMode = .hide
            
            audioService.playAll(sentences: scriptData.sentences)
            uiState.isPause = false
        } else {
            audioService.stop()
            
            if audioService.isPlaying {
                self.uiState.isPlaying = false
            }
        }
    }
    
    func togglePauseResume() {
        guard uiState.isPlaying else { return }
        
        uiState.isPause.toggle()
        
        if uiState.isPause {
            audioService.pause()
        } else {
            audioService.resume()
        }
    }
    
    // MARK: Script Interaction
    
    func handleChunkTap(chunk: ChunkData, identifier: ChunkIdentifier) {
        if uiState.funcMode == .hide {
            interactionState.toggleHiddenState(in: &interactionState.hiddenEngChunks, for: identifier)
        } else {
            if audioService.currentSpokenTextID == chunk.englishText {
                audioService.stop()
            } else {
                audioService.play(text: chunk.englishText)
            }
        }
    }
    
    func handleSentenceTap(sentence: SentenceData) {
        if uiState.funcMode == .hide {
            interactionState.toggleHiddenState(in: &interactionState.hiddenEngSentences, for: sentence.orderIndex)
        } else {
            if audioService.currentSpokenTextID == sentence.englishText {
                audioService.stop()
            } else {
                audioService.play(text: sentence.englishText)
            }
        }
    }
    
    // MARK: Service Callbacks
    
    func handleAudioServiceStateChange(isPlaying serviceIsPlaying: Bool, isPaused serviceIsPaused: Bool) {
        if !serviceIsPlaying && !serviceIsPaused {
            self.uiState.isPlaying = false
            self.uiState.isPause = false
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
                // 실패: 404 - 데이터를 찾을 수 없음
                let message = "스크립트를 불러오는데 실패했습니다: \(scriptId)번 스크립트를 찾을 수 없습니다."
                currentError = .dataNotFound(message)
                self.currentTitle = "스크립트 없음"
                isLoadingScript = false
                return // 재시도 없이 즉시 함수 종료
                
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
