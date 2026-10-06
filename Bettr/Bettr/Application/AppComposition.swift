import SwiftUI

/// 앱 시작점의 조립 경계입니다. 기능에는 계약 또는 해당 화면의 생성 함수만 전달합니다.
@MainActor
final class AppComposition {
    private let scriptService: any ScriptManagementServiceProtocol
    private let wordService: any WordExtractionServicing
    private let analyzer: any ScriptAnalyzing
    private let audioService: any AudioPlaybackServiceProtocol
    private let rateLimiter: any AnalysisRateLimiting
    private let textRecognizer: any TextRecognizing
    private let pdfExtractor: any PDFTextExtracting

    init(
        scriptService: any ScriptManagementServiceProtocol,
        wordService: any WordExtractionServicing,
        analyzer: any ScriptAnalyzing,
        audioService: any AudioPlaybackServiceProtocol,
        rateLimiter: any AnalysisRateLimiting,
        textRecognizer: any TextRecognizing,
        pdfExtractor: any PDFTextExtracting
    ) {
        self.scriptService = scriptService
        self.wordService = wordService
        self.analyzer = analyzer
        self.audioService = audioService
        self.rateLimiter = rateLimiter
        self.textRecognizer = textRecognizer
        self.pdfExtractor = pdfExtractor
    }

    static func live() -> AppComposition {
        let database = AppDatabase.shared
        let repository = ScriptRepository(dbQueue: database.dbQueue)
        let scriptService = ScriptManagementService(scriptRepository: repository)
        let adapter = FirebaseGeminiAdapter()
        return AppComposition(
            scriptService: scriptService,
            wordService: WordExtractionService(
                dbQueue: database.dbQueue,
                scriptRepository: repository,
                scriptManagementService: scriptService,
                wordExtractor: adapter
            ),
            analyzer: adapter,
            audioService: AudioPlaybackService(),
            rateLimiter: LocalRateLimiter.shared,
            textRecognizer: TextRecognitionService(),
            pdfExtractor: PDFTextExtractor()
        )
    }

    func makeHomeListModel() -> HomeListModel {
        HomeListModel(scriptService: scriptService)
    }

    func makeHomeView(model: HomeListModel) -> HomeView {
        HomeView(model: model, textRecognitionService: textRecognizer, pdfTextExtractor: pdfExtractor)
    }

    func makeScriptConfirmView(initialText: String?, initialTitle: String?) -> ScriptConfirmView {
        ScriptConfirmView(
            initialText: initialText,
            initialTitle: initialTitle,
            analyzer: analyzer,
            scriptService: scriptService,
            rateLimiter: rateLimiter
        )
    }

    func makeMemorizationView(scriptId: Int64, scriptTitle: String) -> MemorizationView {
        MemorizationView(
            viewModel: MemorizationViewModel(
                scriptId: scriptId,
                scriptTitle: scriptTitle,
                scriptService: scriptService,
                audioService: audioService
            ),
            wordListViewModel: WordListViewModel(scriptId: scriptId, wordExtractionService: wordService),
            makeFeedbackHistory: { self.makeFeedbackHistoryView(scriptId: scriptId) }
        )
    }

    func makeFeedbackHistoryView(scriptId: Int64) -> FeedbackHistoryView {
        FeedbackHistoryView(
            viewModel: FeedbackHistoryViewModel(scriptId: scriptId, scriptService: scriptService),
            makeRecording: { scriptId, title, sentences in
                self.makeRecordingView(scriptId: scriptId, scriptTitle: title, sentences: sentences)
            },
            makeFeedbackResult: { summaryId, _ in
                self.makeFeedbackResultView(scriptId: scriptId, summaryId: summaryId)
            }
        )
    }

    func makeRecordingView(scriptId: Int64, scriptTitle: String, sentences: [String]) -> RecordingView {
        RecordingView(
            scriptId: scriptId,
            scriptTitle: scriptTitle,
            viewModel: RecordingViewModel(sentences: sentences, scriptManagementService: scriptService)
        )
    }

    func makeFeedbackResultView(scriptId: Int64, summaryId: Int64) -> FeedbackResultView {
        FeedbackResultView(viewModel: FeedbackResultViewModel(
            scriptId: scriptId,
            summaryId: summaryId,
            scriptManagementService: scriptService
        ))
    }
}
