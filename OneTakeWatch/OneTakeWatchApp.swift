import SwiftUI
import OneTakeKit

@main
struct OneTakeWatchApp: App {
    @State private var connectivityManager = WatchConnectivityManager.shared
    @State private var watchAuth = WatchAuthState()

    init() {
        WatchConnectivityManager.shared.activate()

        // 1. Try to configure from the Watch bundle's Supabase.plist first
        if let path = Bundle.main.path(forResource: "Supabase", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let urlString = dict["SUPABASE_URL"] as? String,
           let anonKey = dict["SUPABASE_ANON_KEY"] as? String,
           let url = URL(string: urlString) {
            SupabaseManager.shared.configure(url: url, anonKey: anonKey)
        }

        // 2. If WatchConnectivity sent credentials before, those override
        if let urlString = UserDefaults.standard.string(forKey: "supabase_url"),
           let anonKey = UserDefaults.standard.string(forKey: "supabase_key"),
           let url = URL(string: urlString) {
            SupabaseManager.shared.configure(url: url, anonKey: anonKey)
        }
    }

    var body: some Scene {
        WindowGroup {
            if connectivityManager.hasReceivedAuth || watchAuth.isSignedIn {
                StartView()
            } else {
                WatchSignInView(watchAuth: watchAuth)
            }
        }
    }
}

// MARK: - Watch Auth State

@Observable
final class WatchAuthState {
    var isSignedIn = false
    var isLoading = false
    var error: String?

    private let authService = AuthService()

    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil
        do {
            // Configure Supabase from plist if not already done
            configureIfNeeded()
            try await authService.signInWithPassword(email: email, password: password)
            isSignedIn = true
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func checkExistingSession() async {
        // Only check if Supabase is configured (otherwise it would crash)
        guard SupabaseManager.shared.isConfigured else { return }
        isSignedIn = await authService.isAuthenticated
    }

    private func configureIfNeeded() {
        guard !SupabaseManager.shared.isConfigured else { return }
        if let path = Bundle.main.path(forResource: "Supabase", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let urlString = dict["SUPABASE_URL"] as? String,
           let anonKey = dict["SUPABASE_ANON_KEY"] as? String,
           let url = URL(string: urlString) {
            SupabaseManager.shared.configure(url: url, anonKey: anonKey)
        }
    }
}

// MARK: - Watch Sign In View

struct WatchSignInView: View {
    @Bindable var watchAuth: WatchAuthState
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: "mic.fill")
                    .font(.title2)
                    .foregroundStyle(Color.oneTakeGreen)

                Text("OneTake")
                    .font(.headline)
                    .fontWeight(.heavy)

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .font(.caption2)

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .font(.caption2)

                signInButton
                errorText
            }
            .padding(.horizontal, 4)
        }
        .task {
            await watchAuth.checkExistingSession()
        }
    }

    private var signInButton: some View {
        Button {
            Task { await watchAuth.signIn(email: email, password: password) }
        } label: {
            if watchAuth.isLoading {
                ProgressView()
            } else {
                Text("Sign In")
                    .fontWeight(.bold)
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.oneTakeGreen)
        .disabled(email.isEmpty || password.isEmpty || watchAuth.isLoading)
    }

    @ViewBuilder
    private var errorText: some View {
        if let error = watchAuth.error {
            Text(error)
                .font(.caption2)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        }
    }
}
