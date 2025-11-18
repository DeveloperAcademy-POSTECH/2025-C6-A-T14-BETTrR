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
    var scripts: [Script]? = nil
    
    init(database: AppDatabase) {
        let scriptRepository = ScriptRepository(dbQueue: database.dbQueue)
        let scriptManagementService = ScriptManagementService(scriptRepository: scriptRepository)
        
        self.scriptRepository = scriptRepository
        self.scriptManagementService = scriptManagementService
        self.wordExtractionService = WordExtractionService(
            dbQueue: database.dbQueue,
            scriptRepository: scriptRepository,
            scriptManagementService: scriptManagementService
        )
    }
    
    @MainActor
    func refreshScripts() async throws {
        self.scripts = try await self.scriptManagementService.fetchAllScripts().sorted { $0.lastViewedAt > $1.lastViewedAt }
    }
    
    static func getForPreview(withMockData: Bool = true) async throws -> DatabaseContainer {
        let db = try AppDatabase.makeInMemory()
        let container = DatabaseContainer(database: db)
        if withMockData {
            try await DemoDataGenerator.generate(into: db)
        }
        try await container.refreshScripts()
        return container
    }
}
