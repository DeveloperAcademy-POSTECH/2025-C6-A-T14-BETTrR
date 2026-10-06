import Foundation

@MainActor
protocol AnalysisRateLimiting {
    func canCall(at now: Date) -> Bool
}

extension AnalysisRateLimiting {
    func canCall() -> Bool { canCall(at: Date()) }
}
