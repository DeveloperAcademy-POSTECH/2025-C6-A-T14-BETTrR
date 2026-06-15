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
        firebaseBootstrap.configure()
        return true
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
