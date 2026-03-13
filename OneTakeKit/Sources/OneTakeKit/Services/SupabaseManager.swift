import Foundation
import Supabase

/// Central access point for the Supabase client.
/// Initialize once at app launch with config values.
public final class SupabaseManager: @unchecked Sendable {
    public static let shared = SupabaseManager()

    private var _client: SupabaseClient?
    private var _url: URL?

    /// The initialized Supabase client. Crashes if accessed before `configure()`.
    public var client: SupabaseClient {
        guard let c = _client else {
            fatalError("SupabaseManager.configure() must be called before accessing client")
        }
        return c
    }

    private init() {}

    /// Configure the Supabase client. Call once at app startup.
    public func configure(url: URL, anonKey: String) {
        _url = url

        // Derive a safe storage key from the host
        let host = url.host ?? "default"
        let projectRef = host.split(separator: ".").first.map(String.init) ?? host
        let storageKey = "sb-\(projectRef)-auth-token"

        _client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: .init(
                auth: .init(storageKey: storageKey)
            )
        )
    }

    /// Configure from a Supabase.plist in the main bundle.
    public func configureFromPlist() {
        guard let path = Bundle.main.path(forResource: "Supabase", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let urlString = dict["SUPABASE_URL"] as? String,
              let anonKey = dict["SUPABASE_ANON_KEY"] as? String,
              let url = URL(string: urlString) else {
            fatalError("Missing or invalid Supabase.plist")
        }
        configure(url: url, anonKey: anonKey)
    }

    /// The Supabase URL (for building Edge Function URLs).
    public var supabaseURL: URL {
        guard let url = _url else {
            fatalError("SupabaseManager.configure() must be called before accessing supabaseURL")
        }
        return url
    }
}
