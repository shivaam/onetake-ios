import SwiftUI
import OneTakeKit

struct LiveSessionView: View {
    @Bindable var viewModel: LiveSessionViewModel
    @State private var selectedTab = 0
    @State private var showEndConfirmation = false
    @State private var editingLog: ExerciseLog?
    @State private var textInput = ""
    @FocusState private var isTextFieldFocused: Bool

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

    @State private var activeDotVisible = true

    private var activeSessionContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    // SESSION ACTIVE badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.oneTakeGreen)
                            .frame(width: 8, height: 8)
                            .opacity(activeDotVisible ? 1 : 0.3)
                            .animation(.easeInOut(duration: 1).repeatForever(), value: activeDotVisible)
                            .onAppear { activeDotVisible.toggle() }

                        Text("SESSION ACTIVE")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.oneTakeGreen)
                    }

                    Text(viewModel.elapsedFormatted)
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundStyle(Color.oneTakeGreen)
                        .monospacedDigit()

                    Text("\(viewModel.groupedExercises.count) exercises logged")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("End Session") {
                    showEndConfirmation = true
                }
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(Color.oneTakeRed)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.oneTakeRed.opacity(0.15), in: Capsule())
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

            // Input bar
            inputBar
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
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.exerciseLogs) { log in
                        // Parsed exercise item
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.oneTakeGreen)
                                .font(.body)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(log.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text(formatSetsSummary(log))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }

                            Spacer()

                            Button {
                                editingLog = log
                            } label: {
                                Text("Edit >")
                                    .font(.caption)
                                    .foregroundStyle(Color.oneTakeGreen)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                        .id(log.id)
                    }

                    if viewModel.isProcessing {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text(viewModel.processingStatus ?? "Processing...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .id("processing")
                    }
                }
                .padding(.vertical, 8)
            }
            .onChange(of: viewModel.exerciseLogs.count) {
                if let last = viewModel.exerciseLogs.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func formatSetsSummary(_ log: ExerciseLog) -> String {
        let setType = log.exercise?.setType
        return log.sets.map { set in
            switch setType {
            case .bodyweightReps:
                return "BW x \(set.r.map { String(format: "%.0f", $0) } ?? "?")"
            case .durationDistance:
                return set.t.map { "\(Int($0))s" } ?? "?"
            default:
                return set.weightRepsDisplay
            }
        }.joined(separator: " · ")
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
                        HStack {
                            Text(group.name)
                                .font(.headline)

                            Spacer()

                            Text("tap to edit")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        // Set pills
                        FlowLayout(spacing: 6) {
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

    // MARK: - Input Bar (text + mic)

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()

            if let error = viewModel.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }

            HStack(spacing: 12) {
                // Text field
                TextField("Type or tap mic...", text: $textInput)
                    .font(.callout)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 20))
                    .focused($isTextFieldFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        sendText()
                    }

                // Mic / Send button
                Button {
                    if !textInput.isEmpty {
                        sendText()
                    } else {
                        viewModel.toggleRecording()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(buttonColor)
                            .frame(width: 44, height: 44)

                        if viewModel.isProcessing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: buttonIcon)
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .disabled(viewModel.isProcessing)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(.ultraThinMaterial)
    }

    private var buttonColor: Color {
        if !textInput.isEmpty { return .oneTakeGreen }
        if viewModel.isProcessing { return .oneTakeOrange }
        if viewModel.isRecording { return .oneTakeRed }
        return .oneTakeGreen
    }

    private var buttonIcon: String {
        if !textInput.isEmpty { return "arrow.up" }
        if viewModel.isRecording { return "stop.fill" }
        return "mic.fill"
    }

    private func sendText() {
        let text = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        textInput = ""
        isTextFieldFocused = false
        Task { await viewModel.sendText(text) }
    }

    // MARK: - No Session

    private var noSessionContent: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "figure.run")
                .font(.system(size: 48))
                .foregroundStyle(Color.oneTakeGreen.opacity(0.5))

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
            .tint(.oneTakeGreen)
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
                .foregroundStyle(Color.oneTakeGreen)

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

// MARK: - Flow Layout (for set pills)

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}
