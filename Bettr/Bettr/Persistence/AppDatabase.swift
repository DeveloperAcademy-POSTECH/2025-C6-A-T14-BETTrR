//
//  AppDatabase.swift
//  Bettr
//
//  Created by oliver on 10/30/25.
//

import Foundation
import GRDB

class AppDatabase {
    let dbQueue: DatabaseQueue
    
    // 싱글톤 인스턴스
    static let shared: AppDatabase = {
        do {
            let databasePath = defaultDatabasePath()
            let dbQueue = try DatabaseQueue(path: databasePath)
            let appDB = AppDatabase(dbQueue: dbQueue)
            try DatabaseMigrator.setupDatabase(dbQueue)
            print("✅ Database initialized at: \(databasePath)")

            #if DEBUG
            // 개발 모드에서만 데모 데이터 생성
            do {
                try DemoDataGenerator.generate(into: appDB)
                print("✅ Demo data creation attempted.")
            } catch {
                print("🔥 Failed to create demo data: \(error.localizedDescription)")
            }
            #endif

            return appDB
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
    }()
    
    // MARK: - Initialization
    
    private init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    // 테스트용 인메모리 데이터베이스
    static func makeInMemory() throws -> AppDatabase {
        let dbQueue = try DatabaseQueue()
        try DatabaseMigrator.setupDatabase(dbQueue)
        return AppDatabase(dbQueue: dbQueue)
    }
    
    // MARK: - Helper Methods
    
    private static func defaultDatabasePath() -> String {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = urls[0]
        return documentsDirectory.appendingPathComponent("app_database.sqlite").path
    }
}
