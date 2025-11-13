//
//  BettrApp.swift
//  Bettr
//
//  Created by 서세린 on 10/28/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAppCheck

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // app check provider factory 설정
        let providerFactory = BettrCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        FirebaseApp.configure()
        
        return true
    }
}

// MARK: - AppCheck Provider Factory 구현
class BettrCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        if #available(iOS 14.0, *) {
            return AppAttestProvider(app: app)
        } else {
            return DeviceCheckProvider(app: app)
        }
    }
}


@main
struct BettrApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    private let database = AppDatabase.shared
    
    @State private var router = NavigationRouter()
    @State private var audioService = AudioPlaybackService()
    
    // 앱 상태가 바뀔 때마다 DatabaseContainer를 매번 새로 생성하여 잠재적인 버그와 성능 저하를 유발할 수 있다면서 아래처럼 바꾸라는데 저는 이걸 잘 몰라서 한 번 확인 해주세요.
    //    @State private var databaseContainer: DatabaseContainer
    
    //    init() {
    //            _databaseContainer = State(initialValue: DatabaseContainer(database: AppDatabase.shared))
    //        }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            //  .environment(databaseContainer)
                .environment(DatabaseContainer(database: database))
                .environment(router)
                .environment(audioService)
        }
    }
}
