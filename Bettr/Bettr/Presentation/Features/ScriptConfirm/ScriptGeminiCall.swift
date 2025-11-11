//
//  ScriptGeminiCall.swift
//  Bettr
//
//  Created by 서세린 on 11/5/25.
//

import SwiftUI
import FirebaseAI

// MARK: - Gemini 호출 전담 클래스
final class ScriptGeminiCall {
    // 🔹 스크립트를 분석해 ScriptData(JSON)로 반환
    func analyzeScript(_ scriptContent: String) async throws -> ScriptData? {
        
        let maxRetry = 2 // 공식문서 참조 두 번 이하 재시도
        
        //모델 초기화는 루프 밖에서 진행.
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let model = ai.generativeModel(modelName: "gemini-2.5-flash-lite")
        
        for attempt in 1...maxRetry {
            do {
                // 새로운 JSON 전용 프롬프트 추가
                let prompt = """
                               당신은 20년 경력의 영어-한국어 언어 코치입니다.
                               
                               # 목표
                               입력된 영어 스크립트를 문장 단위로 분할하고, 각 문장을 의미 단위 청크로 나눈 뒤 1:1로 한국어 번역을 정렬합니다.
                               또한 각 문장의 자연스러운 전체 번역을 생성합니다.
                               title은 그냥 "title"를 기본 제목으로 사용합니다.
                               
                               # 출력 형식 (중요)
                               - 반드시 **순수 JSON 하나만** 출력합니다.
                               - 코드펜스(json,  등), 설명, 주석, 추가 텍스트 금지.
                               - 키 이름은 DTO(ScriptData, SentenceData, ChunkData)와 동일하게 유지:
                                 title, sentences[].orderIndex, sentences[].englishText, sentences[].koreanText, sentences[].chunks[].orderIndex,sentences[].chunks[].englishText, sentences[].chunks[].koreanText
                               
                               # JSON 스키마
                               {
                                 "title": string,
                                 "sentences": [
                                   {
                                     "orderIndex": number,
                                     "englishText": string,
                                     "koreanText": string,
                                     "chunks": [ { "orderIndex": number, "englishText": string, "koreanText": string } ]
                                   }
                                 ]
                               }
                               
                               # 인덱싱 규칙
                               1. sentences[].orderIndex는 0부터 시작하여 각 문장 순서대로 1씩 증가합니다.
                               2. 각 문장 내부의 chunks[].orderIndex도 0부터 시작하여 순서대로 1씩 증가합니다.
                               3. 인덱스는 문장과 청크의 실제 순서를 반영해야 합니다.
                               
                               # 청킹 규칙 (요약)
                               1) 의미 중심 (3~8단어 권장)
                               2) S+V 결속 / 5형식은 O+OC 결속
                               3) 전치사-보어 결속
                               4) 호흡/리듬 고려
                               5) 커버리지 100% (단어/구두점 누락 금지, 순서 보존)
                               
                               **# 청크 번역 스타일 (강화)**
                               - 청크 번역(`chunks[].koreanText`)은 영어 구조와 의미에 **직접적으로 대응**하는 **직역 기반**으로 생성하여 영어 학습에 도움이 되도록 합니다.
                               - 전체 문장 번역(`koreanText`)은 **가장 자연스러운 한국어**로 완성합니다.
                                
                               # Few-Shot 예시 1
                                
                               # 입력 스크립트 예시
                               "The most significant advantage of this new technology lies in its potential to revolutionize sustainable energy sources, which is a major concern globally."
                                
                               # 출력 JSON 예시
                               {
                                 "title": "title",
                                 "sentences": [
                                   {
                                     "orderIndex": 0,
                                     "englishText": "The most significant advantage of this new technology lies in its potential to revolutionize sustainable energy sources, which is a major concern globally.",
                                     "koreanText": "이 새로운 기술의 가장 중요한 장점은 전 세계적인 주요 관심사인 지속 가능한 에너지원을 혁신할 잠재력에 있다는 것이다.",
                                     "chunks": [
                                       { "orderIndex": 0, "englishText": "The most significant advantage", "koreanText": "가장 중요한 장점은" },
                                       { "orderIndex": 1, "englishText": "of this new technology", "koreanText": "이 새로운 기술의" },
                                       { "orderIndex": 2, "englishText": "lies in its potential", "koreanText": "그 잠재력에 있다" },
                                       { "orderIndex": 3, "englishText": "to revolutionize sustainable energy sources,", "koreanText": "지속 가능한 에너지원을 혁신할," },
                                       { "orderIndex": 4, "englishText": "which is a major concern globally.", "koreanText": "그것은 전 세계적인 주요 관심사이다." }
                                     ]
                                   }
                                 ]
                               }
                                
                               # Few-Shot 예시 2
                                
                               # 입력 스크립트 예시
                               "Despite the challenging weather, the team successfully completed the mission. Their dedication was truly remarkable."
                                
                               # 출력 JSON 예시
                               {
                                 "title": "title",
                                 "sentences": [
                                   {
                                     "orderIndex": 0,
                                     "englishText": "Despite the challenging weather, the team successfully completed the mission.",
                                     "koreanText": "어려운 날씨에도 불구하고, 팀은 임무를 성공적으로 완수했다.",
                                     "chunks": [
                                       { "orderIndex": 0, "englishText": "Despite the challenging weather,", "koreanText": "어려운 날씨에도 불구하고," },
                                       { "orderIndex": 1, "englishText": "the team successfully completed", "koreanText": "그 팀은 성공적으로 완수했다" },
                                       { "orderIndex": 2, "englishText": "the mission.", "koreanText": "그 임무를." }
                                     ]
                                   },
                                   {
                                     "orderIndex": 1,
                                     "englishText": "Their dedication was truly remarkable.",
                                     "koreanText": "그들의 헌신은 정말 놀라웠다.",
                                     "chunks": [
                                       { "orderIndex": 0, "englishText": "Their dedication", "koreanText": "그들의 헌신은" },
                                       { "orderIndex": 1, "englishText": "was truly remarkable.", "koreanText": "진정으로 놀라웠다." }
                                     ]
                                   }
                                 ]
                               }
                                
                               # 입력 스크립트
                               \(scriptContent)
                               """
                
                let response = try await model.generateContent(prompt)
                guard let text = response.text else {
                    throw URLError(.badServerResponse) // 에러 전달
                }
                
                print("Gemini 응답:\n\(text)")
                
//                //    ↓ JSON 디코딩 전용 함수로 교체
//                if let jsonParsed = parseGeminiJSONToScriptData(text, fallbackTitle: "사용자 입력 스크립트") {
//                    await MainActor.run { self.parsedScript = jsonParsed }
//                    return // 성공 시 함수 종료
//                } else {
//                    throw URLError(.cannotParseResponse)
//                }
                // 🔹 JSON 파싱 시도
                if let parsed = parseGeminiJSONToScriptData(text, fallbackTitle: "사용자 입력 스크립트") {
                    print("✅ JSON 파싱 성공 → ScriptData 생성 완료")
                    return parsed
                } else {
                    throw URLError(.cannotParseResponse)
                }
                
            } catch {
                // 🔹 에러 로그
                print("🔥 Gemini 호출 오류 (\(attempt)/\(maxRetry)): \(error.localizedDescription)")
                let category = classifyGeminiCallError(error)
                
                switch category {
                case .clientInput:
                    print("❌ 입력 형식 문제 (Gemini 프롬프트 점검 필요)")
                    return nil
                case .auth:
                    print("🔑 인증 오류 - FirebaseAI 토큰 확인 필요")
                    return nil
                case .rateLimited:
                    print("⏳ 요청 한도 초과 - 잠시 후 재시도 필요")
                    return nil
                case .transient:
                    if attempt < maxRetry {
                        let delay = pow(2.0, Double(attempt - 1))
                        print("🌐 일시적 오류 — \(delay)s 후 재시도")
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    } else {
                        print("❌ 재시도 실패 — 네트워크 불안정")
                        return nil
                    }
                case .jsonParsing:
                    if attempt < maxRetry {
                        print("⚠️ JSON 파싱 실패 — 재시도 중 (\(attempt)/\(maxRetry))")
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        continue
                    } else {
                        print("❌ JSON 파싱 실패 — Gemini 출력 형식 확인 필요")
                        return nil
                    }
                case .unknown:
                    print("❓ 알 수 없는 오류 발생: \(error.localizedDescription)")
                    return nil
                }
            }
        }
        return nil
    }
}

