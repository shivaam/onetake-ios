import Foundation

public enum SessionStatus: String, Codable, Sendable {
    case active
    case completed
}

public struct Session: Codable, Identifiable, Sendable {
    public let id: String
    public let userId: String
    public let status: SessionStatus
    public let startedAt: String
    public let endedAt: String?
    public let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, status
        case userId = "user_id"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case createdAt = "created_at"
    }
}

public struct ActiveSessionResponse: Codable, Sendable {
    public let id: String
    public let startedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case startedAt = "started_at"
    }
}

public struct StartSessionResponse: Codable, Sendable {
    public let success: Bool
    public let sessionId: String?
    public let message: String?

    enum CodingKeys: String, CodingKey {
        case success
        case sessionId = "session_id"
        case message
    }
}
