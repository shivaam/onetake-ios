import SwiftUI
import OneTakeKit

struct SessionDetailView: View {
    let sessionId: String
    @State private var viewModel = SessionDetailViewModel()
    @State private var editingLog: ExerciseLog?

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    // Session info header
                    Section {
                        HStack {
                            Label("Duration", systemImage: "clock")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(viewModel.duration)
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Label("Exercises", systemImage: "figure.strengthtraining.traditional")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(viewModel.groupedExercises.count)")
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Label("Total Sets", systemImage: "number")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(viewModel.totalSets)")
                                .fontWeight(.semibold)
                        }
                    }

                    // Exercises
                    Section("Exercises") {
                        ForEach(viewModel.groupedExercises) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.name)
                                    .font(.headline)

                                ForEach(Array(group.allSets.enumerated()), id: \.offset) { index, setData in
                                    HStack {
                                        Text("Set \(index + 1)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 44, alignment: .leading)

                                        Text(setData.weightRepsDisplay)
                                            .font(.subheadline)
                                            .monospacedDigit()

                                        Spacer()
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let firstLog = group.logs.first {
                                    editingLog = firstLog
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingLog) { log in
            NavigationStack {
                EditExerciseView(exerciseLog: log) {
                    Task { await viewModel.refreshLogs() }
                }
            }
        }
        .task {
            await viewModel.load(sessionId: sessionId)
        }

        if let error = viewModel.error {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }
}
