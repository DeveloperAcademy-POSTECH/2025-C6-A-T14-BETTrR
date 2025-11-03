//
//  DatabaseMigrator.swift
//  Bettr
//
//  Created by oliver on 10/30/25.
//

import Foundation
import GRDB

class DatabaseMigrator {
    static func setupDatabase(_ dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            // Script 테이블
            try db.create(table: Script.databaseTableName, ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("title", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("lastViewedAt", .datetime).notNull()
            }
            
            // Sentence 테이블
            try db.create(table: Sentence.databaseTableName, ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("scriptId", .integer)
                    .notNull()
                    .indexed()
                    .references(Script.databaseTableName, onDelete: .cascade)
                t.column("orderIndex", .integer).notNull()
                t.column("englishText", .text).notNull()
                t.column("koreanText", .text).notNull()
            }
            
            // Chunk 테이블
            try db.create(table: Chunk.databaseTableName, ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("sentenceId", .integer)
                    .notNull()
                    .indexed()
                    .references(Sentence.databaseTableName, onDelete: .cascade)
                t.column("orderIndex", .integer).notNull()
                t.column("englishText", .text).notNull()
                t.column("koreanText", .text).notNull()
            }
            
            // PracticeSession 테이블
            try db.create(table: PracticeSession.databaseTableName, ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("scriptId", .integer)
                    .notNull()
                    .indexed()
                    .references(Script.databaseTableName, onDelete: .cascade)
                t.column("recordingPath", .text).notNull()
                t.column("totalPresentationTime", .double).notNull()
                t.column("createdAt", .datetime).notNull()
            }
            
            // FeedbackSummary 테이블
            try db.create(table: FeedbackSummary.databaseTableName, ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("practiceSessionId", .integer)
                    .notNull()
                    .unique()
                    .indexed()
                    .references(PracticeSession.databaseTableName, onDelete: .cascade)
                t.column("totalScore", .double).notNull()
                t.column("missingWordCount", .integer).notNull()
                t.column("addedWordCount", .integer).notNull()
                t.column("replacedWordCount", .integer).notNull()
                t.column("analyzedAt", .datetime).notNull()
            }
            
            // FeedbackDetail 테이블
            try db.create(table: FeedbackDetail.databaseTableName, ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("feedbackSummaryId", .integer)
                    .notNull()
                    .indexed()
                    .references(FeedbackSummary.databaseTableName, onDelete: .cascade)
                t.column("errorType", .text).notNull()
                t.column("originalText", .text)
                t.column("spokenText", .text)
                t.column("startTime", .double).notNull()
                t.column("endTime", .double).notNull()
            }
        }
    }
}
