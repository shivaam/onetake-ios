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
            headerSection
            setsSection
            addSetSection
            deleteSection
            errorSection
        }
        .navigationTitle("Edit Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Back") { dismiss() }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                saveButton
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section {
            Text(exerciseLog.displayName)
                .font(.title2)
                .fontWeight(.bold)
                .listRowBackground(Color.clear)
        }
    }

    private var setsSection: some View {
        ForEach(Array(sets.enumerated()), id: \.offset) { index, _ in
            Section {
                setEditor(index: index)
            } header: {
                setHeader(index: index)
            }
        }
    }

    private var addSetSection: some View {
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
    }

    private var deleteSection: some View {
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
    }

    @ViewBuilder
    private var errorSection: some View {
        if let error {
            Section {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            Text("Save")
                .fontWeight(.bold)
                .foregroundStyle(Color.green)
        }
        .disabled(isSaving)
    }

    // MARK: - Set Header

    private func setHeader(index: Int) -> some View {
        HStack {
            Text("Set \(index + 1)")
                .font(.subheadline)
                .fontWeight(.semibold)

            Spacer()

            if sets.count > 1 {
                Button("Delete") {
                    withAnimation { _ = sets.remove(at: index) }
                }
                .font(.caption)
                .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Set Editor

    @ViewBuilder
    private func setEditor(index: Int) -> some View {
        if sets[index].w != nil || sets[index].r != nil {
            weightRepsRow(index: index)
        }
        if sets[index].t != nil || sets[index].d != nil {
            timeDurationRow(index: index)
        }
    }

    private func weightRepsRow(index: Int) -> some View {
        HStack(spacing: 16) {
            numericField(
                label: "WEIGHT (LBS)",
                value: Binding(
                    get: { sets[index].w ?? 0 },
                    set: { sets[index].w = $0 }
                ),
                keyboard: .decimalPad
            )
            numericField(
                label: "REPS",
                value: Binding(
                    get: { sets[index].r ?? 0 },
                    set: { sets[index].r = $0 }
                ),
                keyboard: .numberPad
            )
        }
    }

    private func timeDurationRow(index: Int) -> some View {
        HStack(spacing: 16) {
            numericField(
                label: "TIME (SEC)",
                value: Binding(
                    get: { sets[index].t ?? 0 },
                    set: { sets[index].t = $0 }
                ),
                keyboard: .numberPad
            )
            numericField(
                label: "DISTANCE (M)",
                value: Binding(
                    get: { sets[index].d ?? 0 },
                    set: { sets[index].d = $0 }
                ),
                keyboard: .numberPad
            )
        }
    }

    private func numericField(label: String, value: Binding<Double>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            TextField("0", value: value, format: .number)
                .keyboardType(keyboard)
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .padding(10)
                .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
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
