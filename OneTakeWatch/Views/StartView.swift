import SwiftUI
import OneTakeKit

struct StartView: View {
    @State private var viewModel = WatchSessionViewModel()
    @State private var navigateToSession = false
    @State private var lastSessionInfo: String?

    private let sessionService = SessionService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()

                // Logo
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.oneTakeGreen, Color.oneTakeGreen.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "mic.fill")
                            .font(.title2)
                            .foregroundStyle(.black)
                    }
                    .shadow(color: Color.oneTakeGreen.opacity(0.3), radius: 15)

                Text("OneTake")
                    .font(.title3)
                    .fontWeight(.heavy)

                Spacer()

                // Start button
                Button {
                    Task {
                        await viewModel.startSession()
                        if viewModel.session != nil {
                            navigateToSession = true
                        }
                    }
                } label: {
                    Text("Start Session")
                        .font(.callout)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.oneTakeGreen)
                .disabled(viewModel.isLoading)

                // Last session info
                if let info = lastSessionInfo {
                    Text(info)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let error = viewModel.error {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.oneTakeRed)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .navigationDestination(isPresented: $navigateToSession) {
                SessionView(viewModel: viewModel)
            }
            .task {
                // Check for existing active session
                await viewModel.checkForActiveSession()
                if viewModel.session != nil {
                    navigateToSession = true
                }

                // Fetch last session info
                await loadLastSession()
            }
        }
    }

    private func loadLastSession() async {
        do {
            let sessions = try await sessionService.fetchHistory()
            if let last = sessions.first {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let start = formatter.date(from: last.startedAt),
                   let end = last.endedAt.flatMap({ formatter.date(from: $0) }) {
                    let minutes = Int(end.timeIntervalSince(start)) / 60
                    lastSessionInfo = "Last: \(minutes) min"
                }
            }
        } catch {
            // Ignore — just don't show last session info
        }
    }
}
