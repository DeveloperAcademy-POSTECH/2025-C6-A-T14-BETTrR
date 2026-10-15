import Foundation
import Observation

/// 한 scene의 홈 목록을 소유합니다. 인프라는 생성하지 않고 주입된 계약만 사용합니다.
@MainActor
@Observable
final class HomeListModel {
    private(set) var scripts: [Script]?
    private(set) var isLoading = false
    private(set) var isDeleting = false
    private(set) var errorMessage: String?

    private let scriptService: any HomeScriptServicing
    private var activeRequestID: UUID?

    init(scriptService: any HomeScriptServicing) {
        self.scriptService = scriptService
    }

    func refresh() async {
        guard !isDeleting, !Task.isCancelled else { return }
        await loadScripts()
    }

    private func loadScripts() async {
        guard !Task.isCancelled else { return }
        let requestID = UUID()
        activeRequestID = requestID
        isLoading = true
        errorMessage = nil
        defer {
            if activeRequestID == requestID {
                activeRequestID = nil
                isLoading = false
            }
        }

        do {
            let fetched = try await scriptService.fetchAllScripts()
            try Task.checkCancellation()
            guard activeRequestID == requestID else { return }
            scripts = fetched.sorted { $0.lastViewedAt > $1.lastViewedAt }
        } catch {
            guard activeRequestID == requestID, !Task.isCancelled,
                  !(error is CancellationError) else { return }
            AppLog.database.error("스크립트 목록 새로고침 실패")
            errorMessage = "스크립트 목록을 불러오지 못했습니다. 다시 시도해 주세요."
        }
    }

    func deleteScript(id: Int64) async {
        guard !isDeleting, !Task.isCancelled else { return }
        // 삭제 전에 시작된 조회가 나중에 완료되어도 삭제한 카드를 복원하지 않습니다.
        activeRequestID = nil
        isLoading = false
        isDeleting = true
        errorMessage = nil
        defer { isDeleting = false }

        do {
            try await scriptService.deleteScript(id: id)
            // DB 삭제 성공은 이후 조회 실패나 취소와 무관하게 목록에 반영합니다.
            scripts?.removeAll { $0.id == id }
            await loadScripts()
        } catch {
            guard !Task.isCancelled, !(error is CancellationError) else { return }
            AppLog.database.error("스크립트 삭제 실패")
            errorMessage = "스크립트를 삭제하지 못했습니다. 다시 시도해 주세요."
        }
    }
}
