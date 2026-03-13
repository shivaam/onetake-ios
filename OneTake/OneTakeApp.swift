import SwiftUI
import OneTakeKit

@main
struct OneTakeApp: App {
    @State private var authViewModel = AuthViewModel()

    init() {
        SupabaseManager.shared.configureFromPlist()
        WatchConnectivityManager.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView(authViewModel: authViewModel)
            } else {
                AuthView(viewModel: authViewModel)
            }
        }
    }
}

struct MainTabView: View {
    @Bindable var authViewModel: AuthViewModel
    @State private var liveSessionViewModel = LiveSessionViewModel()

    var body: some View {
        TabView {
            Tab("Workout", systemImage: "mic.fill") {
                LiveSessionView(viewModel: liveSessionViewModel)
            }

            Tab("History", systemImage: "clock") {
                HistoryView()
            }

            Tab("Settings", systemImage: "gearshape") {
                SettingsView(authViewModel: authViewModel)
            }
        }
        .tint(.green)
    }
}

// MARK: - Settings (minimal)

struct SettingsView: View {
    @Bindable var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(role: .destructive) {
                        Task { await authViewModel.signOut() }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
