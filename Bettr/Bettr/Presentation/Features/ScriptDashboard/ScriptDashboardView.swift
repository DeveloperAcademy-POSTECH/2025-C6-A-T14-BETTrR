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
    
    @ScaledMetric(relativeTo: .body) var horizontalPadding: CGFloat = 84
    @ScaledMetric(relativeTo: .body) var topPadding: CGFloat = 36
    @ScaledMetric(relativeTo: .body) var bottomPadding: CGFloat = 48
    
    init(viewModel: ScriptDashboardViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        Group {
            if viewModel.scriptDashboardData != nil {
                
                Grid(alignment: .top, horizontalSpacing: 16, verticalSpacing: 16) {
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
                LoadingView(
                    isLoading: viewModel.isLoading,
                    errorMessage: viewModel.errorMessage
                )
            }
        }
        .border(Color.blue)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, horizontalPadding)
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
        .border(Color.red)
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
