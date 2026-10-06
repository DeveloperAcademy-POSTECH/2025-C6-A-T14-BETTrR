import Foundation

/// 단일 분석 요청을 처리하며, 구현체는 작업 취소 이후 도착한 응답을 폐기해야 합니다.
@MainActor
protocol ScriptAnalyzing {
    func analyzeScript(_ content: String) async throws -> ScriptData
}

/// AI 단어 추출만 담당하며, 영속화와 영속화 실패는 호출부가 책임집니다.
@MainActor
protocol WordExtracting {
    func extractWords(from content: String) async throws -> [WordData]
}

nonisolated struct WordData: Codable, Hashable, Sendable {
    let lemma: String
    let pos: String
    let meaning: String
}

/// 제공자 오류와 사용자 콘텐츠가 이 경계를 넘어 노출되지 않도록 합니다.
nonisolated enum AIError: Error, Equatable, Sendable, LocalizedError {
    case cancelled
    case authentication
    case rateLimited
    case transient
    case invalidInput
    case responseContract
    case unknown

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "분석이 취소되었습니다."
        case .authentication:
            return "AI 서비스 인증 또는 권한을 확인할 수 없습니다."
        case .rateLimited:
            return "AI 요청이 많습니다. 잠시 후 다시 시도해 주세요."
        case .transient:
            return "AI 서비스에 연결할 수 없습니다. 잠시 후 다시 시도해 주세요."
        case .invalidInput:
            return "분석할 스크립트를 확인해 주세요."
        case .responseContract:
            return "AI 분석 결과를 확인할 수 없습니다. 다시 시도해 주세요."
        case .unknown:
            return "AI 분석에 실패했습니다. 잠시 후 다시 시도해 주세요."
        }
    }
}
