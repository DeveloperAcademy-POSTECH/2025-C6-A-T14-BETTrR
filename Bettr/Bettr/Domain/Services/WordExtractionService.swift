
import Foundation
import GRDB
import FirebaseAI

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
    private let scriptManagementService: ScriptManagementService
    
    init(dbQueue: DatabaseQueue, scriptRepository: ScriptRepository, scriptManagementService: ScriptManagementService) {
        self.dbQueue = dbQueue
        self.scriptRepository = scriptRepository
        self.scriptManagementService = scriptManagementService
    }
    
    // MARK: - 🔹 Gemini 기반 단어 추출 + GRDB 저장
    func extractAndSaveWords(for scriptId: Int64) async {
        let maxRetry = 2
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let model = ai.generativeModel(modelName: "gemini-2.0-flash-lite")
        
        do {
            // 1️⃣ 스크립트 불러오기
            guard let scriptData = try scriptManagementService.fetchScriptWithSentencesAndChunks(id: scriptId) else {
                throw WordExtractionError.scriptNotFound
            }
            
            // 2️⃣ 텍스트 합치기
            let fullText = scriptData.sentences.map { $0.sentence.englishText }.joined(separator: " ")
            
            // 3️⃣ Gemini 프롬프트 구성
            let prompt = """
            당신은 영어 어휘 전문가이자 한국어 번역가입니다.

            아래 영어 문장에서 학습자가 모를만한 주요 단어를 추출하고,
            각 단어의 품사(명사, 동사, 형용사 등)와 간결한 한국어 뜻을 함께 JSON으로 출력하세요.

            # 출력 형식 (중요)
            반드시 **순수 JSON만** 출력합니다.
            코드펜스(```json 등), 설명, 주석 금지.
            필드명은 아래와 동일하게 유지해야 합니다.

            [
              {"lemma": "단어원형", "pos": "품사", "meaning": "간단한 한국어 뜻"}
            ]

            # 예시
            입력: "I encountered an enormous challenge during the experiment."
            출력:
            [
              {"lemma": "encounter", "pos": "verb", "meaning": "마주치다"},
              {"lemma": "enormous", "pos": "adjective", "meaning": "거대한"},
              {"lemma": "challenge", "pos": "noun", "meaning": "도전"}
            ]

            # 입력 텍스트
            \(fullText)
            """
            
            // 4️⃣ Gemini 호출 + 재시도
            for attempt in 1...maxRetry {
                do {
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
                    try saveWordsToDatabase(scriptId: scriptId, words: words)
                    print("✅ Gemini 기반 단어 \(words.count)개 저장 완료")
                    return // 성공 시 종료
                    
                } catch {
                    // 에러 로깅 및 분류
                    print("🔥 WordExtraction 오류 (시도 \(attempt)/\(maxRetry)): \(error.localizedDescription)")
                    
                    let nsError = error as NSError
                    let category = classifyGeminiCallError(error)
                    print("   - Domain: \(nsError.domain), Code: \(nsError.code)")
                    print("   - 분류 결과: \(category)")
                    
                    switch category {
                    case .clientInput:
                        print("❌ 입력 문제 — 문장 형식을 점검하세요.")
                        return
                    case .auth:
                        print("🔑 인증 오류 — FirebaseAI 연결을 확인하세요.")
                        return
                    case .rateLimited:
                        print("⏳ 요청 한도 초과 — 잠시 후 재시도 필요.")
                        return
                    case .transient:
                        if attempt < maxRetry {
                            let delay = pow(2.0, Double(attempt - 1))
                            print("🌐 일시적 오류 — \(delay)s 후 재시도 (\(attempt)/\(maxRetry))")
                            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                            continue
                        } else {
                            print("❌ 재시도 실패 — 서버 연결 불안정.")
                            return
                        }
                    case .jsonParsing:
                        if attempt < maxRetry {
                            print("⚠️ JSON 파싱 실패 — 재시도 중 (\(attempt)/\(maxRetry))")
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                            continue
                        } else {
                            print("❌ JSON 파싱 실패 — Gemini 출력 확인 필요.")
                            return
                        }
                    case .unknown:
                        print("❓ 알 수 없는 오류 발생 — \(error.localizedDescription)")
                        return
                    }
                }
            }
        } catch {
            print("❌ WordExtractionService 오류: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 💾 GRDB 저장 로직
    private func saveWordsToDatabase(scriptId: Int64, words: [GeminiWord]) throws {
        try dbQueue.write { db in
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
