//
//  DatabaseContainer.swift
//  Bettr
//
//  Created by oliver on 10/30/25.
//

import Foundation
import Combine

@Observable
class DatabaseContainer {
    let scriptRepository: ScriptRepository
    let scriptManagementService: ScriptManagementServiceProtocol
    let wordExtractionService: WordExtractionService
    
    @MainActor
    init(database: AppDatabase, wordExtractor: (any WordExtracting)? = nil) {
        let scriptRepository = ScriptRepository(dbQueue: database.dbQueue)
        let scriptManagementService = ScriptManagementService(scriptRepository: scriptRepository)
        let wordExtractor = wordExtractor ?? FirebaseGeminiAdapter()
        
        self.scriptRepository = scriptRepository
        self.scriptManagementService = scriptManagementService
        self.wordExtractionService = WordExtractionService(
            dbQueue: database.dbQueue,
            scriptRepository: scriptRepository,
            scriptManagementService: scriptManagementService,
            wordExtractor: wordExtractor
        )
    }
    
    static func getForPreview(withMockData: Bool = true) async throws -> DatabaseContainer {
        let db = try AppDatabase.makeInMemory()
        let container = DatabaseContainer(database: db, wordExtractor: PreviewWordExtractor())
        if withMockData {
            try await DemoDataGenerator.generate(into: db)
        }
        return container
    }
}

@MainActor
private struct PreviewWordExtractor: WordExtracting {
    func extractWords(from content: String) async throws -> [WordData] {
        [
            WordData(lemma: "encounter", pos: "동", meaning: "마주치다"),
            WordData(lemma: "challenge", pos: "명", meaning: "도전")
        ]
    }
}
