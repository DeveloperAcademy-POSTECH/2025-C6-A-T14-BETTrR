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
                        .cornerRadius(10)                        .foregroundColor(.white)
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
    }
    
    // MARK: - 저장 + AI 호출
    func callGemini() async {
        // 편집 모드일 때는 호출을 막음 (안전장치)
        if isEditing {
            print("편집 중에는 Gemini 호출이 비활성화되어 있습니다.")
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let ai = FirebaseAI.firebaseAI(backend: .googleAI())
            let model = ai.generativeModel(modelName: "gemini-2.5-flash-lite")
            
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
                print("⚠️ 응답 없음")
                return
            }

            print("Gemini 응답:\n\(text)")
            
            //    ↓ JSON 디코딩 전용 함수로 교체
            if let jsonParsed = parseGeminiJSONToScriptData(text, fallbackTitle: "사용자 입력 스크립트") {
                await MainActor.run { self.parsedScript = jsonParsed }
                print("✅ JSON 파싱 성공: \(jsonParsed.sentences.count)문장")
                
                // Oliver's "스크립트 자동 저장" 기능
                do {
                    _ = try databaseContainer.scriptManagementService.createScript(scriptData: jsonParsed)
                    print("✅ 스크립트가 성공적으로 저장되었습니다.")
                } catch {
                    print("🔥 스크립트 저장 오류:", error.localizedDescription)
                }
                
            } else {
                print("⚠️ JSON 디코딩 실패")
            }

//<<<<<<< HEAD
//=======
//            print("✅ 총 문장 수: \(parsed.sentences.count)")
//
//            // ✅ 스크립트 저장
//            do {
//                _ = try databaseContainer.scriptManagementService.createScript(scriptData: parsed)
//                print("✅ 스크립트가 성공적으로 저장되었습니다.")
//            } catch {
//                print("🔥 스크립트 저장 오류:", error.localizedDescription)
//            }
//
//>>>>>>> dev
        } catch {
            print("🔥 FirebaseAI 오류:", error.localizedDescription)
        }
    }
}

// MARK: - Gemini가 생성한 json 처리로직
// JSON 응답을 Swift 구조체로 매핑하는 함수
// 기존의 'parseGeminiOutputToScriptData' 대신 새롭게 추가됨
func parseGeminiJSONToScriptData(_ jsonText: String, fallbackTitle: String) -> ScriptData? {
    // 코드펜스 제거 (Gemini가 ```json 으로 감싸는 경우 대비)
    let trimmed = jsonText
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
