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
                ScrollView {
                    VStack(spacing: 36) {
                        HStack(alignment: .top, spacing: 32) {
                            ScriptDashboardTopLeftContents(feedbacks: viewModel.scriptDashboardData!.recentFeedbacks)
                            
                            ScriptDashboardTopRightContents(
                                feedbackCount: viewModel.scriptDashboardData!.feedbackCount,
                                top3IncorrectWords: viewModel.scriptDashboardData!.top3IncorrectWords,
                                averagePracticeDuration: viewModel.scriptDashboardData!.averagePracticeDuration,
                                recentFeedbackCount: viewModel.scriptDashboardData!.recentFeedbackCount
                            )
                        }
                        .frame(maxHeight: 272)
                        
                        HStack(alignment: .top, spacing: 32) {
                            ScriptDashboardBottomLeftContents(
                                recentFeedbacks: viewModel.scriptDashboardData!.recentFeedbacks,
                                allFeedbacks: viewModel.scriptDashboardData!.allFeedbacks,
                                scriptTitle: viewModel.currentTitle,
                                feedbackNumber: viewModel.scriptDashboardData!.feedbackCount
                            )
                            
                            ScriptDashboardBottomRightContents(
                                scriptId: viewModel.scriptId,
                                sentences: viewModel.scriptDashboardData!.sentences,
                                scriptTitle: viewModel.currentTitle,
                                currentFeedbackNumber: viewModel.scriptDashboardData!.feedbackCount
                            )
                        }
                        .frame(maxHeight: 546)
                    }
                }
            } else {
                LoadingView(
                    isLoading: viewModel.isLoading,
                    errorMessage: viewModel.errorMessage
                )
            }
        }
        .safeAreaPadding(.horizontal, 84)
        .safeAreaPadding(.top, 36)
        .safeAreaPadding(.bottom, 48)
        .onTapGesture {
            isTitleEditing = false
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                EditableTitle(
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
