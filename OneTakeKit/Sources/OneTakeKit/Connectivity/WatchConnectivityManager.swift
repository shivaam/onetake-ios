import Foundation

#if os(iOS) || os(watchOS)
import WatchConnectivity

/// Manages auth token transfer between iPhone and Apple Watch.
/// On iPhone: sends tokens after sign-in.
/// On Watch: receives tokens and configures Supabase client.
@Observable
public final class WatchConnectivityManager: NSObject, WCSessionDelegate, @unchecked Sendable {
    public static let shared = WatchConnectivityManager()

    public var isReachable = false
    public var hasReceivedAuth = false

    private var wcSession: WCSession?

    private override init() {
        super.init()
    }

    public func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        wcSession = session
    }

    // MARK: - iPhone side: Send auth to Watch

    /// Send auth credentials to the paired Watch.
    public func sendAuthToWatch(accessToken: String, refreshToken: String, supabaseURL: String, supabaseKey: String) {
        guard let session = wcSession, session.activationState == .activated else { return }

        let context: [String: Any] = [
            "accessToken": accessToken,
            "refreshToken": refreshToken,
            "supabaseURL": supabaseURL,
            "supabaseKey": supabaseKey,
        ]

        // Use application context so the Watch gets the latest even if not reachable now
        try? session.updateApplicationContext(context)
    }

    // MARK: - Watch side: Receive auth

    #if os(watchOS)
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleReceivedAuth(applicationContext)
    }

    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handleReceivedAuth(userInfo)
    }

    private func handleReceivedAuth(_ info: [String: Any]) {
        guard let accessToken = info["accessToken"] as? String,
              let refreshToken = info["refreshToken"] as? String,
              let urlString = info["supabaseURL"] as? String,
              let anonKey = info["supabaseKey"] as? String,
              let url = URL(string: urlString) else {
            return
        }

        // Store in UserDefaults for persistence
        let defaults = UserDefaults.standard
        defaults.set(accessToken, forKey: "supabase_access_token")
        defaults.set(refreshToken, forKey: "supabase_refresh_token")
        defaults.set(urlString, forKey: "supabase_url")
        defaults.set(anonKey, forKey: "supabase_key")

        // Configure Supabase client
        SupabaseManager.shared.configure(url: url, anonKey: anonKey)

        Task { @MainActor in
            self.hasReceivedAuth = true
        }
    }
    #endif

    // MARK: - WCSessionDelegate required methods

    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }

        #if os(watchOS)
        // On Watch activation, check if we already have stored credentials
        if let urlString = UserDefaults.standard.string(forKey: "supabase_url"),
           let anonKey = UserDefaults.standard.string(forKey: "supabase_key"),
           let url = URL(string: urlString) {
            SupabaseManager.shared.configure(url: url, anonKey: anonKey)
            Task { @MainActor in
                self.hasReceivedAuth = true
            }
        }

        // Also check application context in case we missed the update
        if !session.receivedApplicationContext.isEmpty {
            handleReceivedAuth(session.receivedApplicationContext)
        }
        #endif
    }

    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    public func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }
}

#else

// Stub for macOS builds (SPM resolution)
@Observable
public final class WatchConnectivityManager: @unchecked Sendable {
    public static let shared = WatchConnectivityManager()
    public var isReachable = false
    public var hasReceivedAuth = false
    public func activate() {}
    public func sendAuthToWatch(accessToken: String, refreshToken: String, supabaseURL: String, supabaseKey: String) {}
}

#endif
