
import Foundation
import GRDB

struct FeedbackSummary: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var practiceSessionId: Int64
    var totalScore: Double
    var missingWordCount: Int
    var addedWordCount: Int
    var replacedWordCount: Int
    var analyzedAt: Date

    static var databaseTableName: String = "feedback_summary"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
