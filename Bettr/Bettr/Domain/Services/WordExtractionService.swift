
import Foundation
import GRDB
import NaturalLanguage

enum WordExtractionError: LocalizedError {
    case scriptNotFound
    case deviceNotSupported
    case extractionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .scriptNotFound:
            return "스크립트를 찾을 수 없습니다."
        case .deviceNotSupported:
            return "Apple Intelligence가 활성화된 지원 기기에서만 실행 가능합니다."
        case .extractionFailed(let message):
            return "단어 추출 실패: \(message)"
        }
    }
}

class WordExtractionService {
    private let dbQueue: DatabaseQueue
    private let scriptRepository: ScriptRepository
    private let scriptManagementService: ScriptManagementService
    
    init(dbQueue: DatabaseQueue, scriptRepository: ScriptRepository, scriptManagementService: ScriptManagementService) {
        self.dbQueue = dbQueue
        self.scriptRepository = scriptRepository
        self.scriptManagementService = scriptManagementService
    }
    
    // 스크립트에서 단어 추출하고 DB에 저장
    func extractAndSaveWords(for scriptId: Int64) async throws {
        // 1. 스크립트 가져오기
        guard let scriptData = try scriptManagementService.fetchScriptWithSentencesAndChunks(id: scriptId) else {
            throw WordExtractionError.scriptNotFound
        }
        
        // 2. 모든 문장 텍스트 합치기
        let fullText = scriptData.sentences
            .map { $0.sentence.englishText }
            .joined(separator: " ")
        
        // 3. NLTagger로 단어 추출
        let tokens = NLTaggerService.tagAndExtract(from: fullText)
        
        guard !tokens.isEmpty else {
            throw WordExtractionError.extractionFailed("태깅 결과가 없습니다.")
        }
        
        // 4. Foundation Model로 필터링
        let selectedLemmas = try await FoundationModelService.selectKeywordsForHighSchool(
            script: fullText,
            tokens: tokens
        )
        
        guard !selectedLemmas.isEmpty else {
            return
        }
        
        // 5. POS 정보 추출 (majority vote)
        let selectedSet = Set(selectedLemmas.map { $0.lowercased() })
        let selectedTokens = tokens.filter { selectedSet.contains($0.lemma.lowercased()) }
        
        var lemmaToPOS: [String: String] = [:]
        let grouped = Dictionary(grouping: selectedTokens, by: { $0.lemma.lowercased() })
        for (lowercaseLemma, group) in grouped {
            var counts: [NLTag: Int] = [:]
            for t in group {
                let tag = t.pos ?? .other
                counts[tag, default: 0] += 1
            }
            if let bestTag = counts.max(by: { $0.value < $1.value })?.key {
                lemmaToPOS[lowercaseLemma] = NLTaggerService.koreanPOS(from: bestTag)
            }
        }
        
        // DB에 넣을 리스트 구성 (AFM이 멀티워드 표현을 반환하면, tokens의 lemmad와 1:1 매칭이 안되어 빠짐
        let wordsToInsert: [(lemma: String, pos: String, orderIndex: Int)] = selectedLemmas.enumerated().compactMap { index, lemma in
            let lowercaseLemma = lemma.lowercased()
            guard let pos = lemmaToPOS[lowercaseLemma] else { return nil }
            return (lemma: lemma, pos: pos, orderIndex: index)
        }
        
        let savedCount = try saveWordsToDatabase(
            scriptId: scriptId,
            wordsToInsert: wordsToInsert
        )
        
        print("✅ 단어 \(savedCount)개가 저장되었습니다.")
    }
    
    // 동기 헬퍼 함수: DB 저장 로직을 분리
    private func saveWordsToDatabase(
        scriptId: Int64,
        wordsToInsert: [(lemma: String, pos: String, orderIndex: Int)]
    ) throws -> Int {
        return try dbQueue.write { db in
            // 기존 단어 확인 및 삭제 (원자적으로 처리)
            let existingCount = try Word
                .filter(Column("scriptId") == scriptId)
                .fetchCount(db)
            
            if existingCount > 0 {
                // 기존 단어 삭제 (중복 방지)
                try Word
                    .filter(Column("scriptId") == scriptId)
                    .deleteAll(db)
            }
            
            // 새 단어 저장
            for wordData in wordsToInsert {
                var word = Word(
                    scriptId: scriptId,
                    lemma: wordData.lemma,
                    pos: wordData.pos,
                    meaning: "",
                    orderIndex: wordData.orderIndex
                )
                try word.save(db)
            }
            
            return wordsToInsert.count
        }
    }
    
    // 저장된 단어 가져오기 (orderIndex 오름차순)
    func fetchWords(for scriptId: Int64) throws -> [Word] {
        return try dbQueue.read { db in
            try Word
                .filter(Column("scriptId") == scriptId)
                .order(Column("orderIndex"))
                .fetchAll(db)
        }
    }
    
    // 단어 번역 업데이트
    func updateWordMeanings(for scriptId: Int64, translations: [String: String]) throws {
        // translations의 키도 소문자로 변환하여 일관성 유지
        let normalizedTranslations: [String: String] = Dictionary(uniqueKeysWithValues:
            translations.map { ($0.key.lowercased(), $0.value) }
        )
        
        try dbQueue.write { db in
            let words = try Word
                .filter(Column("scriptId") == scriptId)
                .fetchAll(db)
            
            for word in words {
                let lowercaseLemma = word.lemma.lowercased()
                if let meaning = normalizedTranslations[lowercaseLemma] {
                    var updatedWord = word
                    updatedWord.meaning = meaning
                    try updatedWord.update(db)
                }
            }
        }
    }
}
