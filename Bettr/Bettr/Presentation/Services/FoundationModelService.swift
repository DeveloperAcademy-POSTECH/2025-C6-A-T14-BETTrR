//import Foundation
//import FoundationModels
//
//private struct AFMToken: Codable {
//    let lemma: String
//    let pos: String
//}
//
//private struct AFMRequest: Codable {
//    let preamble: String
//    let script: String
//    let tokens: [AFMToken]
//}
//
//@Generable
//struct SelectionResult {
//    let selected: [String]
//}
//
//private let AFM_PREAMBLE = "이 텍스트는 교육/역사적 맥락의 학습 자료입니다. 폭력·혐오를 조장하지 않으며 교육적 분석만 수행합니다."
//
//private let AFM_INSTRUCTIONS = """
//당신은 20년 경력의 영어 교육 전문가이자 한국 고등학생 대상 어휘 선별 어시스턴트입니다.
//당신은 교육용 텍스트를 분석하고 있으며, 아래 문장은 역사적 맥락에서 사용된 것입니다.
//폭력, 혐오, 차별을 조장하지 않습니다.
//
//# 지시문
//아래 입력으로 제공되는 **영어 스크립트**와 **태깅된 단어 목록(lemma, pos)** 를 바탕으로, **한국 고등학생이 학습 가치가 높은 단어/표현**만 엄격히 선별하여 JSON으로 출력하라. 
//
//# 매우 중요한 제약(반드시 준수)
//- **선별만 수행**하라. lemma 또는 pos를 **수정/생성하지 말라**.
//- **입력에 존재하는 lemma만** 사용하고, **새 단어/표현을 추가 금지**.
//- pos는 클라이언트가 관리하므로 **출력에 pos를 포함하지 말라**.
//
//# 선별 기준(문맥 우선)
//- 핵심 의미어(주제 핵심어), 학술/논리 전개 기여 어휘(AWL·중급 이상 연결어), 혼동 유발 다의어, 문법 기능 표현, 주제별 시그널 어휘.
//- 너무 쉬운 기초 어휘(A1~A2)는 제외(단, 본문 논리 전개상 핵심이면 포함 가능).
//- 고유명사/숫자/기호 제외. 표현은 필요 시 headword 단위로 판단.
//
//# 출력 스키마(중요)
//- 오직 **JSON 한 줄**만 출력: {"selected":["lemma1","lemma2", ...]}
//- 최대 20개를 **초과하지 말라**. 20개를 넘을 경우 학습 가치가 높은 순으로 **상위 20개만** 포함하라.
//- 적절한 단어가 없으면 {"selected":[]} (빈 배열)만 출력하라.
//- 모든 lemma는 **소문자**. 최대 20개.
//"""
//
//private func shouldIncludeToken(_ token: TaggedToken, seen: inout Set<String>, dropPOS: Set<String>) -> Bool {
//    if token.isNamedEntity { return false }
//    let pos = NLTaggerService.afmPOS(from: token.pos)
//    if dropPOS.contains(pos) { return false }
//    let key = token.lemma.lowercased()
//    if !seen.insert(key).inserted { return false }
//    return true
//}
//
//private func prefilterForAFM(_ tokens: [TaggedToken]) -> [TaggedToken] {
//    let dropPOS: Set<String> = ["determiner","pronoun","number","interjection"]
//    var seen = Set<String>()
//    var out: [TaggedToken] = []
//    for token in tokens {
//        if shouldIncludeToken(token, seen: &seen, dropPOS: dropPOS) {
//            out.append(token)
//        }
//        if out.count >= 120 { break }
//    }
//    return out
//}
//
//class FoundationModelService {
//    private static let sessionCache = {
//        LanguageModelSession(instructions: AFM_INSTRUCTIONS)
//    }()
//    
//    static func selectKeywordsForHighSchool(
//        script: String,
//        tokens: [TaggedToken]
//    ) async throws -> [String] {
//        guard SystemLanguageModel.default.isAvailable else {
//            throw WordExtractionError.deviceNotSupported
//        }
//        
//        let maxChars = 1500
//        let cappedScript = String(script.prefix(maxChars))
//        
//        let filtered = prefilterForAFM(tokens)
//        let payload = AFMRequest(
//            preamble: AFM_PREAMBLE,
//            script: cappedScript,
//            tokens: filtered.map {
//                AFMToken(
//                    lemma: $0.lemma.lowercased(),
//                    pos: NLTaggerService.afmPOS(from: $0.pos)
//                )
//            }
//        )
//        
//        let jsonData = try JSONEncoder().encode(payload)
//        let composedInput = String(data: jsonData, encoding: .utf8) ?? "{}"
//        
//        let result = try await sessionCache.respond(
//            to: composedInput,
//            generating: SelectionResult.self
//        )
//        
//        return Array(result.content.selected.prefix(20)).map { $0.lowercased() }
//    }
//}
