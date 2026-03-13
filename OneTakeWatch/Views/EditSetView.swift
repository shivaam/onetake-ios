import SwiftUI
import OneTakeKit

struct EditSetView: View {
    let exerciseLog: ExerciseLog
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var sets: [SetData]
    @State private var selectedSetIndex = 0
    @State private var isSaving = false
    @State private var error: String?

    private let exerciseLogService = ExerciseLogService()

    init(exerciseLog: ExerciseLog, onSave: @escaping () -> Void) {
        self.exerciseLog = exerciseLog
        self.onSave = onSave
        self._sets = State(initialValue: exerciseLog.sets)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text(exerciseLog.displayName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .lineLimit(1)

                if sets.isEmpty {
                    Text("No sets")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    // Set selector
                    HStack {
                        Button {
                            if selectedSetIndex > 0 { selectedSetIndex -= 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.caption2)
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedSetIndex == 0)

                        Text("Set \(selectedSetIndex + 1) of \(sets.count)")
                            .font(.caption2)
                            .monospacedDigit()

                        Button {
                            if selectedSetIndex < sets.count - 1 { selectedSetIndex += 1 }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedSetIndex >= sets.count - 1)
                    }
                    .padding(.bottom, 4)

                    // Weight field (Digital Crown adjustable)
                    if sets[selectedSetIndex].w != nil {
                        VStack(spacing: 2) {
                            Text("WEIGHT")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .tracking(1)

                            let weight = Binding(
                                get: { sets[selectedSetIndex].w ?? 0 },
                                set: { sets[selectedSetIndex].w = $0 }
                            )
                            Text(String(format: weight.wrappedValue.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", weight.wrappedValue))
                                .font(.title3)
                                .fontWeight(.bold)
                                .monospacedDigit()
                                #if os(watchOS)
                                .focusable()
                                .digitalCrownRotation(weight, from: 0, through: 999, by: 2.5, sensitivity: .medium)
                                #endif
                        }
                    }

                    // Reps field
                    if sets[selectedSetIndex].r != nil {
                        VStack(spacing: 2) {
                            Text("REPS")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .tracking(1)

                            let reps = Binding(
                                get: { sets[selectedSetIndex].r ?? 0 },
                                set: { sets[selectedSetIndex].r = $0 }
                            )
                            Text(String(format: "%.0f", reps.wrappedValue))
                                .font(.title3)
                                .fontWeight(.bold)
                                .monospacedDigit()
                                #if os(watchOS)
                                .focusable()
                                .digitalCrownRotation(reps, from: 0, through: 999, by: 1, sensitivity: .medium)
                                #endif
                        }
                    }
                }

                // Save / Delete buttons
                HStack(spacing: 8) {
                    Button {
                        Task { await save() }
                    } label: {
                        Text("Save")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(isSaving)

                    Button(role: .destructive) {
                        Task { await deleteLog() }
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isSaving)
                }

                if let error {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func save() async {
        isSaving = true
        do {
            _ = try await exerciseLogService.update(id: exerciseLog.id, sets: sets, notes: nil)
            onSave()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }

    private func deleteLog() async {
        isSaving = true
        do {
            try await exerciseLogService.delete(id: exerciseLog.id)
            onSave()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }
}
