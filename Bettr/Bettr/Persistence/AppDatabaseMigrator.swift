import GRDB

enum AppDatabaseMigrator {
    static let initialSchemaMigration = "v1_initial_schema"

    static var migrator: GRDB.DatabaseMigrator {
        var migrator = GRDB.DatabaseMigrator()

        migrator.registerMigration(initialSchemaMigration) { db in
            try db.create(table: "script", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("title", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("lastViewedAt", .datetime).notNull()
            }

            try db.create(table: "sentence", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("scriptId", .integer)
                    .notNull()
                    .references("script", onDelete: .cascade)
                t.column("orderIndex", .integer).notNull()
                t.column("englishText", .text).notNull()
                t.column("koreanText", .text).notNull()
            }

            try db.create(table: "chunk", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("sentenceId", .integer)
                    .notNull()
                    .references("sentence", onDelete: .cascade)
                t.column("orderIndex", .integer).notNull()
                t.column("englishText", .text).notNull()
                t.column("koreanText", .text).notNull()
            }

            try db.create(table: "feedback_summary", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("scriptId", .integer)
                    .notNull()
                    .references("script", onDelete: .cascade)
                t.column("accuracy", .double).notNull()
                t.column("missingWordCount", .integer).notNull()
                t.column("addedWordCount", .integer).notNull()
                t.column("replacedWordCount", .integer).notNull()
                t.column("practiceDuration", .double).notNull()
                t.column("createdAt", .datetime).notNull()
            }

            try db.create(table: "feedback_detail", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("feedbackSummaryId", .integer)
                    .notNull()
                    .references("feedback_summary", onDelete: .cascade)
                t.column("wordDiffType", .text).notNull()
                t.column("wordDiffExpected", .text)
                t.column("wordDiffActual", .text)
                t.column("originalText", .text)
                t.column("sentenceIndex", .integer).notNull()
                t.column("wordIndex", .integer).notNull()
            }

            try db.create(table: "word", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("scriptId", .integer)
                    .notNull()
                    .indexed()
                    .references("script", onDelete: .cascade)
                t.column("lemma", .text).notNull()
                t.column("pos", .text).notNull()
                t.column("meaning", .text).notNull()
                t.column("orderIndex", .integer).notNull()
            }
        }

        return migrator
    }

    static func migrate(_ dbQueue: DatabaseQueue) throws {
        try migrator.migrate(dbQueue)
    }
}
