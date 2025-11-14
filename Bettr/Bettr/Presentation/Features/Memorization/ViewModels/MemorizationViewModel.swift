
import SwiftUI
import AVFoundation

@Observable
final class MemorizationViewModel: TitleEditableViewModelProtocol {
    
    // MARK: - Properties
    
    // MARK: Dependencies (의존성)
    let scriptId: Int64
    let scriptService: ScriptManagementServiceProtocol
    let audioService: AudioPlaybackServiceProtocol
    let currentFeedbackCount: Int
    
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
    
    // MARK: - Initialization
    
    init(
        scriptId: Int64,
        scriptTitle: String,
        currentFeedbackCount: Int,
        scriptService: ScriptManagementServiceProtocol,
        audioService: AudioPlaybackServiceProtocol,
    ) {
        self.scriptId = scriptId
        self.currentTitle = scriptTitle
        self.currentFeedbackCount = currentFeedbackCount
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
        uiState.tappedPlaybackText = nil
    }
    
    func setFunctionMode(_ newMode: FunctionMode) {
        uiState.funcMode = newMode
        
        if uiState.funcMode == .read {
            interactionState.clearAllHiddenStates()
        }
        uiState.tappedPlaybackText = nil
    }
    
    // MARK: Playback Controls
    
    func togglePlayStop() {
        uiState.isPlaying.toggle()
        
        if uiState.isPlaying {
            guard let scriptData = scriptData else {
                uiState.isPlaying = false
                return
            }
            audioService.playAll(sentences: scriptData.sentences)
            uiState.isPause = false
            uiState.tappedPlaybackText = nil
        } else {
            audioService.stop()
            uiState.tappedPlaybackText = nil
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
            audioService.play(text: chunk.englishText)
            uiState.tappedPlaybackText = chunk.englishText
        }
    }
    
    func handleSentenceTap(sentence: SentenceData) {
        if uiState.funcMode == .hide {
            interactionState.toggleHiddenState(in: &interactionState.hiddenEngSentences, for: sentence.orderIndex)
        } else {
            audioService.play(text: sentence.englishText)
            uiState.tappedPlaybackText = sentence.englishText
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
    
    func isTextHighlighted(_ text: String) -> Bool {
        return uiState.tappedPlaybackText == text
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
                // --- 1. 데이터 로드 시도 ---
                guard let fetchedData = try await scriptService.fetchScriptWithSentencesAndChunks(id: scriptId) else {
                    // 실패: 404 - 데이터를 찾을 수 없음
                    let message = "스크립트를 불러오는데 실패했습니다: \(scriptId)번 스크립트를 찾을 수 없습니다."
                    currentError = .dataNotFound(message)
                    self.currentTitle = "스크립트 없음"
                    isLoadingScript = false
                    return // 재시도 없이 즉시 함수 종료
                }
                
                // --- 2. 성공 ---
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
                
            } catch {
                let appError = AppError.networkError(error.localizedDescription)
                
                // 재시도 불가능한 에러이거나, 마지막 시도였다면
                if !appError.isRetryable || attempt == maxRetries {
                    currentError = appError
                    self.currentTitle = "스크립트 오류"
                    isLoadingScript = false
                    return
                }
                
                // 아직 재시도 기회 남음 (Exponential Backoff)
                let delaySeconds = UInt64(pow(2, Double(attempt)))
                try? await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
                // 딜레이 후, for 루프의 다음 단계(attempt + 1)로 넘어감
            }
        }
    }
}
