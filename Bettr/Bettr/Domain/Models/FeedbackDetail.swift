
import Foundation
import GRDB

struct FeedbackDetail: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var feedbackSummaryId: Int64
    var wordDiffType: String
    var wordDiffExpected: String?
    var wordDiffActual: String?
    var originalText: String? // Keep originalText
    var sentenceIndex: Int
    var wordIndex: Int

    var wordDiff: WordDiff {
        switch wordDiffType {
        case "matched":
            return .matched(word: originalText ?? "") // Keep matched case
        case "missing":
            return .missing(expected: wordDiffExpected ?? "")
        case "extra":
            return .extra(actual: wordDiffActual ?? "")
        case "replaced":
            return .replaced(expected: wordDiffExpected ?? "", actual: wordDiffActual ?? "")
        default:
            return .matched(word: originalText ?? "") // Fallback
        }
    }

    static let feedbackSummary = belongsTo(FeedbackSummary.self)

    static var databaseTableName: String = "feedback_detail"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
