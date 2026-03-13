import Foundation
import OneTakeKit

/// Represents a session with its exercise logs for the history view
struct SessionWithLogs: Identifiable, Sendable {
    let session: Session
    let exerciseLogs: [ExerciseLog]
    let groupedExercises: [GroupedExercise]

    var id: String { session.id }

    var duration: String {
        guard let start = parseDate(session.startedAt),
              let end = session.endedAt.flatMap({ parseDate($0) }) else {
            return "--"
        }
        let minutes = Int(end.timeIntervalSince(start)) / 60
        if minutes < 60 { return "\(minutes) min" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    var durationMinutes: Int {
        guard let start = parseDate(session.startedAt),
              let end = session.endedAt.flatMap({ parseDate($0) }) else { return 0 }
        return Int(end.timeIntervalSince(start)) / 60
    }

    var totalSets: Int {
        exerciseLogs.reduce(0) { $0 + $1.sets.count }
    }

    var totalVolume: Double {
        exerciseLogs.flatMap(\.sets).compactMap { set in
            guard let w = set.w, let r = set.r else { return nil }
            return w * r
        }.reduce(0, +)
    }

    var dayLabel: String {
        guard let date = parseDate(session.startedAt) else { return "" }
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func parseDate(_ s: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: s)
    }
}

@Observable
final class HistoryViewModel {
    var sessions: [Session] = []
    var sessionsWithLogs: [SessionWithLogs] = []
    var isLoading = false
    var error: String?

    private let sessionService = SessionService()
    private let exerciseLogService = ExerciseLogService()

    // Stats
    var thisMonthCount: Int {
        let cal = Calendar.current
        return sessionsWithLogs.filter { swl in
            guard let d = parseDate(swl.session.startedAt) else { return false }
            return cal.isDate(d, equalTo: Date(), toGranularity: .month)
        }.count
    }

    var totalVolumeThisMonth: Double {
        let cal = Calendar.current
        return sessionsWithLogs.filter { swl in
            guard let d = parseDate(swl.session.startedAt) else { return false }
            return cal.isDate(d, equalTo: Date(), toGranularity: .month)
        }.reduce(0) { $0 + $1.totalVolume }
    }

    var totalTimeThisMonth: Int {
        let cal = Calendar.current
        return sessionsWithLogs.filter { swl in
            guard let d = parseDate(swl.session.startedAt) else { return false }
            return cal.isDate(d, equalTo: Date(), toGranularity: .month)
        }.reduce(0) { $0 + $1.durationMinutes }
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            sessions = try await sessionService.fetchHistory()

            // Load exercise logs for each session
            var result: [SessionWithLogs] = []
            for session in sessions {
                let logs = try await exerciseLogService.fetchBySession(session.id)
                let grouped = groupExerciseLogs(logs)
                result.append(SessionWithLogs(session: session, exerciseLogs: logs, groupedExercises: grouped))
            }
            sessionsWithLogs = result
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func parseDate(_ s: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: s)
    }
}
