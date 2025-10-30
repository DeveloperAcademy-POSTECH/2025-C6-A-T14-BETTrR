
import Foundation

enum FeedbackErrorType: String, CaseIterable, Codable {
    case missingWord = "누락된 단어"
    case addedWord = "추가된 단어"
    case replacedWord = "대체된 단어"
}
