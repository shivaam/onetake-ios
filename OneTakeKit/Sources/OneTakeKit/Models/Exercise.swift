import Foundation

public enum SetType: String, Codable, Sendable {
    case weightReps = "WEIGHT_REPS"
    case bodyweightReps = "BODYWEIGHT_REPS"
    case weightedBodyweight = "WEIGHTED_BODYWEIGHT"
    case assistedBodyweight = "ASSISTED_BODYWEIGHT"
    case durationDistance = "DURATION_DISTANCE"
}

/// Represents a single set within an exercise log.
/// Uses short keys matching the JSONB format: w (weight), r (reps), t (time), d (distance).
public struct SetData: Codable, Sendable, Equatable {
    public var w: Double?
    public var r: Double?
    public var t: Double?
    public var d: Double?

    public init(w: Double? = nil, r: Double? = nil, t: Double? = nil, d: Double? = nil) {
        self.w = w
        self.r = r
        self.t = t
        self.d = d
    }

    /// Display string for weight/reps sets (e.g. "135x8")
    public var weightRepsDisplay: String {
        let weight = w.map { String(format: $0.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", $0) } ?? "?"
        let reps = r.map { String(format: "%.0f", $0) } ?? "?"
        return "\(weight)x\(reps)"
    }
}

public struct Exercise: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let setType: SetType
    public let muscleGroup: String?
    public let userId: String?
    public let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case setType = "set_type"
        case muscleGroup = "muscle_group"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}
