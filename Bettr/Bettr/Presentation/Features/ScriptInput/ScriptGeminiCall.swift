//
//  ScriptGeminiCall.swift
//  Bettr
//
//  Created by 서세린 on 11/5/25.
//

import SwiftUI
import FirebaseAI

extension ScriptInputView {
    // MARK: - 저장 + AI 호출 (에러 분류 및 재시도 추가)
    func callGemini() async {
        // 편집 모드일 때는 호출을 막음 (안전장치)
        if isEditing {
            print("편집 중에는 Gemini 호출이 비활성화되어 있습니다.")
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let maxRetry = 2 // 공식문서 참조 두 번 이하 재시도

        //모델 초기화는 루프 밖에서 진행.
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let model = ai.generativeModel(modelName: "gemini-2.5-flash-lite")
        
        for attempt in 1...maxRetry {
            do {
                // 🧪 [테스트용] 강제로 에러 시뮬레이션
                // 필요할 때 주석 해제해서 각 케이스를 테스트하세요.
                
                //throw NSError(domain: "FIRGenerativeAI", code: 400, userInfo: [NSLocalizedDescriptionKey: "INVALID_ARGUMENT: input too long"])   // clientInput
                // throw NSError(domain: "FIRGenerativeAI", code: 401, userInfo: [NSLocalizedDescriptionKey: "PERMISSION_DENIED: missing auth"])   // auth
                // throw NSError(domain: "FIRGenerativeAI", code: 429, userInfo: [NSLocalizedDescriptionKey: "RESOURCE_EXHAUSTED: quota exceeded"]) // rateLimited
                // throw NSError(domain: "FIRGenerativeAI", code: 503, userInfo: [NSLocalizedDescriptionKey: "UNAVAILABLE: service temporarily down"]) // transient
                // throw URLError(.timedOut) // transient (timeout)
                // throw URLError(.cannotParseResponse) // jsonParsing
                // throw URLError(.badServerResponse) // emptyResponse
                // throw NSError(domain: "Test", code: 999, userInfo: [NSLocalizedDescriptionKey: "Something weird happened"]) // unknown
                
                // ⚠️ 실제 실행할 때는 위 줄을 모두 주석 처리하세요.
                // 새로운 JSON 전용 프롬프트 추가
                let prompt = """
                           당신은 20년 경력의 영어-한국어 언어 코치입니다.

                           # 목표
                           입력된 영어 스크립트를 문장 단위로 분할하고, 각 문장을 의미 단위 청크로 나눈 뒤 1:1로 한국어 번역을 정렬합니다.
                           또한 각 문장의 자연스러운 전체 번역을 생성합니다.

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

                           # 입력 스크립트
                           \(inputscriptText)
                           """
                
                let response = try await model.generateContent(prompt)
                guard let text = response.text else {
//                    print("⚠️ 응답 없음")
//                    return
                    throw URLError(.badServerResponse) // 에러 전달
                }

                print("Gemini 응답:\n\(text)")
                
                //    ↓ JSON 디코딩 전용 함수로 교체
                if let jsonParsed = parseGeminiJSONToScriptData(text, fallbackTitle: "사용자 입력 스크립트") {
                    await MainActor.run { self.parsedScript = jsonParsed }
                    print("✅ JSON 파싱 성공: \(jsonParsed.sentences.count)문장")
                    
                    // Oliver's "스크립트 자동 저장" 기능
                    do {
                        let script = try databaseContainer.scriptManagementService.createScript(scriptData: jsonParsed)
                        print("✅ 스크립트가 성공적으로 저장되었습니다.")
                        
                        if let scriptId = script.id {
                            try await databaseContainer.wordExtractionService.extractAndSaveWords(for: scriptId)
                        }
                        
                    } catch {
                        print("🔥 스크립트 저장 오류:", error.localizedDescription)
                    }
                    
                    return
                } else {
                    throw URLError(.cannotParseResponse)
                }
                    
//                } else {
//                    print("⚠️ JSON 디코딩 실패")
//                }
            } catch {
                //                print("🔥 FirebaseAI 오류:", error.localizedDescription)
                // ✅ [개선] 에러 상세 정보 로깅 추가
                print("🔥 에러 발생 (시도 \(attempt)/\(maxRetry)): \(error)")
                print("   - 타입: \(type(of: error))")
                print("   - 설명: \(error.localizedDescription)")
                
                // ✅ [개선] NSError로 변환하여 상세 정보 확인
                let nsError = error as NSError
                print("   - Domain: \(nsError.domain)")
                print("   - Code: \(nsError.code)")
                print("   - UserInfo: \(nsError.userInfo)")
                
                let category = classifyGeminiCallError(error)
                // ✅ [추가] 분류 결과 로깅
                print("   - 분류 결과: \(category)")
                
                switch category {
                case .clientInput:
                    // ✅ [개선] 더 구체적인 메시지로 변경
                    await MainActor.run {
                        showErrorAlert("입력 내용에 문제가 있습니다.\n\n 특수문자나 형식이 올바른지 확인해주세요")
                    }
                    return
                    
                case .auth:
                    // ✅ [개선] 인증 문제 상세화
                    await MainActor.run {
                        showErrorAlert("API 인증에 문제가 발생했습니다.\n\n앱을 재시작하거나 네트워크 연결을 확인해주세요.")
                    }
                    return
                    
                case .rateLimited:
                    // ✅ [개선] Rate Limit 안내 강화
                    await MainActor.run {
                        showErrorAlert("API 사용 한도를 초과했습니다.\n\n1분 후 다시 시도해주세요.")
                    }
                    return
                    
                case .transient:
                    if attempt < maxRetry {
                        let delay = pow(2.0, Double(attempt - 1))
                        print("⏳ 일시적 오류 — \(delay)s 후 재시도 (\(attempt)/\(maxRetry))")
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    } else {
                        // ✅ [개선] 재시도 실패 시 더 명확한 메시지
                        await MainActor.run {
                            showErrorAlert("서버 연결이 불안정합니다.\n\n네트워크 상태를 확인하고\n잠시 후 다시 시도해주세요.")
                        }
                        return
                    }
                    
                case .jsonParsing:
                    // ✅ [추가] JSON 파싱 전용 에러 처리 (Gemini가 가끔 형식 실수 - 재시도 가치 있음) - 에러 확인 성공.
                    if attempt < maxRetry {
                        print("⚠️ JSON 파싱 실패 - 재시도 (\(attempt)/\(maxRetry))")
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        continue
                    } else {
                        await MainActor.run {
                            showErrorAlert("AI 응답을 처리할 수 없습니다.\n\n다시 시도해주세요.")
                        }
                        return
                    }
                    
                case .unknown:
                    // ✅ [수정] unknown은 원인 불명이므로 재시도해도 소용없음 - 즉시 중단
                    await MainActor.run {
                        showErrorAlert("예기치 못한 오류가 발생했습니다.\n\n문제가 지속되면 다시시도해주세요.")
                    }
                    return
                }
            }
        }
    }
}
