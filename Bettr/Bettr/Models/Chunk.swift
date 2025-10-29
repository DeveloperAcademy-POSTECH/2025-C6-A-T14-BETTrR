
import Foundation
import GRDB

struct Chunk: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var sentenceId: Int64
    var orderIndex: Int
    var englishText: String
    var koreanText: String

    static var databaseTableName: String = "chunk"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
