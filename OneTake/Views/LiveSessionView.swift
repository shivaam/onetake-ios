import SwiftUI
import OneTakeKit

struct LiveSessionView: View {
    @Bindable var viewModel: LiveSessionViewModel
    @State private var selectedTab = 0
    @State private var showEndConfirmation = false
    @State private var editingLog: ExerciseLog?

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.hasActiveSession {
                activeSessionContent
            } else if viewModel.sessionEnded {
                sessionEndedContent
            } else {
                noSessionContent
            }
        }
        .task {
            await viewModel.checkForActiveSession()
        }
    }

    // MARK: - Active Session

    private var activeSessionContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.elapsedFormatted)
                        .font(.title)
                        .fontWeight(.heavy)
                        .foregroundStyle(.green)
                        .monospacedDigit()

                    Text("Workout in progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("End") {
                    showEndConfirmation = true
                }
                .font(.callout)
                .fontWeight(.bold)
                .foregroundStyle(.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.red.opacity(0.1), in: Capsule())
            }
            .padding()

            // Tab picker
            Picker("View", selection: $selectedTab) {
                Text("Feed").tag(0)
                Text("Summary").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Content
            if selectedTab == 0 {
                feedTab
            } else {
                summaryTab
            }

            Spacer(minLength: 0)

            // Mic button
            micButton
                .padding()
        }
        .confirmationDialog("End workout?", isPresented: $showEndConfirmation) {
            Button("End Workout", role: .destructive) {
                Task { await viewModel.endSession() }
            }
        }
        .sheet(item: $editingLog) { log in
            NavigationStack {
                EditExerciseView(exerciseLog: log) {
                    Task { await viewModel.refreshLogs() }
                }
            }
        }
    }

    // MARK: - Feed Tab

    private var feedTab: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(viewModel.exerciseLogs) { log in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.body)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.displayName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(log.sets.map(\.weightRepsDisplay).joined(separator: "  "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                    .id(log.id)
                }

                if viewModel.isProcessing {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text(viewModel.processingStatus ?? "Processing...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .id("processing")
                }
            }
            .listStyle(.plain)
            .onChange(of: viewModel.exerciseLogs.count) {
                if let last = viewModel.exerciseLogs.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Summary Tab

    private var summaryTab: some View {
        List {
            if viewModel.groupedExercises.isEmpty {
                Text("No exercises yet. Tap the mic to start logging.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.groupedExercises) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.name)
                            .font(.headline)

                        // Sets as pills
                        HStack(spacing: 6) {
                            ForEach(Array(group.allSets.enumerated()), id: \.offset) { _, setData in
                                Text(setData.weightRepsDisplay)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .monospacedDigit()
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let firstLog = group.logs.first {
                            editingLog = firstLog
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Mic Button

    private var micButton: some View {
        VStack(spacing: 8) {
            Button {
                viewModel.toggleRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            viewModel.isProcessing ? Color.orange :
                            viewModel.isRecording ? Color.red :
                            Color.green
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: .green.opacity(0.3), radius: 15)

                    if viewModel.isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
            }
            .disabled(viewModel.isProcessing)

            if let error = viewModel.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - No Session

    private var noSessionContent: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "figure.run")
                .font(.system(size: 48))
                .foregroundStyle(.green.opacity(0.5))

            Text("Ready to work out?")
                .font(.title2)
                .fontWeight(.bold)

            Button {
                Task { await viewModel.startSession() }
            } label: {
                Label("Start Workout", systemImage: "play.fill")
                    .font(.callout)
                    .fontWeight(.bold)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .foregroundStyle(.black)

            Spacer()
        }
    }

    // MARK: - Session Ended

    private var sessionEndedContent: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            Text("Workout Complete")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 8) {
                HStack {
                    Text("Duration")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(viewModel.elapsedFormatted)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
                HStack {
                    Text("Exercises")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(viewModel.groupedExercises.count)")
                        .fontWeight(.semibold)
                }
                HStack {
                    Text("Sets")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(viewModel.totalSets)")
                        .fontWeight(.semibold)
                }
            }
            .font(.callout)
            .padding()
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 32)

            Spacer()

            Button("Start New Workout") {
                viewModel.reset()
            }
            .font(.callout)
            .fontWeight(.bold)
            .padding(.bottom, 32)
        }
    }
}
