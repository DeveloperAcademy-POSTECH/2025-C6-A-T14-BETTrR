//
//  MemorizationToolbar.swift
//  Bettr
//
//  Created by 길정수 on 10/29/25.
//

import SwiftUI

enum FunctionMode {
    case hide   // 가리기
    case read   // 재생
}

struct MemorizationToolbar: ToolbarContent {
    
    @Bindable var viewModel: MemorizationViewModel
    let showEditIcon: Bool
    
    @Namespace private var modeAnimation
    
    var body: some ToolbarContent {
        // 타이틀
        ToolbarItem(placement: .principal) {
            EditableTitle(
                title: $viewModel.currentTitle,
                showEditIcon: showEditIcon,
                isEditing: $viewModel.uiState.isTitleEditing
            )
        }
        
        topToolbarItems
        
        bottomToolbarItems
    }
    
    
    @ToolbarContentBuilder
    private var topToolbarItems: some ToolbarContent {
        // 청크 모드
        ToolbarItem {
            Button(action: {
                viewModel.toggleChunkMode()
            }) {
                Image(systemName: viewModel.uiState.isChunkMode ? "text.word.spacing": "text.justify")
                    .toolbarButtonStyle(emphasized: viewModel.uiState.isChunkMode)
            }
        }
        
        ToolbarSpacer(.flexible)
        
        // 기능 모드 (Hide/Read)
        ToolbarItemGroup {
            Button(action: {
                viewModel.setFunctionMode(.hide)
            }) {
                Image(systemName: "eye.slash")
                    .toolbarButtonStyle(enabled: viewModel.uiState.funcMode == .hide)
            }
            
            Button(action: {
                if viewModel.isReadModeDisabled {
                        viewModel.showToaster(message: "전체 재생 중에는 탭하여 재생하기를 사용할 수 없습니다")
                } else {
                    viewModel.setFunctionMode(.read)
                }
            }) {
                Image(systemName: "speaker.wave.2")
                    .toolbarButtonStyle(enabled: viewModel.uiState.funcMode == .read)
            }
        }
        
        ToolbarSpacer(.flexible)
        
        // 한국어 토글
        ToolbarItem {
            Button(action: {
                viewModel.toggleKoreanVisibility()
            }) {
                Text("한")
                    .toolbarButtonStyle(emphasized: viewModel.uiState.isKoreanVisible)
            }
        }
        
        ToolbarSpacer(.flexible)
        
        // 단어장
        ToolbarItem {
            Button(action: {
                viewModel.uiState.showWordList.toggle()
            }) {
                Image(systemName: "character.book.closed")
                    .toolbarButtonStyle(emphasized: viewModel.uiState.showWordList)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var bottomToolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            // 왼쪽 버튼 (재생/일시정지/정지)
            playbackControls
            
            Spacer()
            
            // 오른쪽 버튼 (피드백)
            feedbackButton
        }
    }
    
    @ViewBuilder
    private var playbackControls: some View {
        if viewModel.uiState.isAudioPlaybackActive {
            ControlGroup {
                Button(action: {
                    viewModel.togglePauseResume()
                }) {
                    Image(systemName: viewModel.uiState.isPause ? "play.fill" : "pause.fill")
                        .foregroundStyle(.secondaryBlue700)
                }
                
                Button(action: {
                    viewModel.togglePlayStop()
                }) {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(.secondaryBlue700)
                }
            }
        } else {
            Button(action: {
                viewModel.togglePlayStop()
            }) {
                Image(systemName: "play.fill")
                    .toolbarButtonStyle(enabled: !viewModel.isFullPlayDisabled)
            }
            .disabled(viewModel.isFullPlayDisabled)
        }
    }
    
    private var feedbackButton: some View {
        Button(action: {
            viewModel.uiState.showFeedbackModal.toggle()
        }) {
            Image(systemName: "chart.line.text.clipboard")
                .toolbarButtonStyle(enabled: !viewModel.isRecordingDisabled)
        }
        .disabled(viewModel.isRecordingDisabled)
    }
}
