
import Foundation
import GRDB

class ScriptRepository {
    private let dbQueue: DatabaseQueue
    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func createScript(scriptData: ScriptData) throws -> Script {
        guard !scriptData.sentences.isEmpty else {
            throw ScriptRepositoryError.validationError(message: "A Script must contain at least one sentence.")
        }

        return try dbQueue.write { db in

            var script = Script(
                title: scriptData.title,
                createdAt: Date(),
                lastViewedAt: Date()
            )
            do {
                try script.save(db)
            } catch {
                throw ScriptRepositoryError.databaseError(message: "Failed to save Script: \(error.localizedDescription)")
            }

            // Ensure script.id is available after saving
            guard let scriptId = script.id else {
                throw ScriptRepositoryError.databaseError(message: "Failed to get ID for created Script")
            }

            for (sentenceOrderIndex, sentenceData) in scriptData.sentences.enumerated() {
                // Validation: A Sentence must contain at least one Chunk
                guard !sentenceData.chunks.isEmpty else {
                    throw ScriptRepositoryError.validationError(message: "A Sentence must contain at least one chunk.")
                }

                var sentence = Sentence(
                    scriptId: scriptId,
                    orderIndex: sentenceOrderIndex,
                    englishText: sentenceData.englishText,
                    koreanText: sentenceData.koreanText
                )
                do {
                    try sentence.save(db)
                } catch {
                    throw ScriptRepositoryError.databaseError(message: "Failed to save Sentence: \(error.localizedDescription)")
                }

                // Ensure sentence.id is available after saving
                guard let sentenceId = sentence.id else {
                    throw ScriptRepositoryError.databaseError(message: "Failed to get ID for created Sentence")
                }

                for (chunkOrderIndex, chunkData) in sentenceData.chunks.enumerated() {
                    var chunk = Chunk(
                        sentenceId: sentenceId,
                        orderIndex: chunkOrderIndex,
                        englishText: chunkData.englishText,
                        koreanText: chunkData.koreanText
                    )
                    do {
                        try chunk.save(db)
                    } catch {
                        throw ScriptRepositoryError.databaseError(message: "Failed to save Chunk: \(error.localizedDescription)")
                    }
                }
            }
            return script
        }
    }

    func fetchScript(id: Int64) throws -> Script? {
        return try dbQueue.read { db in
            try Script.fetchOne(db, key: id)
        }
    }

    func fetchAllScripts() throws -> [Script] {
        return try dbQueue.read { db in
            try Script.fetchAll(db)
        }
    }
}
