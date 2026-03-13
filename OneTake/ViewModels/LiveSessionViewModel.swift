import Foundation
import AVFoundation
import OneTakeKit

@Observable
final class LiveSessionViewModel {
    var session: Session?
    var exerciseLogs: [ExerciseLog] = []
    var groupedExercises: [GroupedExercise] = []
    var elapsedTime: TimeInterval = 0
    var isLoading = false
    var error: String?
    var sessionEnded = false

    // Recording state
    var isRecording = false
    var isProcessing = false
    var processingStatus: String?

    private let sessionService = SessionService()
    private let exerciseLogService = ExerciseLogService()
    private let voiceService = VoiceService()
    private var timerTask: Task<Void, Never>?
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var autoStopTask: Task<Void, Never>?

    var elapsedFormatted: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    var hasActiveSession: Bool { session != nil && !sessionEnded }

    var totalSets: Int {
        exerciseLogs.reduce(0) { $0 + $1.sets.count }
    }

    // MARK: - Session lifecycle

    func checkForActiveSession() async {
        do {
            if let active = try await sessionService.fetchActive() {
                let fetched = try await sessionService.fetchById(active.id)
                session = fetched
                startTimer(from: fetched.startedAt)
                await refreshLogs()
            }
        } catch {
            // No active session
        }
    }

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

    // MARK: - Recording

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
        } catch {
            self.error = "Microphone access failed"
            return
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("recording_\(UUID().uuidString).m4a")
        recordingURL = fileURL

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.record()
            isRecording = true
            self.error = nil

            autoStopTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run { self?.stopRecording() }
            }
        } catch {
            self.error = "Failed to start recording"
        }
    }

    private func stopRecording() {
        autoStopTask?.cancel()
        autoStopTask = nil

        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.stop()
        isRecording = false

        guard let url = recordingURL, let data = try? Data(contentsOf: url) else {
            error = "Failed to read recording"
            return
        }

        guard let sessionId = session?.id else { return }

        isProcessing = true
        processingStatus = "Uploading..."

        Task {
            do {
                let inputMessageId = try await voiceService.uploadAudio(data: data, sessionId: sessionId)
                await MainActor.run { self.processingStatus = "Processing..." }
                _ = try await voiceService.pollForCompletion(inputMessageId: inputMessageId)
                await MainActor.run {
                    self.isProcessing = false
                    self.processingStatus = nil
                }
                await refreshLogs()
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.processingStatus = nil
                    self.error = error.localizedDescription
                }
            }
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Text input

    func sendText(_ text: String) async {
        guard let sessionId = session?.id, !text.isEmpty else { return }
        isProcessing = true
        processingStatus = "Processing..."
        error = nil
        do {
            let inputMessageId = try await voiceService.uploadText(text, sessionId: sessionId)
            _ = try await voiceService.pollForCompletion(inputMessageId: inputMessageId)
            isProcessing = false
            processingStatus = nil
            await refreshLogs()
        } catch {
            isProcessing = false
            processingStatus = nil
            self.error = error.localizedDescription
        }
    }

    // MARK: - Timer

    private func startTimer(from startedAt: String) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let start = formatter.date(from: startedAt) else { return }

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
