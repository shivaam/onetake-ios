import Foundation
import OneTakeKit

@Observable
final class SessionDetailViewModel {
    var session: Session?
    var exerciseLogs: [ExerciseLog] = []
    var groupedExercises: [GroupedExercise] = []
    var isLoading = false
    var error: String?

    private let sessionService = SessionService()
    private let exerciseLogService = ExerciseLogService()

    func load(sessionId: String) async {
        isLoading = true
        error = nil
        do {
            async let fetchedSession = sessionService.fetchById(sessionId)
            async let fetchedLogs = exerciseLogService.fetchBySession(sessionId)

            session = try await fetchedSession
            exerciseLogs = try await fetchedLogs
            groupedExercises = groupExerciseLogs(exerciseLogs)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func refreshLogs() async {
        guard let sessionId = session?.id else { return }
        do {
            exerciseLogs = try await exerciseLogService.fetchBySession(sessionId)
            groupedExercises = groupExerciseLogs(exerciseLogs)
        } catch {
            self.error = error.localizedDescription
        }
    }

    var duration: String {
        guard let session,
              let startedAt = parseDate(session.startedAt),
              let endedAt = session.endedAt.flatMap({ parseDate($0) }) else {
            return "--"
        }
        let interval = endedAt.timeIntervalSince(startedAt)
        let minutes = Int(interval) / 60
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)h \(remainingMinutes)m"
    }

    var totalSets: Int {
        exerciseLogs.reduce(0) { $0 + $1.sets.count }
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString)
    }
}
