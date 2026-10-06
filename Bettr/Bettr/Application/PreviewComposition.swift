import Foundation
import Observation
import UIKit

/// Preview와 테스트 조립은 운영 singleton, Firebase, 오디오 장치에 접근하지 않습니다.
@MainActor
enum PreviewComposition {
    static func make(
        database: AppDatabase? = nil,
        analyzer: (any ScriptAnalyzing)? = nil,
        wordExtractor: (any WordExtracting)? = nil,
        audioService: (any AudioPlaybackServiceProtocol)? = nil
    ) throws -> AppComposition {
        let database = try database ?? AppDatabase.makeInMemory()
        let repository = ScriptRepository(dbQueue: database.dbQueue)
        let scriptService = ScriptManagementService(scriptRepository: repository)
        let ai = PreviewAI()
        return AppComposition(
            scriptService: scriptService,
            wordService: WordExtractionService(
                dbQueue: database.dbQueue,
                scriptRepository: repository,
                scriptManagementService: scriptService,
                wordExtractor: wordExtractor ?? ai
            ),
            analyzer: analyzer ?? ai,
            audioService: audioService ?? PreviewAudioPlayback(),
            rateLimiter: LocalRateLimiter(uuid: "preview"),
            textRecognizer: PreviewDocumentImporter(),
            pdfExtractor: PreviewDocumentImporter()
        )
    }

    static func withDemoData() async throws -> AppComposition {
        let database = try AppDatabase.makeInMemory()
        try await DemoDataGenerator.generate(into: database)
        return try make(database: database)
    }
}

@MainActor
private struct PreviewAI: ScriptAnalyzing, WordExtracting {
    func analyzeScript(_ content: String) async throws -> ScriptData {
        ScriptData(title: "Preview", sentences: [
            SentenceData(orderIndex: 0, englishText: content, koreanText: "미리보기", chunks: [
                ChunkData(orderIndex: 0, englishText: content, koreanText: "미리보기")
            ])
        ])
    }
    func extractWords(from content: String) async throws -> [WordData] {
        [WordData(lemma: "challenge", pos: "명", meaning: "도전")]
    }
}

@MainActor
@Observable
private final class PreviewAudioPlayback: AudioPlaybackServiceProtocol {
    var isPlaybackActive = false
    var isPaused = false
    var currentPlaybackMode = PlaybackMode.stopped
    var currentSpokenTextID: String?
    var currentPlaybackID: PlaybackTargetID?
    var currentMultiSentenceIndex: Int?
    var currentSpokenRange: NSRange?

    func play(text: String, id: PlaybackTargetID, language: String) {
        currentPlaybackMode = .single
        currentPlaybackID = id
        isPlaybackActive = true
    }
    func playAll(sentences: [SentenceData], language: String) {
        currentPlaybackMode = .multi
        currentMultiSentenceIndex = sentences.first?.orderIndex
        isPlaybackActive = true
    }
    func stop() {
        isPlaybackActive = false
        isPaused = false
        currentPlaybackMode = .stopped
        currentPlaybackID = nil
        currentMultiSentenceIndex = nil
        currentSpokenRange = nil
    }
    func pause() { isPaused = true }
    func resume() { isPaused = false }
}

@MainActor
private struct PreviewDocumentImporter: TextRecognizing, PDFTextExtracting {
    func recognizeText(from image: UIImage, completion: @escaping (String) -> Void) {
        completion("Preview script.")
    }
    func extractText(from url: URL) -> String? { "Preview script." }
}
