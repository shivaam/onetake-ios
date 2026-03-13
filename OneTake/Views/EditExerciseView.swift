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
        // Use sets as-is — fields only show when the value is non-nil
        // This correctly handles all set types (weight/reps, bodyweight, duration)
        self._sets = State(initialValue: exerciseLog.sets)
    }

    var body: some View {
        List {
            // Exercise name header
            Section {
                Text(exerciseLog.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .listRowBackground(Color.clear)
            }

            // Sets
            ForEach(Array(sets.enumerated()), id: \.offset) { index, _ in
                Section {
                    setEditor(index: index)
                } header: {
                    HStack {
                        Text("Set \(index + 1)")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        if sets.count > 1 {
                            Button("Delete") {
                                withAnimation { sets.remove(at: index) }
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                        }
                    }
                }
            }

            // Add set
            Section {
                Button {
                    let lastSet = sets.last ?? SetData(w: 0, r: 0)
                    withAnimation { sets.append(lastSet) }
                } label: {
                    Label("Add Set", systemImage: "plus.circle.fill")
                        .font(.callout)
                        .foregroundStyle(.green)
                }
            }

            // Delete exercise
            Section {
                Button(role: .destructive) {
                    Task { await deleteLog() }
                } label: {
                    HStack {
                        Spacer()
                        Label("Delete Exercise", systemImage: "trash")
                        Spacer()
                    }
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
                Button("Back") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .fontWeight(.bold)
                .foregroundStyle(.green)
                .disabled(isSaving)
            }
        }
    }

    // MARK: - Set Editor

    @ViewBuilder
    private func setEditor(index: Int) -> some View {
        if sets[index].w != nil || sets[index].r != nil {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WEIGHT (LBS)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    let weight = Binding(
                        get: { sets[index].w ?? 0 },
                        set: { sets[index].w = $0 }
                    )
                    TextField("0", value: weight, format: .number)
                        .keyboardType(.decimalPad)
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .multilineTextAlignment(.center)
                        .padding(10)
                        .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("REPS")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    let reps = Binding(
                        get: { Int(sets[index].r ?? 0) },
                        set: { sets[index].r = Double($0) }
                    )
                    TextField("0", value: reps, format: .number)
                        .keyboardType(.numberPad)
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .multilineTextAlignment(.center)
                        .padding(10)
                        .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }

        if sets[index].t != nil || sets[index].d != nil {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TIME (SEC)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    let time = Binding(
                        get: { Int(sets[index].t ?? 0) },
                        set: { sets[index].t = Double($0) }
                    )
                    TextField("0", value: time, format: .number)
                        .keyboardType(.numberPad)
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .multilineTextAlignment(.center)
                        .padding(10)
                        .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("DISTANCE (M)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    let dist = Binding(
                        get: { Int(sets[index].d ?? 0) },
                        set: { sets[index].d = Double($0) }
                    )
                    TextField("0", value: dist, format: .number)
                        .keyboardType(.numberPad)
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .multilineTextAlignment(.center)
                        .padding(10)
                        .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    // MARK: - Actions

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
