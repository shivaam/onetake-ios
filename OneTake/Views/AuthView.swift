import SwiftUI

struct AuthView: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            VStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .overlay {
                        Image(systemName: "mic.fill")
                            .font(.title)
                            .foregroundStyle(.black)
                    }
                    .shadow(color: .green.opacity(0.3), radius: 20)

                Text("OneTake")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .tracking(-1)
            }
            .padding(.bottom, 48)

            // Form
            VStack(spacing: 14) {
                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))

                SecureField("Password", text: $viewModel.password)
                    .textContentType(viewModel.isSignUp ? .newPassword : .password)
                    .padding()
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))

                Button {
                    Task { await viewModel.signIn() }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text(viewModel.isSignUp ? "Sign Up" : "Sign In")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(viewModel.isLoading)

                if let error = viewModel.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            // Toggle sign in / sign up
            Button {
                viewModel.isSignUp.toggle()
                viewModel.error = nil
            } label: {
                Text(viewModel.isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.callout)
                    .foregroundStyle(.green)
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
    }
}
