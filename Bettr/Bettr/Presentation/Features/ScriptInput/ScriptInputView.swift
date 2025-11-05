//
//  ScriptInputView.swift
//  Bettr
//
//  Created by 서세린 on 10/28/25.
//

import SwiftUI
import FirebaseAI

// MARK: - 화면 UI
struct ScriptInputView: View {
    @Environment(DatabaseContainer.self) var databaseContainer

    @State private var scriptText: String = """
    Hello everyone, my name is Dewy.
    Today, I want to talk about the power of challenge.
    I used to be afraid of speaking English in front of others.
    But my teacher told me, “Mistakes are part of learning.”
    So I decided to join the English speech contest.
    At first, I was really nervous, but I didn’t give up.
    When I finished, I felt proud of myself.
    That experience taught me to be brave.
    Now I know every challenge helps me grow.
    Thank you for listening.
    """
    @State private var isLoading: Bool = false              // FirebaseAI 호출 중 로딩 상태
    @State private var isEditing: Bool = false
    @FocusState private var editorFocused: Bool

    @State private var parsedScript: ScriptData?     // Gemini 분석 후 결과 저장(추가)
    @State private var showErrorAlert: Bool = false         // 🆕 추가: 사용자 에러 알림
    @State private var errorMessage: String = ""            // 🆕 추가: Alert에 표시될 메시지
    
