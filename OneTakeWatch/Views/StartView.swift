import SwiftUI
import OneTakeKit

struct StartView: View {
    @State private var viewModel = WatchSessionViewModel()
    @State private var navigateToSession = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()

                // Logo
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "mic.fill")
                            .font(.title2)
                            .foregroundStyle(.black)
                    }
                    .shadow(color: .green.opacity(0.3), radius: 15)

                Text("OneTake")
                    .font(.title3)
                    .fontWeight(.heavy)

                Spacer()

                // Start button
                Button {
                    Task {
                        await viewModel.startSession()
                        if viewModel.session != nil {
                            navigateToSession = true
                        }
                    }
                } label: {
                    Text("Start Workout")
                        .font(.callout)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(viewModel.isLoading)

                if let error = viewModel.error {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .navigationDestination(isPresented: $navigateToSession) {
                SessionView(viewModel: viewModel)
            }
            .task {
                // Check for existing active session on appear
                await viewModel.checkForActiveSession()
                if viewModel.session != nil {
                    navigateToSession = true
                }
            }
        }
    }
}
