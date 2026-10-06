import Foundation
import GRDB

@MainActor
protocol WordExtractionServicing {
    func fetchWords(for scriptId: Int64) async throws -> [Word]
    func extractAndSaveWords(for scriptId: Int64) async throws
}

@MainActor
final class WordExtractionService: WordExtractionServicing {
    private let dbQueue: DatabaseQueue
    private let scriptRepository: ScriptRepository
    private let scriptManagementService: ScriptManagementServiceProtocol
    private let wordExtractor: any WordExtracting

    init(
        dbQueue: DatabaseQueue,
        scriptRepository: ScriptRepository,
        scriptManagementService: ScriptManagementServiceProtocol,
        wordExtractor: any WordExtracting
    ) {
        self.dbQueue = dbQueue
        self.scriptRepository = scriptRepository
        self.scriptManagementService = scriptManagementService
        self.wordExtractor = wordExtractor
    }

    func extractAndSaveWords(for scriptId: Int64) async throws {
        try Task.checkCancellation()

        let existingWords = try await fetchWords(for: scriptId)
        try Task.checkCancellation()

        guard existingWords.isEmpty else {
            AppLog.ai.debug("기존 단어가 있어 추출 생략")
            return
        }

        let scriptData = try await scriptManagementService.fetchScriptWithSentencesAndChunks(id: scriptId)
        try Task.checkCancellation()

        let fullText = scriptData.sentences
            .map(\.sentence.englishText)
            .joined(separator: " ")

        let words = try await wordExtractor.extractWords(from: fullText)
        try Task.checkCancellation()

        try await saveWordsToDatabase(scriptId: scriptId, words: words)
    }

    func fetchWords(for scriptId: Int64) async throws -> [Word] {
        try await dbQueue.read { db in
            try scriptRepository.fetchWords(forScriptId: scriptId, in: db)
        }
    }

    private func saveWordsToDatabase(scriptId: Int64, words: [WordData]) async throws {
        try Task.checkCancellation()

        // 큐에 등록된 트랜잭션은 UI에서 요청을 취소해도 커밋될 수 있습니다.
        try await dbQueue.write { db in
            try scriptRepository.deleteWords(forScriptId: scriptId, in: db)

            for (index, word) in words.enumerated() {
                var entity = Word(
                    scriptId: scriptId,
                    lemma: word.lemma,
                    pos: word.pos,
                    meaning: word.meaning,
                    orderIndex: index
                )
                _ = try scriptRepository.save(word: &entity, in: db)
            }
        }
    }
}
