import Foundation

/// AI Adapter와 호출부 사이에서 특정 actor에 격리되지 않은 값으로 전달하는 청크 데이터입니다.
/// `nonisolated`와 `Sendable`을 유지해 actor 경계를 안전하게 오갈 수 있도록 합니다.
nonisolated public struct ChunkData: Codable, Hashable, Sendable {
    public var orderIndex: Int
    public var englishText: String
    public var koreanText: String

    public init(orderIndex: Int, englishText: String, koreanText: String) {
        self.orderIndex = orderIndex
        self.englishText = englishText
        self.koreanText = koreanText
    }
}
