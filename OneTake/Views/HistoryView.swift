import SwiftUI
import OneTakeKit

struct HistoryView: View {
    @State private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.sessionsWithLogs.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.sessionsWithLogs.isEmpty {
                    ContentUnavailableView(
                        "No workouts yet",
                        systemImage: "figure.run",
                        description: Text("Complete a workout to see it here.")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Stats cards
                            statsSection

                            // Recent workouts
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)

                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.sessionsWithLogs) { swl in
                                        NavigationLink(value: swl.session.id) {
                                            SessionCard(sessionWithLogs: swl)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        await viewModel.load()
                    }
                }
            }
            .navigationTitle("Workouts")
            .navigationDestination(for: String.self) { sessionId in
                SessionDetailView(sessionId: sessionId)
            }
            .task {
                await viewModel.load()
            }
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                value: "\(viewModel.thisMonthCount)",
                label: "This month",
                color: .primary
            )

            StatCard(
                value: formatVolume(viewModel.totalVolumeThisMonth),
                label: "Volume",
                color: .orange
            )

            StatCard(
                value: formatTime(viewModel.totalTimeThisMonth),
                label: "Total time",
                color: .green
            )
        }
        .padding(.horizontal)
    }

    private func formatVolume(_ v: Double) -> String {
        if v >= 1000 {
            return String(format: "%.1fk", v / 1000)
        }
        return String(format: "%.0f", v)
    }

    private func formatTime(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        let hours = Double(minutes) / 60.0
        return String(format: "%.1fh", hours)
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.heavy)
                .foregroundStyle(color)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Session Card

private struct SessionCard: View {
    let sessionWithLogs: SessionWithLogs

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(sessionTitle)
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(sessionWithLogs.duration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(sessionWithLogs.dayLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            // Exercise preview (up to 3)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(sessionWithLogs.groupedExercises.prefix(3)) { group in
                    HStack {
                        Text(group.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 100, alignment: .leading)
                            .lineLimit(1)

                        Text(group.allSets.map(\.weightRepsDisplay).joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                }
            }

            // Footer
            HStack(spacing: 16) {
                Text("\(sessionWithLogs.groupedExercises.count) exercises")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("\(sessionWithLogs.totalSets) sets")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 14))
    }

    private var sessionTitle: String {
        if let firstExercise = sessionWithLogs.groupedExercises.first?.logs.first?.exercise,
           let muscle = firstExercise.muscleGroup {
            return muscle.capitalized
        }
        return "Workout"
    }
}
