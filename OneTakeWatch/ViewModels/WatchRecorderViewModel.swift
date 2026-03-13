import AVFoundation
import OneTakeKit

/// Handles audio recording on watchOS using AVAudioRecorder.
/// Records AAC .m4a files, then uploads via VoiceService.
@Observable
final class WatchRecorderViewModel {
    var isRecording = false
    var isProcessing = false
    var processingStatus: String?
    var error: String?

    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var autoStopTask: Task<Void, Never>?
    private let voiceService: VoiceService
    private let maxDuration: TimeInterval = 60

    init(voiceService: VoiceService = VoiceService()) {
        self.voiceService = voiceService
    }

    func toggleRecording(sessionId: String, onComplete: @escaping () -> Void) {
        if isRecording {
            stopRecording(sessionId: sessionId, onComplete: onComplete)
        } else {
            startRecording(sessionId: sessionId, onComplete: onComplete)
        }
    }

    private func startRecording(sessionId: String, onComplete: @escaping () -> Void) {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
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
            error = nil

            // Auto-stop after max duration
            autoStopTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(60 * 1_000_000_000))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.stopRecording(sessionId: sessionId, onComplete: onComplete)
                }
            }
        } catch {
            self.error = "Failed to start recording"
        }
    }

    private func stopRecording(sessionId: String, onComplete: @escaping () -> Void) {
        autoStopTask?.cancel()
        autoStopTask = nil

        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.stop()
        isRecording = false

        guard let url = recordingURL, let data = try? Data(contentsOf: url) else {
            error = "Failed to read recording"
            return
        }

        // Upload and process
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
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.processingStatus = nil
                    self.error = error.localizedDescription
                }
            }

            // Clean up temp file
            try? FileManager.default.removeItem(at: url)
        }
    }
}
