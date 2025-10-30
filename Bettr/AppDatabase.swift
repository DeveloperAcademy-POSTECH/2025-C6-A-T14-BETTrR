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
            appDB.createDemoData()
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

    private func createDemoData() {
        let scriptRepository = ScriptRepository()
        let scriptManagementService = ScriptManagementService(dbQueue: dbQueue, scriptRepository: scriptRepository)
        let practiceSessionService = PracticeSessionService(dbQueue: dbQueue, scriptRepository: scriptRepository)

        // Check if demo data already exists to prevent duplicates
        do {
            let existingScripts = try scriptManagementService.fetchAllScripts()
            if !existingScripts.isEmpty {
                print("ℹ️ Demo data already exists. Skipping creation.")
                return
            }
        } catch {
            print("⚠️ Failed to check for existing demo data: \(error.localizedDescription)")
        }

        let demoScriptData = [
            ScriptData(
                title: "Sample Script for Demo",
                sentences: [
                    SentenceData(
                        orderIndex: 0,
                        englishText: "Hello, this is a sample sentence for the demo application.",
                        koreanText: "안녕하세요, 이것은 데모 애플리케이션을 위한 샘플 문장입니다.",
                        chunks: [
                            ChunkData(orderIndex: 0, englishText: "Hello,", koreanText: "안녕하세요,"),
                            ChunkData(orderIndex: 1, englishText: "this is a sample sentence", koreanText: "이것은 샘플 문장입니다"),
                            ChunkData(orderIndex: 2, englishText: "for the demo application.", koreanText: "데모 애플리케이션을 위한.")
                        ]
                    ),
                    SentenceData(
                        orderIndex: 1,
                        englishText: "We hope you enjoy using Bettr to improve your English speaking skills.",
                        koreanText: "Bettr를 사용하여 영어 말하기 실력을 향상시키시길 바랍니다.",
                        chunks: [
                            ChunkData(orderIndex: 0, englishText: "We hope you enjoy", koreanText: "즐겁게 사용하시길 바랍니다"),
                            ChunkData(orderIndex: 1, englishText: "using Bettr", koreanText: "Bettr를 사용하여"),
                            ChunkData(orderIndex: 2, englishText: "to improve your English speaking skills.", koreanText: "영어 말하기 실력을 향상시키기 위해.")
                        ]
                    )
                ]
            ),
            ScriptData(
                title: "Another Demo Script",
                sentences: [
                    SentenceData(
                        orderIndex: 0,
                        englishText: "This is another example script for testing purposes.",
                        koreanText: "이것은 테스트 목적의 또 다른 예시 스크립트입니다.",
                        chunks: [
                            ChunkData(orderIndex: 0, englishText: "This is another example script", koreanText: "이것은 또 다른 예시 스크립트입니다"),
                            ChunkData(orderIndex: 1, englishText: "for testing purposes.", koreanText: "테스트 목적의.")
                        ]
                    )
                ]
            )
        ]

        for scriptData in demoScriptData {
            do {
                let script = try scriptManagementService.createScript(scriptData: scriptData)
                print("✅ Demo script created successfully: \(scriptData.title)")

                guard let scriptId = script.id else { continue }

                // Create a demo practice session using PracticeSessionService
                let practiceSession = try practiceSessionService.createPracticeSession(
                    scriptId: scriptId,
                    recordingPath: "/path/to/demo_recording_\(scriptId).m4a",
                    totalPresentationTime: 60.0 + Double(scriptId),
                )

                guard let practiceSessionId = practiceSession.id else { continue }

                // Create demo feedback details data
                let feedbackDetailsData: [(errorType: FeedbackErrorType, originalText: String?, spokenText: String?, startTime: Double, endTime: Double)] = [
                    (errorType: .addedWord, originalText: nil, spokenText: "extra", startTime: 5.0, endTime: 5.5),
                    (errorType: .missingWord, originalText: "word", spokenText: nil, startTime: 15.0, endTime: 15.8)
                ]

                // Create a demo feedback summary using PracticeSessionService
                _ = try practiceSessionService.createFeedbackSummary(
                    practiceSessionId: practiceSessionId,
                    totalScore: 75.0 + Double(scriptId) * 5,
                    missingWordCount: 1,
                    addedWordCount: 1,
                    replacedWordCount: 0,
                    feedbackDetailsData: feedbackDetailsData
                )

                print("✅ Demo feedback data created successfully for script: \(scriptData.title)")
            } catch {
                print("🔥 Failed to create demo data for script \(scriptData.title): \(error.localizedDescription)")
            }
        }
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
