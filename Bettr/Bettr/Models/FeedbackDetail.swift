
import Foundation
import GRDB

struct FeedbackDetail: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var feedbackSummaryId: Int64
    var errorType: String
    var originalText: String?
    var spokenText: String?
    var startTime: Double
    var endTime: Double

    static let feedbackSummary = belongsTo(FeedbackSummary.self)

    static var databaseTableName: String = "feedback_detail"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
