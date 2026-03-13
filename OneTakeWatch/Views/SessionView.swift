import SwiftUI
import OneTakeKit

struct SessionView: View {
    @Bindable var viewModel: WatchSessionViewModel
    @State private var recorder = WatchRecorderViewModel()
    @State private var selectedTab = 0
    @State private var showEndConfirmation = false
    @State private var showRecording = false
    @State private var editingLog: ExerciseLog?

    var body: some View {
        VStack(spacing: 0) {
            // Header: timer + end button
            HStack {
                Text(viewModel.elapsedFormatted)
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundStyle(.green)
                    .monospacedDigit()

                Spacer()

                Button("END") {
                    showEndConfirmation = true
                }
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.red.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)

            // Tab selector
            HStack(spacing: 0) {
                TabButton(title: "FEED", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                TabButton(title: "SUMMARY", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
            }
            .padding(.bottom, 4)

            // Content
            if selectedTab == 0 {
                FeedTabView(logs: viewModel.exerciseLogs, isProcessing: recorder.isProcessing, processingStatus: recorder.processingStatus)
            } else {
                SummaryTabView(groups: viewModel.groupedExercises, onEditLog: { log in
                    editingLog = log
                })
            }

            // Mic button
            Button {
                if recorder.isRecording {
                    recorder.toggleRecording(sessionId: viewModel.session?.id ?? "") {
                        Task { await viewModel.refreshLogs() }
                    }
                } else if recorder.isProcessing {
                    // Do nothing while processing
                } else {
                    showRecording = true
                    recorder.toggleRecording(sessionId: viewModel.session?.id ?? "") {
                        Task { await viewModel.refreshLogs() }
                        showRecording = false
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(recorder.isProcessing ? Color.orange : Color.green)
                        .frame(width: 38, height: 38)
                        .shadow(color: .green.opacity(0.3), radius: 10)

                    if recorder.isProcessing {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                            .font(.body)
                            .foregroundStyle(.black)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(.horizontal, 4)
        .navigationBarBackButtonHidden(true)
        .confirmationDialog("End workout?", isPresented: $showEndConfirmation) {
            Button("End Workout", role: .destructive) {
                Task { await viewModel.endSession() }
            }
        }
        .fullScreenCover(isPresented: $showRecording) {
            RecordingOverlayView(recorder: recorder, sessionId: viewModel.session?.id ?? "") {
                Task { await viewModel.refreshLogs() }
                showRecording = false
            }
        }
        .sheet(item: $editingLog) { log in
            EditSetView(exerciseLog: log) {
                Task { await viewModel.refreshLogs() }
            }
        }
        .navigationDestination(isPresented: $viewModel.sessionEnded) {
            DoneView(viewModel: viewModel)
        }
        .task {
            await viewModel.refreshLogs()
        }

        if let error = recorder.error {
            Text(error)
                .font(.caption2)
                .foregroundStyle(.red)
        }
    }
}

// MARK: - Tab Button

private struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(isSelected ? .green : .secondary)
                    .tracking(0.5)

                Rectangle()
                    .fill(isSelected ? .green : .clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Feed Tab

private struct FeedTabView: View {
    let logs: [ExerciseLog]
    let isProcessing: Bool
    let processingStatus: String?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 3) {
                    ForEach(logs) { log in
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.green)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(log.displayName)
                                    .font(.system(size: 9, weight: .semibold))
                                Text(log.sets.map(\.weightRepsDisplay).joined(separator: ", "))
                                    .font(.system(size: 8))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(6)
                        .background(Color.gray.opacity(0.3), in: RoundedRectangle(cornerRadius: 7))
                        .id(log.id)
                    }

                    if isProcessing {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.6)
                            Text(processingStatus ?? "Processing...")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                        .padding(6)
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 7))
                        .id("processing")
                    }
                }
                .padding(.horizontal, 2)
            }
            .onChange(of: logs.count) {
                if let last = logs.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }
}

// MARK: - Summary Tab

private struct SummaryTabView: View {
    let groups: [GroupedExercise]
    let onEditLog: (ExerciseLog) -> Void

    var body: some View {
        ScrollView {
            if groups.isEmpty {
                Text("No exercises yet")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 20)
            } else {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(groups) { group in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(group.name)
                                    .font(.system(size: 10, weight: .bold))
                                Spacer()
                                Text("tap to edit")
                                    .font(.system(size: 7))
                                    .foregroundStyle(.secondary)
                            }

                            // Set pills
                            FlowLayout(spacing: 4) {
                                ForEach(Array(group.allSets.enumerated()), id: \.offset) { _, set in
                                    Text(set.weightRepsDisplay)
                                        .font(.system(size: 9, design: .monospaced))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(Color.gray.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let firstLog = group.logs.first {
                                onEditLog(firstLog)
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

// MARK: - FlowLayout (simple horizontal wrapping)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? .infinity, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxWidth = max(maxWidth, x)
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
