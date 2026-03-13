import SwiftUI
import OneTakeKit

struct DoneView: View {
    @Bindable var viewModel: WatchSessionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Checkmark
                ZStack {
                    Circle()
                        .fill(Color.oneTakeGreen.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "checkmark")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.oneTakeGreen)
                }

                Text("Session Saved")
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.oneTakeGreen)

                // Stats row
                HStack(spacing: 12) {
                    VStack(spacing: 1) {
                        Text(viewModel.elapsedFormatted)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.oneTakeGreen)
                        Text("DURATION")
                            .font(.system(size: 6))
                            .foregroundStyle(.secondary)
                    }
                    VStack(spacing: 1) {
                        Text("\(viewModel.groupedExercises.count)")
                            .font(.system(size: 11, weight: .bold))
                        Text("EXERCISES")
                            .font(.system(size: 6))
                            .foregroundStyle(.secondary)
                    }
                    VStack(spacing: 1) {
                        Text("\(viewModel.totalSets)")
                            .font(.system(size: 11, weight: .bold))
                        Text("SETS")
                            .font(.system(size: 6))
                            .foregroundStyle(.secondary)
                    }
                }

                // Exercise summary list
                if !viewModel.groupedExercises.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LOGGED")
                            .font(.system(size: 7))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)

                        ForEach(viewModel.groupedExercises) { group in
                            HStack(spacing: 4) {
                                Text(group.name)
                                    .font(.system(size: 9, weight: .semibold))
                                    .frame(maxWidth: 70, alignment: .leading)
                                    .lineLimit(1)

                                Text(group.allSets.map(\.weightRepsDisplay).joined(separator: ", "))
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.oneTakeSurface2, in: RoundedRectangle(cornerRadius: 8))
                }

                // Done button
                Button {
                    viewModel.reset()
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.callout)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.oneTakeGreen)
            }
            .padding(.horizontal, 4)
        }
        .navigationBarBackButtonHidden(true)
    }
}