    init(initialText: String? = nil) {
        _scriptText = State(initialValue: initialText ?? """
    Hello everyone, my name is Dewy.
    Today, I want to talk about the power of challenge.
    I used to be afraid of speaking English in front of others.
    But my teacher told me, “Mistakes are part of learning.”
    So I decided to join the English speech contest.
    At first, I was really nervous, but I didn’t give up.
    When I finished, I felt proud of myself.
    That experience taught me to be brave.
    Now I know every challenge helps me grow.
    Thank you for listening.
    """)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack{
                Text("영어 스크립트를 입력하세요")
                    .font(.headline)
                Button(action: {
                    // 편집 모드 토글
                    withAnimation {
                        isEditing.toggle()
                        // 편집 모드 전환 시 포커스 제어
                        editorFocused = isEditing
                    }
                }) {
                    Text(isEditing ? "편집 완료" : "편집")
                        .bold()
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .frame(minWidth: 90)
                        .background(isEditing ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(isEditing ? .white : .primary)
                        .cornerRadius(8)
                }
                // 편집 중이면 간단 안내 텍스트
                if isEditing {
                    Text("편집 중..")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            
            // 텍스트 입력창 (편집 비허용 상태에서는 disabled)
            ScrollView {
                TextEditor(text: $scriptText)
                    .focused($editorFocused)
                    .disabled(!isEditing)
                    .padding(4) // Add some inner padding for the text
                    .background(isEditing ? Color.yellow.opacity(0.08) : Color.clear)
            }
            .frame(height: 300)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.5))
            )
            .padding(.horizontal)
            .opacity(isEditing ? 1.0 : 0.95)
            
            // Gemini 호출 버튼
            Button(action: {
                Task {
                    await callGemini()
                }
            }) {
                if isLoading {
                    ProgressView("Gemini가 분석 중...")
                        .tint(.white)
                } else {
                    Text("Gemini에게 분석 요청")
                        .bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            (isEditing || isLoading || scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            ? Color.gray
                            : Color.blue
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .disabled(scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading || isEditing)
            .padding(.horizontal)
            
            // 결과 표시 (파싱 버전 삽입용)
            if let script = parsedScript {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(script.sentences, id: \.orderIndex) { sentence in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("🗣️ Sentence \(sentence.orderIndex + 1)")
                                    .font(.headline)
                                
                                GroupBox(label: Text("영문 문장")) {
                                    Text(sentence.englishText)
                                }
                                GroupBox(label: Text("자연스러운 번역")) {
                                    Text(sentence.koreanText)
                                }
                                
                                GroupBox(label: Text("청크 매칭")) {
                                    ForEach(sentence.chunks, id: \.orderIndex) { chunk in
                                        VStack(alignment: .leading) {
                                            Text("EN: \(chunk.englishText)")
                                            Text("KR: \(chunk.koreanText)")
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            } else {
                Text("아직 분석 결과가 없습니다.")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        // 🆕 Alert 추가
        .alert("오류", isPresented: $showErrorAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
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
                           \(scriptText)
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
    // MARK: - 사용자 알림 (UI Thread 전환)
    @MainActor
    func showErrorAlert(_ message: String) {
        self.errorMessage = message
        self.showErrorAlert = true
    }
}

// MARK: - 에러 분류기 (FirebaseAI / Vertex 기준)
enum GeminiErrorCategory {
    case clientInput    // 400~422 → 입력 오류
    case transient      // 408, 500, 502, 503, timeout → 서버 불안정
    case auth           // 인증오류
    case rateLimited    // 무료 버전 분당 호출 제한.
    case jsonParsing    // ✅ [추가] JSON 파싱 실패
    case unknown
}

func classifyGeminiCallError(_ error: Error) -> GeminiErrorCategory {
    let nsError = error as NSError
    let code = nsError.code
    let domain = nsError.domain
    
    // ✅ [개선] 에러 메시지를 소문자로 변환하여 검사
    let msg = error.localizedDescription.lowercased()
    
    // ✅ [추가] URLError 타입별 분류 (JSON 파싱, 빈 응답 등)
    if let urlError = error as? URLError {
        switch urlError.code {
        case .cannotParseResponse:
            return .jsonParsing
        case .timedOut, .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet:
            return .transient
        default:
            break
        }
    }
    
    // ✅ [개선] Firebase/Vertex 표준 gRPC 상태 코드 검사 (대소문자 무관)
    if msg.contains("invalid_argument") || msg.contains("invalid argument") {
        return .clientInput
    }
    if msg.contains("failed_precondition") || msg.contains("failed precondition") {
        return .clientInput
    }
    if msg.contains("permission_denied") || msg.contains("permission denied") {
        return .auth
    }
    if msg.contains("unauthenticated") {
        return .auth
    }
    if msg.contains("not_found") || msg.contains("not found") {
        return .clientInput
    }
    if msg.contains("resource_exhausted") || msg.contains("resource exhausted") || msg.contains("quota") {
        return .rateLimited
    }
    if msg.contains("unavailable") || msg.contains("deadline_exceeded") || msg.contains("deadline exceeded") {
        return .transient
    }
    if msg.contains("cancelled") {
        return .transient
    }
    
    // ✅ [개선] HTTP 상태 코드 기반 분류 (더 세밀하게)
    if (400...403).contains(code) { return .clientInput }
    if code == 404 { return .clientInput }
    if code == 413 || code == 414 { return .clientInput } // Payload Too Large
    if code == 429 { return .rateLimited }
    if code == 408 { return .transient } // Request Timeout
    if (500...504).contains(code) { return .transient }
    
    // ✅ [개선] Firebase SDK 특정 도메인 검사
    if domain.contains("FIRGenerativeAI") || domain.contains("Firebase") {
        // ✅ [추가] Firebase 에러 코드 범위별 분류
        if (1...99).contains(code) { return .clientInput }
        if (100...199).contains(code) { return .auth }
        if code == 429 { return .rateLimited }
        if (500...599).contains(code) { return .transient }
    }
    
    // ✅ [개선] 메시지 내용 기반 추가 분류
    if msg.contains("timeout") || msg.contains("timed out") {
        return .transient
    }
    if msg.contains("network") || msg.contains("connection") {
        return .transient
    }
    if msg.contains("too large") || msg.contains("too long") {
        return .clientInput
    }
    if msg.contains("rate") || msg.contains("limit") {
        return .rateLimited
    }
    if msg.contains("invalid") || msg.contains("malformed") {
        return .clientInput
    }
    
    // ✅ [개선] 마지막 resort로 unknown 반환 (이제 재시도 로직 포함)
    return .unknown
}

// MARK: - Gemini가 생성한 json 처리로직
// JSON 응답을 Swift 구조체로 매핑하는 함수
// 기존의 'parseGeminiOutputToScriptData' 대신 새롭게 추가됨
func parseGeminiJSONToScriptData(_ jsonText: String, fallbackTitle: String) -> ScriptData? {
    // 코드펜스 제거 (Gemini가 ```json 으로 감싸는 경우 대비)
    let trimmed = jsonText
//        .replacingOccurrences(of: "```json", with: "")
//        .replacingOccurrences(of: "```", with: "")
        .replacingOccurrences(of: "```json", with: "")
        .replacingOccurrences(of: "```", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    
    guard let data = trimmed.data(using: .utf8) else { return nil }
    
    do {
        // Gemini가 orderIndex를 주므로, 별도 enumerated() 보정 불필요
        let decoded = try JSONDecoder().decode(ScriptData.self, from: data)

        // title이 비어 있을 경우 대비
        let finalTitle = decoded.title.isEmpty ? fallbackTitle : decoded.title

        // 그대로 반환 (orderIndex는 Gemini가 부여한 값 사용)
        return ScriptData(title: finalTitle, sentences: decoded.sentences)
        
    } catch {
        print("⚠️ JSON 디코딩 실패: \(error)")
        return nil
    }
}

#Preview {
    ScriptInputView(initialText: nil)
        .environment(DatabaseContainer.getForPreview())
        .environment(NavigationRouter())
}
