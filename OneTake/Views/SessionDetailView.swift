import SwiftUI
import OneTakeKit

struct SessionDetailView: View {
    let sessionId: String
    @State private var viewModel = SessionDetailViewModel()
    @State private var editingGroup: GroupedExercise?

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        statsRow
                        exercisesSection
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingGroup) { group in
            NavigationStack {
                if let firstLog = group.logs.first {
                    EditExerciseView(exerciseLog: firstLog) {
                        Task { await viewModel.refreshLogs() }
                    }
                }
            }
        }
        .task {
            await viewModel.load(sessionId: sessionId)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(sessionTitle)
                    .font(.title)
                    .fontWeight(.bold)

                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(viewModel.duration)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.15), in: Capsule())
        }
        .padding(.horizontal)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            DetailStatCard(value: "\(viewModel.groupedExercises.count)", label: "EXERCISES")
            DetailStatCard(value: "\(viewModel.totalSets)", label: "SETS")
            DetailStatCard(
                value: formatVolume(viewModel.totalVolume),
                label: "VOLUME",
                color: .orange
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Exercises

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercises")
                .font(.headline)
                .padding(.horizontal)

            ForEach(viewModel.groupedExercises) { group in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(group.name)
                            .font(.subheadline)
                            .fontWeight(.bold)

                        Spacer()

                        Button {
                            editingGroup = group
                        } label: {
                            Text("Edit")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }

                    ForEach(Array(group.allSets.enumerated()), id: \.offset) { index, setData in
                        HStack {
                            Text("Set \(index + 1)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 44, alignment: .leading)

                            Text(formatSetDisplay(setData, setType: group.setType))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .monospacedDigit()

                            Spacer()
                        }
                        .padding(.leading, 4)
                    }
                }
                .padding()
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Helpers

    private var sessionTitle: String {
        if let firstExercise = viewModel.groupedExercises.first?.logs.first?.exercise,
           let muscle = firstExercise.muscleGroup {
            return muscle.capitalized
        }
        return "Workout"
    }

    private var formattedDate: String {
        guard let session = viewModel.session,
              let date = parseDate(session.startedAt) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    private func parseDate(_ s: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: s)
    }

    private func formatSetDisplay(_ set: SetData, setType: SetType?) -> String {
        switch setType {
        case .bodyweightReps:
            let r = set.r.map { String(format: "%.0f", $0) } ?? "?"
            return "BW × \(r) reps"
        case .weightedBodyweight:
            let w = set.w.map { String(format: "+%.0f", $0) } ?? "?"
            let r = set.r.map { String(format: "%.0f", $0) } ?? "?"
            return "\(w) lbs × \(r) reps"
        case .assistedBodyweight:
            let w = set.w.map { String(format: "%.0f", abs($0)) } ?? "?"
            let r = set.r.map { String(format: "%.0f", $0) } ?? "?"
            return "\(w) lbs assist × \(r) reps"
        case .durationDistance:
            let t = set.t.map { formatDuration(Int($0)) } ?? "?"
            let d = set.d.map { formatDistance($0) } ?? "?"
            return "\(t) — \(d)"
        default:
            let w = set.w.map { String(format: $0.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", $0) } ?? "?"
            let r = set.r.map { String(format: "%.0f", $0) } ?? "?"
            return "\(w) lbs × \(r) reps"
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let min = seconds / 60
        let sec = seconds % 60
        return sec == 0 ? "\(min)m" : "\(min)m \(sec)s"
    }

    private func formatDistance(_ meters: Double) -> String {
        meters < 1000 ? "\(Int(meters))m" : String(format: "%.2fkm", meters / 1000)
    }

    private func formatVolume(_ v: Double) -> String {
        if v >= 1000 { return String(format: "%.1fk", v / 1000) }
        return String(format: "%.0f", v)
    }
}

// MARK: - Detail Stat Card

private struct DetailStatCard: View {
    let value: String
    let label: String
    var color: Color = .primary

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
        .padding(.vertical, 12)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
    }
}
