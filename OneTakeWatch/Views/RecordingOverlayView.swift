import SwiftUI
import OneTakeKit

struct RecordingOverlayView: View {
    @Bindable var recorder: WatchRecorderViewModel
    let sessionId: String
    let elapsedFormatted: String
    let onDone: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var wavePhase: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            // Pulsing mic circle with ring
            ZStack {
                Circle()
                    .stroke(Color.oneTakeGreen.opacity(0.3), lineWidth: 3)
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulseScale)

                Circle()
                    .fill(Color.oneTakeGreen.opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: "mic.fill")
                    .font(.title2)
                    .foregroundStyle(Color.oneTakeGreen)
            }

            // Wave bars
            HStack(spacing: 3) {
                ForEach(0..<7, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.oneTakeGreen)
                        .frame(width: 4, height: waveBarHeight(index: i))
                        .animation(
                            .easeInOut(duration: 0.4 + Double(i) * 0.08)
                            .repeatForever(autoreverses: true),
                            value: wavePhase
                        )
                }
            }
            .frame(height: 24)

            Text("Listening...")
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(Color.oneTakeGreen)

            // Transcript preview
            if let transcript = recorder.lastTranscript {
                Text("\"\(transcript)\"")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .italic()
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            Spacer()

            // Timer
            Text(elapsedFormatted)
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)

            Button {
                recorder.toggleRecording(sessionId: sessionId) {
                    onDone()
                }
            } label: {
                Text(recorder.isRecording ? "Stop" : "Done")
                    .font(.callout)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(recorder.isRecording ? .oneTakeRed : .oneTakeGreen)
        }
        .padding()
        .background(.black)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
            wavePhase = true
        }
    }

    private func waveBarHeight(index: Int) -> CGFloat {
        let base: CGFloat = wavePhase ? 6 : 20
        let variance: CGFloat = wavePhase ? 18 : 4
        // Center bars taller, edges shorter
        let centerFactor = 1.0 - abs(CGFloat(index) - 3.0) / 4.0
        return base + variance * centerFactor
    }
}
