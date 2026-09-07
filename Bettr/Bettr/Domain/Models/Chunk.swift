
import Foundation
import GRDB

struct Chunk: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var sentenceId: Int64
    var orderIndex: Int
    var englishText: String
    var koreanText: String

    static let sentence = belongsTo(Sentence.self)

    static var databaseTableName: String = "chunk"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension Chunk {
    static func from(_ data: ChunkData, sentenceId: Int64) -> Chunk {
        Chunk(
            id: nil,
            sentenceId: sentenceId,
            orderIndex: data.orderIndex,
            englishText: data.englishText,
            koreanText: data.koreanText
        )
    }
}
