import Foundation
import OneTakeKit

@Observable
final class AuthViewModel {
    var email = ""
    var password = ""
    var isSignUp = false
    var isLoading = false
    var error: String?
    var isAuthenticated = false

    private let authService = AuthService()

    func checkAuth() async {
        if await authService.isAuthenticated {
            isAuthenticated = true
            sendAuthToWatch()
        }
    }

    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            error = "Please fill in all fields"
            return
        }

        isLoading = true
        error = nil

        do {
            if isSignUp {
                try await authService.signUp(email: email, password: password)
            } else {
                try await authService.signInWithPassword(email: email, password: password)
            }
            isAuthenticated = true
            sendAuthToWatch()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func signOut() async {
        do {
            try await authService.signOut()
            isAuthenticated = false
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func sendAuthToWatch() {
        Task {
            guard let tokens = await authService.tokens else { return }
            let url = SupabaseManager.shared.supabaseURL.absoluteString
            if let path = Bundle.main.path(forResource: "Supabase", ofType: "plist"),
               let dict = NSDictionary(contentsOfFile: path),
               let anonKey = dict["SUPABASE_ANON_KEY"] as? String {
                WatchConnectivityManager.shared.sendAuthToWatch(
                    accessToken: tokens.accessToken,
                    refreshToken: tokens.refreshToken,
                    supabaseURL: url,
                    supabaseKey: anonKey
                )
            }
        }
    }
}
