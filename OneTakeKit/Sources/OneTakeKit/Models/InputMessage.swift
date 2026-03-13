import Foundation

public enum InputMessageStatus: String, Codable, Sendable {
    case processing
    case completed
    case failed
}

public struct InputMessage: Codable, Identifiable, Sendable {
    public let id: String
    public let status: InputMessageStatus
    public let content: String?
    public let errorMessage: String?
    public let isWorkoutRelated: Bool?

    enum CodingKeys: String, CodingKey {
        case id, status, content
        case errorMessage = "error_message"
        case isWorkoutRelated = "is_workout_related"
    }
}

public struct UploadResponse: Codable, Sendable {
    public let success: Bool
    public let inputMessageId: String
    public let status: String
    public let message: String

    enum CodingKeys: String, CodingKey {
        case success, status, message
        case inputMessageId = "inputMessageId"
    }
}
