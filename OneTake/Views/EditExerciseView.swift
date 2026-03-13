import SwiftUI
import OneTakeKit

struct EditExerciseView: View {
    let exerciseLog: ExerciseLog
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var sets: [SetData]
    @State private var isSaving = false
    @State private var error: String?

    private let exerciseLogService = ExerciseLogService()

    init(exerciseLog: ExerciseLog, onSave: @escaping () -> Void) {
        self.exerciseLog = exerciseLog
        self.onSave = onSave
        self._sets = State(initialValue: exerciseLog.sets)
    }

    var body: some View {
        List {
            Section {
                Text(exerciseLog.displayName)
                    .font(.headline)
            }

            Section("Sets") {
                ForEach(Array(sets.enumerated()), id: \.offset) { index, _ in
                    HStack(spacing: 16) {
                        Text("Set \(index + 1)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 44)

                        // Weight
                        if sets[index].w != nil {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Weight")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)

                                let weight = Binding(
                                    get: { sets[index].w ?? 0 },
                                    set: { sets[index].w = $0 }
                                )
                                TextField("0", value: weight, format: .number)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                            }
                        }

                        // Reps
                        if sets[index].r != nil {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reps")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)

                                let reps = Binding(
                                    get: { Int(sets[index].r ?? 0) },
                                    set: { sets[index].r = Double($0) }
                                )
                                TextField("0", value: reps, format: .number)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                            }
                        }

                        Spacer()

                        // Delete set
                        if sets.count > 1 {
                            Button(role: .destructive) {
                                sets.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Add set
                Button {
                    let lastSet = sets.last ?? SetData(w: 0, r: 0)
                    sets.append(lastSet)
                } label: {
                    Label("Add Set", systemImage: "plus.circle.fill")
                        .font(.callout)
                }
            }

            Section {
                // Delete exercise
                Button(role: .destructive) {
                    Task { await deleteLog() }
                } label: {
                    Label("Delete Exercise", systemImage: "trash")
                }
                .disabled(isSaving)
            }

            if let error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Edit Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .fontWeight(.bold)
                .disabled(isSaving)
            }
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
