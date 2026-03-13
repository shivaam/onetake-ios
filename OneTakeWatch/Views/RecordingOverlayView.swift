import SwiftUI

struct RecordingOverlayView: View {
    @Bindable var recorder: WatchRecorderViewModel
    let sessionId: String
    let onDone: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // Pulsing mic circle
            ZStack {
                // Outer pulse ring
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulseScale)

                Circle()
                    .fill(Color.green.opacity(0.25))
                    .frame(width: 70, height: 70)
                    .scaleEffect(pulseScale * 0.9)

                Circle()
                    .fill(Color.green)
                    .frame(width: 50, height: 50)

                Image(systemName: "mic.fill")
                    .font(.title2)
                    .foregroundStyle(.black)
            }

            Text(recorder.isRecording ? "Listening..." : "Tap to record")
                .font(.callout)
                .fontWeight(.semibold)

            Spacer()

            Button {
                recorder.toggleRecording(sessionId: sessionId) {
                    onDone()
                }
            } label: {
                Text(recorder.isRecording ? "Stop" : "Done")
                    .font(.callout)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(recorder.isRecording ? .red : .green)
        }
        .padding()
        .background(.black)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.2
            }
        }
    }
}
