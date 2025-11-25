//
//  FeedbackHistoryView.swift
//  Bettr
//
//  Created by 길정수 on 11/20/25.
//

import SwiftUI
import Charts

struct FeedbackHistoryView: View {
    
    @Environment(DatabaseContainer.self) private var container
    @Environment(NavigationRouter.self) private var modalRouter
    @Environment(\.dismiss) var modalDismiss
    
    @State var viewModel: FeedbackHistoryViewModel
    
    var body: some View {
        
        @Bindable var modalRouter = modalRouter
        
        NavigationStack(path: $modalRouter.path) {
            Group {
                if viewModel.isLoading { // 로딩
                    ProgressView()
                } else if let error = viewModel.currentError { // 에러
                    ErrorView(error: error) {
                        Task { // 다시 시도
                            viewModel.retryLoadData()
                        }
                    }
                } else if viewModel.feedbackHistoryData != nil { // 성공
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 16) {
                            FeedbackStatisticsCard(viewModel: viewModel, layoutMode: .full)
                                .frame(maxWidth: 474)
                            FeedbackHistoryCard(viewModel: viewModel)
                        }
                        .safeAreaPadding(.horizontal, 84)
                        
                        VStack(spacing: 16) {
                            FeedbackStatisticsCard(viewModel: viewModel, layoutMode: .compact)
                            FeedbackHistoryCard(viewModel: viewModel)
                        }
                        .safeAreaPadding(.horizontal, 84)
                    }
                } else { // 예외 케이스: 로딩도 아니고, 에러도 아닌데, 데이터도 없는 경우
                    ErrorView(error: .unknown("데이터를 불러오지 못했습니다.")) {
                        Task {
                            viewModel.retryLoadData()
                        }
                    }
                }
            }
            .safeAreaPadding(.top, 24)
            .safeAreaPadding(.bottom, 48)
            .environment(\.modalDismiss, modalDismiss)
            .navigationBarTitleDisplayMode(.inline)
            .cancelToolbar(isXmark: true)
            .onAppear {
                viewModel.onAppear()
            }
            .navigationDestination(for: ModalRoute.self) { route in
                navigationDestinationView(route)
            }
        }
    }
    
    @ViewBuilder
    private func navigationDestinationView(_ route: ModalRoute) -> some View {
        switch route {
        case .recording(let scriptId, let scriptTitle, let sentences):
            let recordingViewModel = RecordingViewModel(
                sentences: sentences,
                scriptManagementService: container.scriptManagementService
            )
            
            RecordingView(
                scriptId: scriptId,
                scriptTitle: scriptTitle,
                viewModel: recordingViewModel
            )
            
        case .feedbackResult(let summaryId, let fromRecording):
            let feedbackResultViewModel = FeedbackResultViewModel(
                scriptId: viewModel.scriptId,
                summaryId: summaryId,
                scriptManagementService: container.scriptManagementService
            )
            
            FeedbackResultView(viewModel: feedbackResultViewModel)
                .environment(\.modalDismiss, fromRecording ? modalDismiss : nil)
        }
    }
}
