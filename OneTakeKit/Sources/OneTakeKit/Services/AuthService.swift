import Foundation
import Supabase
import Auth

/// Simple token pair for passing auth credentials without exposing Supabase types.
public struct AuthTokens: Sendable {
    public let accessToken: String
    public let refreshToken: String
}

public protocol AuthServiceProtocol: Sendable {
    func signInWithPassword(email: String, password: String) async throws
    func signUp(email: String, password: String) async throws
    func signOut() async throws
    var isAuthenticated: Bool { get async }
    var accessToken: String? { get async }
    var tokens: AuthTokens? { get async }
}

public struct AuthService: AuthServiceProtocol {
    private var auth: AuthClient { SupabaseManager.shared.client.auth }

    public init() {}

    public func signInWithPassword(email: String, password: String) async throws {
        try await auth.signIn(email: email, password: password)
    }

    public func signUp(email: String, password: String) async throws {
        try await auth.signUp(email: email, password: password)
    }

    public func signOut() async throws {
        try await auth.signOut()
    }

    public var isAuthenticated: Bool {
        get async {
            (try? await auth.session) != nil
        }
    }

    public var accessToken: String? {
        get async {
            try? await auth.session.accessToken
        }
    }

    public var tokens: AuthTokens? {
        get async {
            guard let session = try? await auth.session else { return nil }
            return AuthTokens(accessToken: session.accessToken, refreshToken: session.refreshToken)
        }
    }
}
