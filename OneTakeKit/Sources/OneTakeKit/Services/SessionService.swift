import Foundation
import Supabase

public protocol SessionServiceProtocol: Sendable {
    func fetchActive() async throws -> ActiveSessionResponse?
    func start() async throws -> StartSessionResponse
    func end(sessionId: String) async throws
    func fetchHistory() async throws -> [Session]
    func fetchById(_ sessionId: String) async throws -> Session
}

public struct SessionService: SessionServiceProtocol {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    public init() {}

    public func fetchActive() async throws -> ActiveSessionResponse? {
        try await client.rpc("get_active_session").execute().value
    }

    public func start() async throws -> StartSessionResponse {
        let response: StartSessionResponse = try await client
            .rpc("start_session", params: ["override_start_time": nil as String?])
            .execute()
            .value
        guard response.success else {
            throw OneTakeError.sessionStartFailed(response.message ?? "Unknown error")
        }
        return response
    }

    public func end(sessionId: String) async throws {
        try await client
            .rpc("end_session", params: [
                "session_id": sessionId,
                "override_end_time": nil as String?,
            ])
            .execute()
    }

    public func fetchHistory() async throws -> [Session] {
        try await client
            .from("sessions")
            .select()
            .eq("status", value: "completed")
            .order("started_at", ascending: false)
            .execute()
            .value
    }

    public func fetchById(_ sessionId: String) async throws -> Session {
        try await client
            .from("sessions")
            .select()
            .eq("id", value: sessionId)
            .single()
            .execute()
            .value
    }
}

public enum OneTakeError: LocalizedError {
    case sessionStartFailed(String)
    case uploadFailed(String)
    case processingTimeout
    case processingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .sessionStartFailed(let msg): return "Failed to start session: \(msg)"
        case .uploadFailed(let msg): return "Upload failed: \(msg)"
        case .processingTimeout: return "Processing timed out. Please try again."
        case .processingFailed(let msg): return "Processing failed: \(msg)"
        }
    }
}
