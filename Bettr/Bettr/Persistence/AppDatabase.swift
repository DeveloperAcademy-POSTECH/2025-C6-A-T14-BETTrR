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
            try AppDatabaseMigrator.migrate(dbQueue)
            AppLog.database.debug("데이터베이스 초기화 완료")

            return appDB
        } catch {
            AppLog.database.fault("데이터베이스 초기화 실패")
            fatalError("Failed to initialize database")
        }
    }()
    
    // MARK: - Initialization
    
    private init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    // 테스트용 인메모리 데이터베이스
    static func makeInMemory() throws -> AppDatabase {
        let dbQueue = try DatabaseQueue()
        try AppDatabaseMigrator.migrate(dbQueue)
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
