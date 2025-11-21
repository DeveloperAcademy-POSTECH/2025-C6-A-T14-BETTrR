//
//  LottieView.swift
//  Bettr
//
//  Created by 길정수 on 11/21/25.
//

import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    
    let name: String
    var loopMode: LottieLoopMode = .loop
        var animationSpeed: CGFloat = 1.0
        var isAnimating: Bool = true
    
    class Coordinator: NSObject {
            var animationView: LottieAnimationView?
        }

        func makeCoordinator() -> Coordinator {
            Coordinator()
        }
    
    func makeUIView(context: Context) -> UIView {
            let view = UIView(frame: .zero)
            let animationView = LottieAnimationView(name: name)
            
            context.coordinator.animationView = animationView

            animationView.contentMode = .scaleAspectFit
            animationView.loopMode = loopMode
            animationView.animationSpeed = animationSpeed

            animationView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(animationView)

            NSLayoutConstraint.activate([
                animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
                animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
            ])
            
            if isAnimating {
                animationView.play()
            } else {
                animationView.pause()
            }
            
            return view
        }

        func updateUIView(_ uiView: UIView, context: Context) {
            // 속도 업데이트
            context.coordinator.animationView?.animationSpeed = animationSpeed
            
            // 재생 상태 업데이트
            if isAnimating {
                if !(context.coordinator.animationView?.isAnimationPlaying ?? false) {
                    context.coordinator.animationView?.play()
                }
            } else {
                context.coordinator.animationView?.pause()
            }
        }
    }
