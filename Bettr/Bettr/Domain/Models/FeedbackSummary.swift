
import Foundation
import GRDB

struct FeedbackSummary: Identifiable, Codable, Equatable, Hashable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var scriptId: Int64
    var accuracy: Double
    var missingWordCount: Int
    var addedWordCount: Int
    var replacedWordCount: Int
    var practiceDuration: Double
    var createdAt: Date

    static let script = belongsTo(Script.self)
    static let feedbackDetails = hasMany(FeedbackDetail.self)

    static var databaseTableName: String = "feedback_summary"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
