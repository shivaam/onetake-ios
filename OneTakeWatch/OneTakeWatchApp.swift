import SwiftUI
import OneTakeKit

@main
struct OneTakeWatchApp: App {
    @State private var connectivityManager = WatchConnectivityManager.shared

    init() {
        WatchConnectivityManager.shared.activate()

        // Try to configure from stored credentials
        if let urlString = UserDefaults.standard.string(forKey: "supabase_url"),
           let anonKey = UserDefaults.standard.string(forKey: "supabase_key"),
           let url = URL(string: urlString) {
            SupabaseManager.shared.configure(url: url, anonKey: anonKey)
        }
    }

    var body: some Scene {
        WindowGroup {
            if connectivityManager.hasReceivedAuth {
                StartView()
            } else {
                WatchNeedsAuthView()
            }
        }
    }
}

struct WatchNeedsAuthView: View {
    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "iphone")
                .font(.largeTitle)
                .foregroundStyle(.green.opacity(0.5))

            Text("Open OneTake on iPhone")
                .font(.callout)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text("Sign in to get started")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }
}
