import Foundation
import OneTakeKit

/// Manages the state of an active workout session on watchOS.
@Observable
final class WatchSessionViewModel {
    var session: Session?
    var exerciseLogs: [ExerciseLog] = []
    var groupedExercises: [GroupedExercise] = []
    var elapsedTime: TimeInterval = 0
    var isLoading = false
    var error: String?
    var sessionEnded = false

    private let sessionService: SessionService
    private let exerciseLogService: ExerciseLogService
    private var timerTask: Task<Void, Never>?
    private var sessionStartDate: Date?

    init(sessionService: SessionService = SessionService(), exerciseLogService: ExerciseLogService = ExerciseLogService()) {
        self.sessionService = sessionService
        self.exerciseLogService = exerciseLogService
    }

    var elapsedFormatted: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var totalSets: Int {
        exerciseLogs.reduce(0) { $0 + $1.sets.count }
    }

    // MARK: - Session lifecycle

    func startSession() async {
        isLoading = true
        error = nil
        do {
            let response = try await sessionService.start()
            if let sessionId = response.sessionId {
                let fetched = try await sessionService.fetchById(sessionId)
                session = fetched
                startTimer(from: fetched.startedAt)
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func checkForActiveSession() async {
        do {
            if let active = try await sessionService.fetchActive() {
                let fetched = try await sessionService.fetchById(active.id)
                session = fetched
                startTimer(from: fetched.startedAt)
                await refreshLogs()
            }
        } catch {
            // No active session — that's fine
        }
    }

    func endSession() async {
        guard let sessionId = session?.id else { return }
        do {
            try await sessionService.end(sessionId: sessionId)
            timerTask?.cancel()
            sessionEnded = true
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Exercise logs

    func refreshLogs() async {
        guard let sessionId = session?.id else { return }
        do {
            exerciseLogs = try await exerciseLogService.fetchBySession(sessionId)
            groupedExercises = groupExerciseLogs(exerciseLogs)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Timer

    private func startTimer(from startedAt: String) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let start = formatter.date(from: startedAt) else { return }
        sessionStartDate = start

        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                await MainActor.run {
                    self?.elapsedTime = Date().timeIntervalSince(start)
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    func reset() {
        timerTask?.cancel()
        session = nil
        exerciseLogs = []
        groupedExercises = []
        elapsedTime = 0
        sessionEnded = false
        error = nil
    }
}
