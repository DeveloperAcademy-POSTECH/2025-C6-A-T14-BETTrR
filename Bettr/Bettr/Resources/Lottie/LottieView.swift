//
//  LottieView.swift
//  Bettr
//
//  Created by 길정수 on 11/21/25.
//

import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    
    // JSON 파일 이름 (확장자 제외)
    let name: String
    // 루프 모드 설정 (기본: .loop)
    var loopMode: LottieLoopMode = .loop

    // Lottie 애니메이션 뷰 생성 (UIKit)
    func makeUIView(context: UIViewRepresentableContext<LottieView>) -> UIView {
        let view = UIView(frame: .zero)
        
        // LottieAnimationView 객체 생성 및 설정
        let animationView = LottieAnimationView(name: name)
        animationView.contentMode = .scaleAspectFit // 애니메이션 크기 조정 방식
        animationView.loopMode = loopMode // 루프 모드 적용
        
        // UIKit 뷰 계층 구조 설정
        animationView.translatesAutoresizingMaskIntoConstraints = false // Auto Layout 사용 설정
        view.addSubview(animationView)
        
        // Auto Layout을 사용하여 Lottie 뷰를 부모 뷰에 꽉 채우도록 설정
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        // 애니메이션 재생 시작
        animationView.play()
        
        return view
    }

    // 뷰 업데이트 (여기서는 애니메이션 뷰를 업데이트할 필요가 없으므로 비워둡니다)
    func updateUIView(_ uiView: UIViewType, context: UIViewRepresentableContext<LottieView>) {
        // 이 함수를 사용하여 애니메이션 상태를 코드에서 변경할 수 있습니다 (선택 사항)
    }
}
