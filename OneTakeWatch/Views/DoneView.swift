import SwiftUI
import OneTakeKit

struct DoneView: View {
    @Bindable var viewModel: WatchSessionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.green)

            Text("Workout Complete")
                .font(.callout)
                .fontWeight(.bold)

            // Stats
            VStack(spacing: 6) {
                StatRow(label: "Duration", value: viewModel.elapsedFormatted)
                StatRow(label: "Exercises", value: "\(viewModel.groupedExercises.count)")
                StatRow(label: "Sets", value: "\(viewModel.totalSets)")
            }
            .padding(.vertical, 8)

            Spacer()

            Button {
                viewModel.reset()
                // Pop to root
                dismiss()
            } label: {
                Text("Done")
                    .font(.callout)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }
}
