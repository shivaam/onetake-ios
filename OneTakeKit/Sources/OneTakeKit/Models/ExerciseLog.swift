import Foundation

public struct ExerciseLog: Codable, Identifiable, Sendable {
    public let id: String
    public let sessionId: String
    public let inputMessageId: String?
    public let userId: String
    public let exerciseId: String?
    public let rawLabel: String
    public var sets: [SetData]
    public let notes: String?
    public let setOrder: Int
    public let createdAt: String
    public let exercise: Exercise?

    enum CodingKeys: String, CodingKey {
        case id, sets, notes, exercise
        case sessionId = "session_id"
        case inputMessageId = "input_message_id"
        case userId = "user_id"
        case exerciseId = "exercise_id"
        case rawLabel = "raw_label"
        case setOrder = "set_order"
        case createdAt = "created_at"
    }

    /// Display name — prefer exercise.name, fall back to rawLabel
    public var displayName: String {
        exercise?.name ?? rawLabel
    }
}

/// Grouping helper: exercises grouped by name with all their sets
public struct GroupedExercise: Identifiable, Sendable {
    public let id: String // exercise_id or rawLabel
    public let name: String
    public let setType: SetType?
    public let logs: [ExerciseLog]

    public var allSets: [SetData] {
        logs.flatMap(\.sets)
    }

    public init(id: String, name: String, setType: SetType?, logs: [ExerciseLog]) {
        self.id = id
        self.name = name
        self.setType = setType
        self.logs = logs
    }
}

/// Groups exercise logs by exercise, preserving order of first appearance
public func groupExerciseLogs(_ logs: [ExerciseLog]) -> [GroupedExercise] {
    var groups: [String: (name: String, setType: SetType?, logs: [ExerciseLog])] = [:]
    var order: [String] = []

    for log in logs {
        let key = log.exerciseId ?? log.rawLabel
        if groups[key] == nil {
            groups[key] = (name: log.displayName, setType: log.exercise?.setType, logs: [])
            order.append(key)
        }
        groups[key]?.logs.append(log)
    }

    return order.compactMap { key in
        guard let group = groups[key] else { return nil }
        return GroupedExercise(id: key, name: group.name, setType: group.setType, logs: group.logs)
    }
}
