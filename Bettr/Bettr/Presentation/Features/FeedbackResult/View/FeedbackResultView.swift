//
//  FeedbackResultView.swift
//  Bettr
//
//  Created by 길정수 on 10/30/25.
//
import Foundation
import SwiftUI

// MARK: - 피드백 결과 뷰 (ViewModel 사용)
struct FeedbackResultView: View {
    
    @State private var viewModel: FeedbackViewModel
    
    init(viewModel: FeedbackViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        // viewModel.feedbackResult가 nil일 경우(ex. 분석 실패)를 대비
        guard let feedback = viewModel.feedbackResult else {
            return AnyView(
                VStack {
                    Text("오류")
                        .font(.largeTitle)
                    Text("피드백 결과를 불러오는 데 실패했습니다.")
                        .foregroundColor(.secondary)
                }
            )
        }
        
        return AnyView(
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("📊 피드백 결과")
                        .font(.largeTitle).bold()
                        .padding(.bottom, 10)
                    
                    Text("전체 정확도: \(Int(feedback.accuracy * 100))%")
                        .font(.title)
                        .foregroundColor(.blue)
                        .bold()
                    
                    Text("총 녹음 시간: \(feedback.totalRecordingTime.toMMSSms())")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 5)
                    
                    HStack(spacing: 12) {
                        Text("오류 분석:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("누락: \(viewModel.missingCount)개")
                            .font(.callout.bold())
                            .foregroundColor(.green)
                        
                        Text("추가: \(viewModel.extraCount)개")
                            .font(.callout.bold())
                            .foregroundColor(.red)
                        
                        Text("대체: \(viewModel.replacedCount)개")
                            .font(.callout.bold())
                            .foregroundColor(.blue)
                        
                        Spacer()
                    }
                    .padding(.bottom, 5)
                    
                    Divider()
                    
                    if viewModel.sentenceDiffs.isEmpty {
                        Text("분석 결과가 없습니다.")
                            .foregroundColor(.gray)
                        
                    } else if viewModel.filteredSentenceDiffs.isEmpty {
                        VStack(alignment: .center, spacing: 10) {
                            Text("🎉 완벽합니다!")
                                .font(.title.bold())
                                .foregroundColor(.green)
                            Text("틀린 문장이 하나도 없습니다.")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        
                    } else {
                        ForEach(viewModel.filteredSentenceDiffs, id: \.index) { (originalIndex, sentenceData) in
                            
                            // (1) 원본 문장
                            VStack(alignment: .leading, spacing: 8) {
                                Text("영어 원문 \(originalIndex + 1)")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text(sentenceData.original)
                                    .font(.title3)
                                    .bold()
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            
                            // (2) 사용자 발화 (하이라이트)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("내 발음 \(originalIndex + 1)")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                
                                buildHighlightText(from: sentenceData.diffs)
                                    .font(.title3)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(6)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray5))
                            .cornerRadius(10)
                            
                            if originalIndex != viewModel.filteredSentenceDiffs.last?.index {
                                Divider()
                                    .padding(.vertical, 10)
                            }
                        }
                    }
                }
                .padding()
            }
                .navigationBarBackButtonHidden()
                .cancelToolbar()
                .navigationTitle("분석 결과")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    Task {
                        await viewModel.saveFeedbackResult()
                    }
                }
        )
    }
    
    /// WordDiff 배열을 하이라이트된 SwiftUI Text로 변환하는 헬퍼 함수
    func buildHighlightText(from diffs: [WordDiff]) -> Text {
        if diffs.isEmpty {
            return Text("(발화 내용 없음)")
                .foregroundStyle(.gray)
        } else {
            var components: [Text] = []
            
            for diff in diffs {
                switch diff {
                case .matched(let word):
                    components.append(Text(word)
                        .foregroundColor(.primary))
                    
                case .missing(let expected):
                    components.append(Text(expected)
                        .foregroundColor(.green)
                        .strikethrough(true, color: .green))
                    
                case .extra(let actual):
                    components.append(Text(actual)
                        .foregroundColor(.red))
                    
                case .replaced(let expected, let actual):
                    components.append(Text(expected)
                        .foregroundColor(.gray)
                        .strikethrough(true, color: .gray))
                    components.append(Text(actual)
                        .foregroundColor(.blue))
                }
            }
            
            // 1. `components` 배열에 첫 번째 요소가 있는지 확인합니다.
            guard let first = components.first else {
                // `diffs`가 비어있지 않다면 `components`도 비어있지 않아야 하지만,
                // 만약의 경우를 대비해 빈 Text를 반환합니다.
                return Text("")
            }
            
            // 2. `reduce`를 사용해 배열의 나머지 요소를 첫 번째 요소에 합칩니다.
            //    `result`는 누적된 Text, `component`는 새로 더해질 Text입니다.
            return components.dropFirst().reduce(first) { result, component in
                Text("\(result) \(component)")
            }
        }
    }
}
