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

        print("🔥 AppDelegate didFinishLaunching - Setting AppCheck Provider Factory")

        let providerFactory = BettrCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)

        FirebaseApp.configure()

        // 강제 토큰 fetch 테스트
        Task {
            do {
                print("⏳ AppCheck: Fetching token manually...")
                let token = try await AppCheck.appCheck().token(forcingRefresh: true)
                print("✅ AppCheck Token Fetched: \(token.token)")
            } catch {
                print("❌ AppCheck Token Fetch FAILED: \(error.localizedDescription)")
            }
        }

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
    
    @State private var databaseContainer: DatabaseContainer
    
    init() {
        _databaseContainer = State(initialValue: DatabaseContainer(database: AppDatabase.shared))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(databaseContainer)
            //    .environment(DatabaseContainer(database: database))
                .environment(router)
                .environment(audioService)
        }
    }
}
