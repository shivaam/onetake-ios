import Foundation
import Supabase

public protocol ExerciseLogServiceProtocol: Sendable {
    func fetchBySession(_ sessionId: String) async throws -> [ExerciseLog]
    func update(id: String, sets: [SetData]?, notes: String?) async throws -> ExerciseLog
    func delete(id: String) async throws
}

public struct ExerciseLogService: ExerciseLogServiceProtocol {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    public init() {}

    public func fetchBySession(_ sessionId: String) async throws -> [ExerciseLog] {
        try await client
            .from("exercise_logs")
            .select("*, exercise:exercises(*)")
            .eq("session_id", value: sessionId)
            .order("set_order", ascending: true)
            .execute()
            .value
    }

    public func update(id: String, sets: [SetData]?, notes: String?) async throws -> ExerciseLog {
        var updates: [String: AnyJSON] = [:]
        if let sets {
            let encoded = try JSONEncoder().encode(sets)
            let json = try JSONDecoder().decode(AnyJSON.self, from: encoded)
            updates["sets"] = json
        }
        if let notes {
            updates["notes"] = .string(notes)
        }

        return try await client
            .from("exercise_logs")
            .update(updates)
            .eq("id", value: id)
            .select("*, exercise:exercises(*)")
            .single()
            .execute()
            .value
    }

    public func delete(id: String) async throws {
        try await client
            .from("exercise_logs")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}
