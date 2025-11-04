//
//  ScriptManagementServiceProtocol.swift
//  Bettr
//
//  Created by 길정수 on 11/3/25.
//

import Foundation
import GRDB

protocol ScriptManagementServiceProtocol {
    func fetchScriptWithSentencesAndChunks(id: Int64) throws -> (script: Script, sentences: [(sentence: Sentence, chunks: [Chunk])])?
}

extension ScriptManagementService: ScriptManagementServiceProtocol { }
