import Foundation
import Supabase

public protocol VoiceServiceProtocol: Sendable {
    func uploadAudio(data: Data, sessionId: String) async throws -> String
    func uploadText(_ text: String, sessionId: String) async throws -> String
    func pollForCompletion(inputMessageId: String) async throws -> InputMessage
}

public struct VoiceService: VoiceServiceProtocol {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    public init() {}

    /// Uploads audio to the process-voice edge function.
    /// Returns the inputMessageId for polling.
    public func uploadAudio(data: Data, sessionId: String) async throws -> String {
        let token = try await client.auth.session.accessToken
        let url = SupabaseManager.shared.supabaseURL
            .appendingPathComponent("functions/v1/process-input")

        // Build multipart form data
        let boundary = UUID().uuidString
        var body = Data()

        // Audio field
        body.appendMultipart(boundary: boundary, name: "audio", filename: "recording.m4a", mimeType: "audio/mp4", data: data)

        // Session ID field
        body.appendMultipart(boundary: boundary, name: "sessionId", value: sessionId)

        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (responseData, httpResponse) = try await URLSession.shared.data(for: request)

        guard let http = httpResponse as? HTTPURLResponse, http.statusCode == 200 else {
            let errorMsg = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            throw OneTakeError.uploadFailed(errorMsg)
        }

        let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: responseData)
        guard uploadResponse.success else {
            throw OneTakeError.uploadFailed("Upload returned success=false")
        }

        return uploadResponse.inputMessageId
    }

    /// Uploads text to the process-text edge function.
    /// Returns the inputMessageId for polling.
    public func uploadText(_ text: String, sessionId: String) async throws -> String {
        let token = try await client.auth.session.accessToken
        let url = SupabaseManager.shared.supabaseURL
            .appendingPathComponent("functions/v1/process-input")

        let payload = ["text": text, "sessionId": sessionId]
        let body = try JSONEncoder().encode(payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (responseData, httpResponse) = try await URLSession.shared.data(for: request)

        guard let http = httpResponse as? HTTPURLResponse, http.statusCode == 200 else {
            let errorMsg = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            throw OneTakeError.uploadFailed(errorMsg)
        }

        let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: responseData)
        guard uploadResponse.success else {
            throw OneTakeError.uploadFailed("Upload returned success=false")
        }

        return uploadResponse.inputMessageId
    }

    /// Polls the input_messages table until processing completes or fails.
    /// Polls every 2 seconds, max 30 attempts (60 seconds total).
    public func pollForCompletion(inputMessageId: String) async throws -> InputMessage {
        let maxAttempts = 30
        let intervalNs: UInt64 = 2_000_000_000 // 2 seconds

        for _ in 0..<maxAttempts {
            let message: InputMessage = try await client
                .from("input_messages")
                .select("id, status, content, error_message, is_workout_related")
                .eq("id", value: inputMessageId)
                .single()
                .execute()
                .value

            switch message.status {
            case .completed, .failed:
                if message.status == .failed {
                    throw OneTakeError.processingFailed(message.errorMessage ?? "Processing failed")
                }
                return message
            case .processing:
                try await Task.sleep(nanoseconds: intervalNs)
            }
        }

        throw OneTakeError.processingTimeout
    }
}

// MARK: - Multipart helpers

extension Data {
    mutating func appendMultipart(boundary: String, name: String, filename: String, mimeType: String, data: Data) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        append(data)
        append("\r\n".data(using: .utf8)!)
    }

    mutating func appendMultipart(boundary: String, name: String, value: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append(value.data(using: .utf8)!)
        append("\r\n".data(using: .utf8)!)
    }
}
