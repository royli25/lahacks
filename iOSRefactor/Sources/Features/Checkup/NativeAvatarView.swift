import SwiftUI

struct NativeAvatarView: View {
    let session: LiveAvatarSessionPayload?
    let statusMessage: String
    let errorMessage: String?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.07, green: 0.09, blue: 0.15),
                            Color(red: 0.05, green: 0.07, blue: 0.11)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(spacing: 12) {
                Image(systemName: "video.bubble.left.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.white.opacity(0.85))

                if let session {
                    Text("Native LiveKit renderer placeholder")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Session ID: \(session.sessionID ?? "unknown")")
                        .font(.footnote)
                        .foregroundStyle(Color.white.opacity(0.7))

                    Text("LiveKit URL: \(session.livekitURL ?? "missing")")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.white.opacity(0.6))
                        .padding(.horizontal, 16)
                } else {
                    Text("Avatar not started")
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.white.opacity(0.75))

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.red.opacity(0.9))
                        .padding(.horizontal, 16)
                }
            }
        }
    }
}

