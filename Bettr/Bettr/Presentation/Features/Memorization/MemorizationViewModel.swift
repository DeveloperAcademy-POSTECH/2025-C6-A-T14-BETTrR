
import SwiftUI
import AVFoundation

@Observable
final class MemorizationViewModel: TitleEditableViewModelProtocol {
    
    // MARK: - Dependencies (의존성)
    let scriptId: Int64
    let scriptService: ScriptManagementServiceProtocol
    let audioService: AudioPlaybackServiceProtocol
    let wordExtractionService: WordExtractionService
    
    // MARK: - State (뷰에서 사용될 상태)
    
    // 원본 데이터
    var scriptData: ScriptData?
    
    // 스크립트 제목
    var currentTitle: String = "Loading..." {
        didSet {
            handleTitleChange(oldValue: oldValue, newValue: currentTitle)
        }
    }
    
    // 오류 상태
    var showingError = false
    var errorMessage = ""
    var isLoadingWords: Bool = false
    var words: [Word] = []
    
    // 툴바 UI 상태
    var isChunkMode: Bool = false {
        didSet { clearAllHiddenStates(); tappedPlaybackText = nil }
    }
    var funcMode: FunctionMode = .hide {
        didSet { if funcMode == .read { clearAllHiddenStates() }; tappedPlaybackText = nil }
    }
    var isKoreanVisible: Bool = true
    var showWordList: Bool = false
    var showFeedbackModal: Bool = false
    
    // 재생 상태
    var isPlaying: Bool = false {
        didSet { handleIsPlayingChange(to: isPlaying) }
    }
    var isPause: Bool = false {
        didSet { handleIsPauseChange(to: isPause) }
    }
    
    // 탭 상태
    var tappedPlaybackText: String? = nil
    
    // 가리기 상태
    var hiddenEngChunks: Set<ChunkIdentifier> = []
    var hiddenKorChunks: Set<ChunkIdentifier> = []
    var hiddenEngSentences: Set<Int> = []
    var hiddenKorSentences: Set<Int> = []
    
    // MARK: - Computed Properties (계산 프로퍼티)
    
    var isRecordingDisabled: Bool {
        scriptData == nil
    }
    
    var referenceSentences: [String] {
        scriptData?.sentences.map { $0.englishText } ?? []
    }
    
    func updateLocalModelTitle(_ newTitle: String) {
        self.scriptData?.title = newTitle
    }
    
    // MARK: - Init
    
    init(
        scriptId: Int64,
        scriptService: ScriptManagementServiceProtocol,
        audioService: AudioPlaybackServiceProtocol,
        wordExtractionService: WordExtractionService
    ) {
        self.scriptId = scriptId
        self.scriptService = scriptService
        self.audioService = audioService
        self.wordExtractionService = wordExtractionService
    }
    
    // MARK: - Public Methods (View's Lifecycle)
    
    @MainActor
    func onAppear() {
        // 뷰가 나타날 때 데이터를 비동기로 로드
        Task {
            await loadScriptById()
            await loadWords()
        }
    }
    
    func onDisappear() {
        audioService.stop()
    }
    
    // MARK: - Public Methods (User Interactions)
    
    // 청크 탭 처리
    func handleChunkTap(chunk: ChunkData, identifier: ChunkIdentifier) {
        if funcMode == .hide {
            withAnimation(.easeInOut(duration: 0.02)) {
                if hiddenEngChunks.contains(identifier) {
                    hiddenEngChunks.remove(identifier)
                } else {
                    hiddenEngChunks.insert(identifier)
                }
            }
        } else {
            audioService.play(text: chunk.englishText)
            tappedPlaybackText = chunk.englishText
        }
    }
    
    func handleKorChunkTap(chunk: ChunkData, identifier: ChunkIdentifier) {
        if funcMode == .hide {
            withAnimation(.easeInOut(duration: 0.02)) {
                if hiddenKorChunks.contains(identifier) {
                    hiddenKorChunks.remove(identifier)
                } else {
                    hiddenKorChunks.insert(identifier)
                }
            }
        }
        // 한국어는 재생 로직이 없으므로 'else'는 생략
    }
    
    // 문장 탭 처리
    func handleSentenceTap(sentence: SentenceData) {
        if funcMode == .hide {
            withAnimation(.easeInOut(duration: 0.02)) {
                if hiddenEngSentences.contains(sentence.orderIndex) {
                    hiddenEngSentences.remove(sentence.orderIndex)
                } else {
                    hiddenEngSentences.insert(sentence.orderIndex)
                }
            }
        } else {
            audioService.play(text: sentence.englishText)
            tappedPlaybackText = sentence.englishText
        }
    }
    
