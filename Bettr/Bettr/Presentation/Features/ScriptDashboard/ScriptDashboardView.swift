//
//  ScriptDashboardView.swift
//  Bettr
//
//  Created by 길정수 on 11/4/25.
//

import SwiftUI

struct ScriptDashboardView: View {
    @State var viewModel: ScriptDashboardViewModel
    @State private var isTitleEditing: Bool = false
    
    init(viewModel: ScriptDashboardViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        Group {
            if viewModel.scriptDashboardData != nil {
                
                Grid(horizontalSpacing: 16, verticalSpacing: 16) {
                    GridRow {
                        ScriptDashboardTopLeftContents(feedbacks: viewModel.scriptDashboardData!.recentFeedbacks)
                        
                        ScriptDashboardTopRightContents(
                            feedbackCount: viewModel.scriptDashboardData!.feedbackCount,
                            top3IncorrectWords: viewModel.scriptDashboardData!.top3IncorrectWords,
                            averagePracticeDuration: viewModel.scriptDashboardData!.averagePracticeDuration,
                            recentFeedbackCount: viewModel.scriptDashboardData!.recentFeedbackCount
                        )
                    }
                    
                    GridRow {
                        ScriptDashboardBottomLeftContents(
                            recentFeedbacks: viewModel.scriptDashboardData!.recentFeedbacks,
                            allFeedbacks: viewModel.scriptDashboardData!.allFeedbacks
                        )
                        
                        ScriptDashboardBottomRightContents(
                            scriptId: viewModel.scriptId,
                            sentences: viewModel.scriptDashboardData!.sentences
                        )
                    }
                }
            } else {
                // 로딩, 에러 뷰
                LoadingView(
                    isLoading: viewModel.isLoading,
                    errorMessage: viewModel.errorMessage
                )
            }
        }
        .padding(.horizontal, 84)
        .padding(.top, 36)
        .padding(.bottom, 48)
        .frame(maxWidth: .infinity)
        .onTapGesture {
            isTitleEditing = false
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                EditableTitleView(
                    title: $viewModel.currentTitle,
                    showEditIcon: true,
                    isEditing: $isTitleEditing
                )
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}
