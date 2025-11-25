//
//  RecordingButtonGroup.swift
//  Bettr
//
//  Created by 길정수 on 11/24/25.
//

import SwiftUI

struct RecordingButtonGroup: View {
    var viewModel: RecordingViewModel
    
    let onSaveAction: () -> Void
    
    var body: some View {
        HStack(spacing: 30) {
            // 왼쪽 버튼: 재설정
            Button(action: { viewModel.cancelRecording() }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(ResetButtonStyle())
            .disabled(!viewModel.didFinishRecording)
            
            Spacer()
            
            // 가운데 버튼: 녹음 시작/정지
            Button(action: { viewModel.toggleRecording() }) {
                Image(systemName: viewModel.isReadyToRecord ? "microphone" : "stop.fill")
            }
            .buttonStyle(RecordToggleButtonStyle(isRecording: viewModel.isRecording))
            .disabled(viewModel.didFinishRecording)
            
            Spacer()
            
            // 오른쪽 버튼: 다음(분석) 버튼
            Button(action: onSaveAction) {
                Image(systemName: "arrow.right")
            }
            .buttonStyle(NextStepButtonStyle())
            .disabled(!viewModel.didFinishRecording)
        }
        .padding(.horizontal, 48)
    }
}
