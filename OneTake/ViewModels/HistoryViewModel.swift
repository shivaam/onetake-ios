import Foundation
import OneTakeKit

@Observable
final class HistoryViewModel {
    var sessions: [Session] = []
    var isLoading = false
    var error: String?

    private let sessionService = SessionService()

    func load() async {
        isLoading = true
        error = nil
        do {
            sessions = try await sessionService.fetchHistory()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
