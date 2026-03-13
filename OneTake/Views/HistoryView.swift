import SwiftUI
import OneTakeKit

struct HistoryView: View {
    @State private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.sessions.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.sessions.isEmpty {
                    ContentUnavailableView(
                        "No workouts yet",
                        systemImage: "figure.run",
                        description: Text("Complete a workout to see it here.")
                    )
                } else {
                    List(viewModel.sessions) { session in
                        NavigationLink(value: session.id) {
                            SessionRow(session: session)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.load()
                    }
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: String.self) { sessionId in
                SessionDetailView(sessionId: sessionId)
            }
            .task {
                await viewModel.load()
            }
        }
    }
}

// MARK: - Session Row

private struct SessionRow: View {
    let session: Session

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(duration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var formattedDate: String {
        guard let date = parseDate(session.startedAt) else { return session.startedAt }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private var duration: String {
        guard let start = parseDate(session.startedAt),
              let end = session.endedAt.flatMap({ parseDate($0) }) else {
            return ""
        }
        let interval = end.timeIntervalSince(start)
        let minutes = Int(interval) / 60
        if minutes < 60 { return "\(minutes) min" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString)
    }
}
