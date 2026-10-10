//
//  BettrApp.swift
//  Bettr
//
//  Created by 서세린 on 10/28/25.
//

import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    private let firebaseBootstrap = FirebaseBootstrap()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 테스트 호스트로 실행될 때는 Firebase를 초기화하지 않는다.
        // GoogleService-Info.plist 없이도 Unit/DatabaseIntegration 테스트가 실행되어야 하며,
        // 실제 Gemini 호출 테스트(GeminiContract)는 테스트 쪽에서 직접 초기화한다.
        if !AppLaunchContext.usesIsolatedDependencies {
            firebaseBootstrap.configure()
        }
        return true
    }
}

@main
struct BettrApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    private let composition: AppComposition
    
    init() {
        do {
            composition = try AppLaunchContext.makeComposition()
        } catch {
            fatalError("Failed to initialize isolated app dependencies")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(composition: composition)
        }
    }
}
