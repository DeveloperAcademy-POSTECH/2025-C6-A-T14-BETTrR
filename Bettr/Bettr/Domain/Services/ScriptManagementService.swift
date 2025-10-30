
import Foundation
import GRDB

class ScriptManagementService {
    private let dbQueue: DatabaseQueue
    private let scriptRepository: ScriptRepository

    init(dbQueue: DatabaseQueue, scriptRepository: ScriptRepository) {
        self.dbQueue = dbQueue
        self.scriptRepository = scriptRepository
    }

    // MARK: - Script Create
    func createScript(scriptData: ScriptData) throws -> Script {
        try dbQueue.write { db in
            try validateScriptData(scriptData)

            var script = Script(
                title: scriptData.title,
                createdAt: Date(),
                lastViewedAt: Date()
            )
            _ = try scriptRepository.save(script: &script, in: db)
            
            guard let scriptId = script.id else {
                throw ScriptRepositoryError.databaseError(message: "Failed to get ID for created Script")
            }

            for (sentenceOrderIndex, sentenceData) in scriptData.sentences.enumerated() {
                var sentence = Sentence(
                    scriptId: scriptId,
                    orderIndex: sentenceOrderIndex,
                    englishText: sentenceData.englishText,
                    koreanText: sentenceData.koreanText
                )
                _ = try scriptRepository.save(sentence: &sentence, in: db)
                
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
                    _ = try scriptRepository.save(chunk: &chunk, in: db)
                }
            }
            return script
        }
    }
    
    // MARK: - Script Read
    func fetchScript(id: Int64) throws -> Script? {
        return try dbQueue.read { db in
            try scriptRepository.fetchScript(id: id, in: db)
        }
    }

    func fetchAllScripts() throws -> [Script] {
        return try dbQueue.read { db in
            try scriptRepository.fetchAllScripts(in: db)
        }
    }
    
    // MARK: - Script Update
    func updateLastViewedAt(forScriptId scriptId: Int64) throws {
        try dbQueue.write { db in
            guard var script = try scriptRepository.fetchScript(id: scriptId, in: db) else {
                throw ScriptRepositoryError.notFound(message: "Script with ID \(scriptId) not found.")
            }
            script.lastViewedAt = Date()
            try script.update(db) // Direct update for now, can be moved to repo if needed
        }
    }

    // MARK: - Script Delete
    func deleteScript(id: Int64) throws {
        try dbQueue.write { db in
            guard let script = try scriptRepository.fetchScript(id: id, in: db) else {
                throw ScriptRepositoryError.notFound(message: "Script with ID \(id) not found.")
            }
            _ = try script.delete(db)
        }
    }

    // MARK: - Private Methods (Validation)
    private func validateScriptData(_ scriptData: ScriptData) throws {
        if scriptData.sentences.isEmpty {
            throw ScriptRepositoryError.validationError(message: "A Script must contain at least one sentence.")
        }

        for sentenceData in scriptData.sentences {
            if sentenceData.chunks.isEmpty {
                throw ScriptRepositoryError.validationError(message: "A Sentence must contain at least one chunk.")
            }
        }
    }
}
