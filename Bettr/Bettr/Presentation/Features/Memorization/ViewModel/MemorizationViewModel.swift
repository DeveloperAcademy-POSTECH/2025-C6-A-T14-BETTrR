
import SwiftUI
import AVFoundation

@Observable
final class MemorizationViewModel {
    
    // MARK: - Dependencies (의존성)
    private let scriptId: Int64
    private let scriptService: ScriptManagementServiceProtocol
    private let audioService: AudioPlaybackServiceProtocol
    
    // MARK: - State (뷰에서 사용될 상태)
    
    // 원본 데이터
    var scriptData: ScriptData?
    
    // 오류 상태
    var showingError = false
    var errorMessage = ""
    
    // 툴바 UI 상태
    var isChunkMode: Bool = false {
        didSet { clearAllHiddenStates(); tappedPlaybackText = nil }
    }
    var funcMode: FunctionMode = .hide {
        didSet { if funcMode == .read { clearAllHiddenStates() }; tappedPlaybackText = nil }
    }
    var langMode: LanguageMode = .engKor {
        didSet { clearAllHiddenStates(); tappedPlaybackText = nil }
    }
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
    
    // 뷰에서 바로 사용할 수 있도록 데이터를 가공
    var toolbarTitle: String {
        scriptData?.title ?? "Loading..."
    }
    
    var isRecordingDisabled: Bool {
        scriptData == nil
    }
    
    var referenceSentences: [String] {
        scriptData?.sentences.map { $0.englishText } ?? []
    }
    
    // MARK: - Init
    
    init(
        scriptId: Int64,
        scriptService: ScriptManagementServiceProtocol,
        audioService: AudioPlaybackServiceProtocol
    ) {
        self.scriptId = scriptId
        self.scriptService = scriptService
        self.audioService = audioService
    }
    
    // MARK: - Public Methods (View's Lifecycle)
    
    @MainActor
    func onAppear() {
        // 뷰가 나타날 때 데이터를 비동기로 로드
        Task {
            await loadScriptById()
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
            
        } catch {
            errorMessage = "스크립트 로딩 중 오류 발생: \(error.localizedDescription)"
            showingError = true
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
