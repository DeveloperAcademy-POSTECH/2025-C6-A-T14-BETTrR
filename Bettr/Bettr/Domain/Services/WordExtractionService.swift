
import Foundation
import GRDB
//import FirebaseAI
import FirebaseAILogic

enum WordExtractionError: Error {
    case scriptNotFound
    case extractionFailed(String)
}

struct GeminiWord: Codable {
    let lemma: String
    let pos: String
    let meaning: String
}

class WordExtractionService {
    private let dbQueue: DatabaseQueue
    private let scriptRepository: ScriptRepository
    private let scriptManagementService: ScriptManagementServiceProtocol
    
    init(dbQueue: DatabaseQueue, scriptRepository: ScriptRepository, scriptManagementService: ScriptManagementServiceProtocol) {
        self.dbQueue = dbQueue
        self.scriptRepository = scriptRepository
        self.scriptManagementService = scriptManagementService
    }
    
    // MARK: - 🔹 Gemini 기반 단어 추출 + GRDB 저장
    func extractAndSaveWords(for scriptId: Int64) async throws {
        // 이미 단어가 존재하면 바로 리턴
        let existingWords = try await fetchWords(for: scriptId)
        if !existingWords.isEmpty {
            print("🟢 이미 단어 \(existingWords.count)개 존재 — Gemini 호출 생략")
            return
        }
        
        let ai = FirebaseAI.firebaseAI(backend: .googleAI(), useLimitedUseAppCheckTokens: true)
        let model = ai.generativeModel(modelName: "gemini-2.5-flash-lite")
        let retryExecutor = GeminiRetryExecutor()
        
        do {
            // 1️⃣ 스크립트 불러오기
            let scriptData = try await scriptManagementService.fetchScriptWithSentencesAndChunks(id: scriptId)
            
            // 2️⃣ 텍스트 합치기
            let fullText = scriptData.sentences.map { $0.sentence.englishText }.joined(separator: " ")
            
            // 3️⃣ Gemini 프롬프트 구성
            let prompt = """
당신은 이제부터 20년 경력의 영어 교육 전문가이자 한국 고등학생 대상 어휘 선별 어시스턴트이다.

# 지시문
가이드라인에 맞춰 입력된 영어 스크립트를 분석하라.  
한국 고등학생에게 학습 가치가 높은 어휘와 표현만 선별하여 지정된 출력 형식(JSON)으로 반환하라.  
코드블록은 사용하지 마라.

# 어휘 선별 guideline
- 문맥 우선: 본문 주제와 논리 전개에 핵심적으로 기여하는 의미어를 우선 선별한다.  
- 학술·논리 어휘: AWL(학술 어휘 목록) 수준 이상의 연결어, 추론·대조·원인/결과 신호어를 포함한다.  
- 다의어·혼동어: 문맥에 따라 의미가 달라질 수 있는 학습 가치 높은 어휘를 포함한다.  
- 문법 기능 표현: 수동, 분사구문, 가정법, 도치 등 고등 수준 문법 구조를 형성하는 표현도 포함한다.  
- **기초어휘 최소 기준:** **CEFR B1 레벨 이상**의 어휘를 우선적으로 선별한다. A1~A2 수준의 기초 어휘는 **'다의어', '숙어', '구동사'**로 사용되는 등 문맥에서 **고유의 핵심 의미**를 가질 때만 예외적으로 포함한다.
- 고유명사/숫자/기호 제외: 인명, 지명, 수치, 기호는 제외한다.  
- meaning 필드는 짧고 핵심적인 한국어 뜻(2~5어절)만 제시한다.  
- 출력 시 모든 필드 값은 문자열이며, 여분의 공백이나 대문자는 제거한다.

# 출력 형식 (중요)
반드시 **순수 JSON만** 출력한다.  
코드펜스(```json 등), 설명, 주석 금지.  
필드명은 아래와 동일하게 유지해야 한다.

- `pos`: 품사를 한국어 약어로 반환  
  - noun → "명"  
  - verb → "동"  
  - adjective → "형"  
  - adverb → "부"  
  - pronoun → "대명"  
  - preposition → "전"  
  - conjunction → "접"  
  - 그 외 → "숙어"

[
  {"lemma": "단어원형", "pos": "한국어 품사", "meaning": "간단한 한국어 뜻"}
]

# 입력 예시
입력: "I encountered an enormous challenge during the experiment."
출력:
[
  {"lemma": "encounter", "pos": "동", "meaning": "마주치다"},
  {"lemma": "enormous", "pos": "형", "meaning": "거대한"},
  {"lemma": "challenge", "pos": "명", "meaning": "도전"}
]

# 입력 텍스트
\(fullText)
"""
            
            // 4️⃣ Gemini 호출 + 재시도
            let didExtractWords = await retryExecutor.perform {
                    let response = try await model.generateContent(prompt)
                    guard let text = response.text else {
                        throw URLError(.badServerResponse)
                    }
                    
                    print("🧠 Gemini 단어 추출 응답:\n\(text)")
                    
                    // 코드펜스 제거 및 문자열 정리
                    let cleanedText = text
                        .replacingOccurrences(of: "```json", with: "")
                        .replacingOccurrences(of: "```", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // JSON 변환
                    guard let jsonData = cleanedText.data(using: .utf8) else {
                        throw WordExtractionError.extractionFailed("JSON 변환 실패")
                    }
                    
                    let decoder = JSONDecoder()
                    let words = try decoder.decode([GeminiWord].self, from: jsonData)
                    
                    guard !words.isEmpty else {
                        throw WordExtractionError.extractionFailed("단어가 비어 있음")
                    }
                    
                    // GRDB 저장
                    try await saveWordsToDatabase(scriptId: scriptId, words: words)
                    print("✅ Gemini 기반 단어 \(words.count)개 저장 완료")
                return true
            }

            guard didExtractWords != nil else {
                return
            }
        } catch {
            print("❌ WordExtractionService 오류: \(error.localizedDescription)")
        }
    }
    // MARK: - 🔹 단어 조회 (스크립트별)
    func fetchWords(for scriptId: Int64) async throws -> [Word] {
        try await dbQueue.read { db in
            try Word
                .filter(Column("scriptId") == scriptId)
                .order(Column("orderIndex").asc)
                .fetchAll(db)
        }
    }
    
    // MARK: - 💾 GRDB 저장 로직
    private func saveWordsToDatabase(scriptId: Int64, words: [GeminiWord]) async throws {
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


//import NaturalLanguage
//
//enum WordExtractionError: LocalizedError {
//    case scriptNotFound
//    case deviceNotSupported
//    case extractionFailed(String)
//    
//    var errorDescription: String? {
//        switch self {
//        case .scriptNotFound:
//            return "스크립트를 찾을 수 없습니다."
//        case .deviceNotSupported:
//            return "Apple Intelligence가 활성화된 지원 기기에서만 실행 가능합니다."
//        case .extractionFailed(let message):
//            return "단어 추출 실패: \(message)"
//        }
//    }
//}
//
//class WordExtractionService {
//    private let dbQueue: DatabaseQueue
//    private let scriptRepository: ScriptRepository
//    private let scriptManagementService: ScriptManagementService
//    
//    init(dbQueue: DatabaseQueue, scriptRepository: ScriptRepository, scriptManagementService: ScriptManagementService) {
//        self.dbQueue = dbQueue
//        self.scriptRepository = scriptRepository
//        self.scriptManagementService = scriptManagementService
//    }
//    
//    // 스크립트에서 단어 추출하고 DB에 저장
//    func extractAndSaveWords(for scriptId: Int64) async throws {
//        // 1. 스크립트 가져오기
//        guard let scriptData = try scriptManagementService.fetchScriptWithSentencesAndChunks(id: scriptId) else {
//            throw WordExtractionError.scriptNotFound
//        }
//        
//        // 2. 모든 문장 텍스트 합치기
//        let fullText = scriptData.sentences
//            .map { $0.sentence.englishText }
//            .joined(separator: " ")
//        
//        // 3. NLTagger로 단어 추출
//        let tokens = NLTaggerService.tagAndExtract(from: fullText)
//        
//        guard !tokens.isEmpty else {
//            throw WordExtractionError.extractionFailed("태깅 결과가 없습니다.")
//        }
//        
//        // 4. Foundation Model로 필터링
//        let selectedLemmas = try await FoundationModelService.selectKeywordsForHighSchool(
//            script: fullText,
//            tokens: tokens
//        )
//        
//        guard !selectedLemmas.isEmpty else {
//            return
//        }
//        
//        // 5. POS 정보 추출 (majority vote)
//        let selectedSet = Set(selectedLemmas.map { $0.lowercased() })
//        let selectedTokens = tokens.filter { selectedSet.contains($0.lemma.lowercased()) }
//        
//        var lemmaToPOS: [String: String] = [:]
//        let grouped = Dictionary(grouping: selectedTokens, by: { $0.lemma.lowercased() })
//        for (lowercaseLemma, group) in grouped {
//            var counts: [NLTag: Int] = [:]
//            for t in group {
//                let tag = t.pos ?? .other
//                counts[tag, default: 0] += 1
//            }
//            if let bestTag = counts.max(by: { $0.value < $1.value })?.key {
//                lemmaToPOS[lowercaseLemma] = NLTaggerService.koreanPOS(from: bestTag)
//            }
//        }
//        
//        // DB에 넣을 리스트 구성 (AFM이 멀티워드 표현을 반환하면, tokens의 lemmad와 1:1 매칭이 안되어 빠짐
//        let wordsToInsert: [(lemma: String, pos: String, orderIndex: Int)] = selectedLemmas.enumerated().compactMap { index, lemma in
//            let lowercaseLemma = lemma.lowercased()
//            guard let pos = lemmaToPOS[lowercaseLemma] else { return nil }
//            return (lemma: lemma, pos: pos, orderIndex: index)
//        }
//        
//        let savedCount = try saveWordsToDatabase(
//            scriptId: scriptId,
//            wordsToInsert: wordsToInsert
//        )
//        
//        print("✅ 단어 \(savedCount)개가 저장되었습니다.")
//    }
//    
//    // 동기 헬퍼 함수: DB 저장 로직을 분리
//    private func saveWordsToDatabase(
//        scriptId: Int64,
//        wordsToInsert: [(lemma: String, pos: String, orderIndex: Int)]
//    ) throws -> Int {
//        return try dbQueue.write { db in
//            // 기존 단어 확인 (레포지토리 활용)
//            let existing = try scriptRepository.fetchWords(forScriptId: scriptId, in: db)
//            if !existing.isEmpty {
//                try scriptRepository.deleteWords(forScriptId: scriptId, in: db)
//            }
//
//            // 새 단어 저장 (레포지토리 활용)
//            for wordData in wordsToInsert {
//                var word = Word(
//                    scriptId: scriptId,
//                    lemma: wordData.lemma,
//                    pos: wordData.pos,
//                    meaning: "",
//                    orderIndex: wordData.orderIndex
//                )
//                _ = try scriptRepository.save(word: &word, in: db)
//            }
//
//            return wordsToInsert.count
//        }
//    }
//    
//    // 저장된 단어 가져오기 (orderIndex 오름차순)
//    func fetchWords(for scriptId: Int64) throws -> [Word] {
//        return try dbQueue.read { db in
//            try scriptRepository.fetchWords(forScriptId: scriptId, in: db)
//        }
//    }
//    
//    // 단어 번역 업데이트
//    func updateWordMeanings(for scriptId: Int64, translations: [String: String]) throws {
//        // translations의 키도 소문자로 변환하여 일관성 유지
//        let normalizedTranslations: [String: String] = Dictionary(uniqueKeysWithValues:
//            translations.map { ($0.key.lowercased(), $0.value) }
//        )
//        
//        try dbQueue.write { db in
//            let words = try Word
//                .filter(Column("scriptId") == scriptId)
//                .fetchAll(db)
//            
//            for word in words {
//                let lowercaseLemma = word.lemma.lowercased()
//                if let meaning = normalizedTranslations[lowercaseLemma] {
//                    var updatedWord = word
//                    updatedWord.meaning = meaning
//                    try updatedWord.update(db)
//                }
//            }
//        }
//    }
//}
