
import Foundation
import GRDB

class ScriptRepository {
    private let dbQueue: DatabaseQueue
    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func createScript(scriptData: ScriptData) throws -> Script {
        return try dbQueue.write { db in
            var script = Script(
                title: scriptData.title,
                createdAt: Date(),
                lastViewedAt: Date()
            )
            try script.save(db)

            guard let scriptId = script.id else {
                throw DatabaseError(message: "Failed to get ID for created Script")
            }

            for (sentenceOrderIndex, sentenceData) in scriptData.sentences.enumerated() {
                var sentence = Sentence(
                    scriptId: scriptId,
                    orderIndex: sentenceOrderIndex,
                    englishText: sentenceData.englishText,
                    koreanText: sentenceData.koreanText
                )
                try sentence.save(db)

                guard let sentenceId = sentence.id else {
                    throw DatabaseError(message: "Failed to get ID for created Sentence")
                }

                for (chunkOrderIndex, chunkData) in sentenceData.chunks.enumerated() {
                    var chunk = Chunk(
                        sentenceId: sentenceId,
                        orderIndex: chunkOrderIndex,
                        englishText: chunkData.englishText,
                        koreanText: chunkData.koreanText
                    )
                    try chunk.save(db)
                }
            }
            return script
        }
    }
}