    func handleKorSentenceTap(sentence: SentenceData) {
        if funcMode == .hide {
            withAnimation(.easeInOut(duration: 0.02)) {
                if hiddenKorSentences.contains(sentence.orderIndex) {
                    hiddenKorSentences.remove(sentence.orderIndex)
                } else {
                    hiddenKorSentences.insert(sentence.orderIndex)
                }
            }
        }
    }
    
    // 오디오 서비스의 상태 변경 처리 (View의 .onChange에서 호출)
    func handleAudioServiceStateChange(isPlaying serviceIsPlaying: Bool, isPaused serviceIsPaused: Bool) {
        if !serviceIsPlaying && !serviceIsPaused {
            // 재생이 끝까지 완료됨
            self.isPlaying = false
            self.isPause = false
        }
    }
    
    // MARK: - Private Methods (Internal Logic)
    
    @MainActor
    private func loadScriptById() async {
        do {
            guard let fetchedData = try scriptService.fetchScriptWithSentencesAndChunks(id: scriptId) else {
                errorMessage = "스크립트를 불러오는데 실패했습니다: \(scriptId)번 스크립트를 찾을 수 없습니다."
                showingError = true
                return
            }
            
            // 원본 코드의 데이터 변환 로직
            let sentenceDataList: [SentenceData] = fetchedData.sentences.map { (sentence, chunks) in
                let chunkDataList: [ChunkData] = chunks.map { chunk in
                    return ChunkData(
                        orderIndex: chunk.orderIndex,
                        englishText: chunk.englishText,
                        koreanText: chunk.koreanText
                    )
                }
                return SentenceData(
                    orderIndex: sentence.orderIndex,
                    englishText: sentence.englishText,
                    koreanText: sentence.koreanText,
                    chunks: chunkDataList
                )
            }
            
            self.scriptData = ScriptData(
                title: fetchedData.script.title,
                sentences: sentenceDataList
            )
            
            self.currentTitle = fetchedData.script.title
            
        } catch {
            errorMessage = "스크립트 로딩 중 오류 발생: \(error.localizedDescription)"
            showingError = true
            self.currentTitle = "스크립트 오류"
        }
    }
    
    @MainActor
    private func loadWords() async {
        // 이미 단어가 존재하면 Gemini 호출 생략
        if !words.isEmpty {
            print("🟢 이미 단어 \(words.count)개 로드됨 — Gemini 호출 생략")
            return
        }
        
        isLoadingWords = true
        defer { isLoadingWords = false }
        do {
            print("🚀 [2/2] Gemini 단어 추출 시작 (MemorizationView)")
            // Gemini 호출 전 DB에도 기존 데이터가 있는지 double-check
            let existing = try wordExtractionService.fetchWords(for: scriptId)
            if !existing.isEmpty {
                print("🟢 DB에서 \(existing.count)개 단어 발견 — Gemini 호출 생략")
                self.words = existing
                return
            }
            
            try await wordExtractionService.extractAndSaveWords(for: scriptId)
            print("✅ [2/2] 단어 추출 및 저장 완료 (MemorizationView)")
            self.words = try wordExtractionService.fetchWords(for: scriptId)
        } catch {
            print("🔥 단어 추출 중 오류 발생 (MemorizationView):", error.localizedDescription)
            // 사용자에게 오류를 표시할 수 있습니다.
        }
    }
    
    private func clearAllHiddenStates() {
        hiddenEngChunks.removeAll()
        hiddenKorChunks.removeAll()
        hiddenEngSentences.removeAll()
        hiddenKorSentences.removeAll()
    }
    
    // .onChange(of: isPlaying) 로직
    private func handleIsPlayingChange(to isNowPlaying: Bool) {
        if isNowPlaying {
            guard let scriptData = scriptData else {
                isPlaying = false // 데이터 없으면 다시 끔
                return
            }
            audioService.playAll(sentences: scriptData.sentences)
            isPause = false // 재생 시작 시 '일시정지' 상태는 해제
            tappedPlaybackText = nil
        } else {
            // "정지" 버튼을 누름 (Playing/Paused -> Stopped)
            audioService.stop()
            tappedPlaybackText = nil
        }
    }
    
    // .onChange(of: isPause) 로직
    private func handleIsPauseChange(to isNowPaused: Bool) {
        guard isPlaying else { return } // isPlaying이 false(정지 상태)일 때는 무시
        
        if isNowPaused {
            audioService.pause()
        } else {
            audioService.resume()
        }
    }
}
